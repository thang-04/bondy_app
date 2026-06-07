import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import 'auth_service.dart';

/// Kết quả từ backend sau Google Sign-In thành công
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

/// Thrown khi backend trả 409 ACCOUNT_EXISTS_LINK
/// → Flutter phải hiển thị popup xác nhận liên kết
class AccountExistsException implements Exception {
  final String message;
  const AccountExistsException(this.message);

  @override
  String toString() => message;
}

class GoogleSignInService {
  static const _timeout = Duration(seconds: 20);

  // Web Client ID: dùng để backend xác thực idToken
  static const _serverClientId =
      '204544826846-vnb5h7bh3j3acpncjq0ba3evnscn5d0l.apps.googleusercontent.com';

  // iOS Client ID từ GoogleService-Info.plist để tránh lỗi khi chưa link plist trong Xcode
  static const _iosClientId =
      '204544826846-2nqemkk3vj5fibiu064h6jnjq0mb0vb6.apps.googleusercontent.com';

  final _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    clientId: kIsWeb ? _serverClientId : (Platform.isIOS ? _iosClientId : null),
    serverClientId: _serverClientId,
  );

  final http.Client _client;
  final String _baseUrl;

  GoogleSignInService({
    http.Client? client,
    String? baseUrlOverride,
  })  : _client = client ?? http.Client(),
        _baseUrl = AuthService.resolveBaseUrl(baseUrlOverride: baseUrlOverride);

  /// Mở Google Sign-In dialog và lấy idToken.
  /// Trả về null nếu user bấm huỷ.
  Future<String?> getIdToken() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return null; // User bấm huỷ

      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) {
        throw const AuthServiceException('Không thể lấy Google ID Token');
      }
      return idToken;
    } catch (e) {
      if (e is AuthServiceException) rethrow;
      throw AuthServiceException('Lỗi Google Sign-In: $e');
    }
  }

  /// Gửi idToken lên POST /api/auth/google.
  /// Throws [AccountExistsException] nếu backend trả 409.
  Future<GoogleAuthResult> loginWithGoogle(String idToken) async {
    final response = await _client
        .post(
          Uri.parse('$_baseUrl/auth/google'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'idToken': idToken}),
        )
        .timeout(_timeout);

    final contentType = response.headers['content-type'] ?? '';
    if (!contentType.contains('application/json')) {
      throw AuthServiceException(
        'Không thể kết nối đến máy chủ API (Mã lỗi: ${response.statusCode}). Vui lòng kiểm tra lại cấu hình server backend.',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 409 &&
        body['code'] == 'ACCOUNT_EXISTS_LINK') {
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

    return GoogleAuthResult.fromJson(
      body['data'] as Map<String, dynamic>,
    );
  }

  /// Gửi idToken lên PUT /api/auth/google để xác nhận liên kết sau popup.
  Future<GoogleAuthResult> confirmLinkAccount(String idToken) async {
    final response = await _client
        .put(
          Uri.parse('$_baseUrl/auth/google'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'idToken': idToken, 'confirmLink': true}),
        )
        .timeout(_timeout);

    final contentType = response.headers['content-type'] ?? '';
    if (!contentType.contains('application/json')) {
      throw AuthServiceException(
        'Không thể kết nối đến máy chủ API (Mã lỗi: ${response.statusCode}). Vui lòng kiểm tra lại cấu hình server backend.',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200 || body['success'] != true) {
      throw AuthServiceException(
        body['error']?.toString() ?? 'Liên kết tài khoản thất bại',
      );
    }
    return GoogleAuthResult.fromJson(body['data'] as Map<String, dynamic>);
  }

  /// Đăng xuất khỏi Google (gọi khi user logout app)
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Bỏ qua lỗi sign out
    }
  }
}

final googleSignInService = GoogleSignInService();
