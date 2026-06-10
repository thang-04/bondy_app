import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import 'auth_service.dart';

/// Result returned by the backend after Google Sign-In succeeds.
class GoogleAuthResult {
  final String accessToken;
  final String refreshToken;
  final String userId;
  final String email;
  final String? name;
  final String? image;
  final bool isNewUser;

  const GoogleAuthResult({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
    required this.email,
    this.name,
    this.image,
    required this.isNewUser,
  });

  factory GoogleAuthResult.fromJson(Map<String, dynamic> data) {
    final user = data['user'] as Map<String, dynamic>;
    return GoogleAuthResult(
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
      userId: user['id'] as String,
      email: user['email'] as String,
      name: user['name'] as String?,
      image: user['image'] as String?,
      isNewUser: user['isNewUser'] as bool? ?? false,
    );
  }
}

/// Thrown when backend returns 409 ACCOUNT_EXISTS_LINK.
class AccountExistsException implements Exception {
  final String message;

  const AccountExistsException(this.message);

  @override
  String toString() => message;
}

class GoogleSignInService {
  static const _timeout = Duration(seconds: 20);

  // Web client ID. Backend verifies Google ID tokens against this audience.
  static const _serverClientId =
      '204544826846-vnb5h7bh3j3acpncjq0ba3evnscn5d0l.apps.googleusercontent.com';

  // iOS client ID from GoogleService-Info.plist.
  static const _iosClientId =
      '204544826846-2nqemkk3vj5fibiu064h6jnjq0mb0vb6.apps.googleusercontent.com';

  final GoogleSignIn _googleSignIn;
  final http.Client _client;
  final String _baseUrl;

  GoogleSignInService({
    http.Client? client,
    String? baseUrlOverride,
    GoogleSignIn? googleSignIn,
  }) : _googleSignIn = googleSignIn ?? _createGoogleSignIn(),
       _client = client ?? http.Client(),
       _baseUrl = AuthService.resolveBaseUrl(baseUrlOverride: baseUrlOverride);

  static GoogleSignIn _createGoogleSignIn() {
    return GoogleSignIn(
      scopes: ['email', 'profile', 'openid'],
      clientId: kIsWeb
          ? _serverClientId
          : (defaultTargetPlatform == TargetPlatform.iOS ? _iosClientId : null),
      serverClientId: _serverClientId,
    );
  }

  Stream<GoogleSignInAccount?> get onCurrentUserChanged =>
      _googleSignIn.onCurrentUserChanged;

  Future<GoogleSignInAccount?> signInSilently() {
    return _googleSignIn.signInSilently();
  }

  /// Opens the native Google Sign-In dialog and returns an ID token.
  /// Returns null if the user cancels.
  Future<String?> getIdToken() async {
    try {
      if (kIsWeb) {
        throw const AuthServiceException(
          'Vui lòng dùng nút Google chuẩn để đăng nhập trên web.',
        );
      }

      final account = await _googleSignIn.signIn();
      if (account == null) return null;
      return getIdTokenForAccount(account);
    } catch (error) {
      if (error is AuthServiceException) rethrow;
      throw AuthServiceException('Lỗi Google Sign-In: $error');
    }
  }

  Future<String> getIdTokenForAccount(GoogleSignInAccount account) async {
    final auth = await account.authentication;
    final idToken = auth.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw const AuthServiceException(
        'Không thể lấy Google ID Token. Vui lòng thử lại bằng nút Google chuẩn.',
      );
    }
    return idToken;
  }

  /// Sends idToken to POST /api/auth/google.
  Future<GoogleAuthResult> loginWithGoogle(String idToken) async {
    final response = await _sendGoogleAuthRequest('POST', {'idToken': idToken});
    final body = _decodeGoogleAuthBody(response, operation: 'login');

    if (response.statusCode == 409 && body['code'] == 'ACCOUNT_EXISTS_LINK') {
      throw AccountExistsException(
        body['error']?.toString() ??
            'Email này đã có tài khoản. Bạn có muốn liên kết với Google không?',
      );
    }

    if (response.statusCode != 200 || body['success'] != true) {
      throw AuthServiceException(
        body['error']?.toString() ?? 'Đăng nhập Google thất bại',
      );
    }

    return GoogleAuthResult.fromJson(body['data'] as Map<String, dynamic>);
  }

  /// Sends idToken to PUT /api/auth/google to confirm account linking.
  Future<GoogleAuthResult> confirmLinkAccount(String idToken) async {
    final response = await _sendGoogleAuthRequest('PUT', {
      'idToken': idToken,
      'confirmLink': true,
    });
    final body = _decodeGoogleAuthBody(response, operation: 'confirmLink');

    if (response.statusCode != 200 || body['success'] != true) {
      throw AuthServiceException(
        body['error']?.toString() ?? 'Liên kết tài khoản thất bại',
      );
    }

    return GoogleAuthResult.fromJson(body['data'] as Map<String, dynamic>);
  }

  /// Signs out from Google. App logout can call this as best effort.
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Ignore sign-out errors.
    }
  }

  Future<http.Response> _sendGoogleAuthRequest(
    String method,
    Map<String, dynamic> body,
  ) async {
    try {
      final uri = Uri.parse('$_baseUrl/auth/google');
      if (method == 'PUT') {
        return await _client
            .put(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(body),
            )
            .timeout(_timeout);
      }

      return await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(_timeout);
    } on TimeoutException {
      throw const AuthServiceException(
        'Máy chủ đăng nhập Google không phản hồi. Vui lòng thử lại.',
      );
    } catch (error) {
      debugPrint('[GOOGLE-AUTH] request failed: $error');
      throw const AuthServiceException(
        'Không thể kết nối máy chủ đăng nhập Google. Vui lòng thử lại.',
      );
    }
  }

  Map<String, dynamic> _decodeGoogleAuthBody(
    http.Response response, {
    required String operation,
  }) {
    final contentType = response.headers['content-type'] ?? '';
    if (!contentType.contains('application/json')) {
      _logGoogleAuthFailure(operation, response, response.body);
      throw AuthServiceException(
        'Không thể kết nối đến máy chủ API (Mã lỗi: ${response.statusCode}). Vui lòng kiểm tra lại cấu hình server backend.',
      );
    }

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        if (response.statusCode >= 400 || decoded['success'] != true) {
          _logGoogleAuthFailure(operation, response, decoded);
        }
        return decoded;
      }
    } catch (error) {
      debugPrint('[GOOGLE-AUTH] invalid JSON response: $error');
    }

    _logGoogleAuthFailure(operation, response, response.body);
    throw AuthServiceException(
      'Phản hồi đăng nhập Google không hợp lệ (Mã lỗi: ${response.statusCode}). Vui lòng thử lại.',
    );
  }

  void _logGoogleAuthFailure(
    String operation,
    http.Response response,
    Object? body,
  ) {
    var preview = body.toString();
    if (preview.length > 500) {
      preview = '${preview.substring(0, 500)}...';
    }
    debugPrint(
      '[GOOGLE-AUTH] $operation failed '
      'status=${response.statusCode} body=$preview',
    );
  }
}

final googleSignInService = GoogleSignInService();
