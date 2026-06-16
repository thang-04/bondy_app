import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class AuthRequiredException implements Exception {
  final String message;

  const AuthRequiredException([
    this.message = 'Vui lòng đăng nhập để tiếp tục',
  ]);

  @override
  String toString() => message;
}

class SessionExpiredException implements Exception {
  final String message;

  const SessionExpiredException([
    this.message = 'Phiên đăng nhập đã hết hạn, vui lòng đăng nhập lại',
  ]);

  @override
  String toString() => message;
}

class AuthServiceException implements Exception {
  final String message;

  const AuthServiceException(this.message);

  @override
  String toString() => message;
}

class SendOtpResult {
  final String message;
  final String? devOtp;

  const SendOtpResult({required this.message, this.devOtp});
}

class VerifyOtpResult {
  final String userId;
  final String accessToken;
  final String refreshToken;

  const VerifyOtpResult({
    required this.userId,
    required this.accessToken,
    required this.refreshToken,
  });
}

class RefreshTokenResult {
  final String accessToken;
  final String refreshToken;

  const RefreshTokenResult({
    required this.accessToken,
    required this.refreshToken,
  });
}

enum SessionRestoreStatus { unauthenticated, authenticated, expired }

class SessionRestoreResult {
  final SessionRestoreStatus status;
  final Map<String, dynamic>? user;

  const SessionRestoreResult._(this.status, [this.user]);

  const SessionRestoreResult.unauthenticated()
    : this._(SessionRestoreStatus.unauthenticated);

  const SessionRestoreResult.authenticated(Map<String, dynamic> user)
    : this._(SessionRestoreStatus.authenticated, user);

  const SessionRestoreResult.expired() : this._(SessionRestoreStatus.expired);
}

class LoginResult {
  final String userId;
  final String email;
  final String name;
  final String accessToken;
  final String refreshToken;

  const LoginResult({
    required this.userId,
    required this.email,
    required this.name,
    required this.accessToken,
    required this.refreshToken,
  });
}

class AuthService {
  static const defaultApiBaseUrl = 'http://103.149.86.25:3000/api';
  static const _accessTokenKey = 'accessToken';
  static const _refreshTokenKey = 'refreshToken';
  static const _userIdKey = 'userId';
  static const _timeout = Duration(seconds: 15);

  final String _baseUrl;
  final FlutterSecureStorage _storage;
  final http.Client _client;

  AuthService({
    String? baseUrlOverride,
    FlutterSecureStorage storage = const FlutterSecureStorage(),
    http.Client? client,
  }) : _baseUrl = resolveBaseUrl(baseUrlOverride: baseUrlOverride),
       _storage = storage,
       _client = client ?? http.Client();

  static String get baseUrl => resolveBaseUrl();

  static String resolveBaseUrl({String? baseUrlOverride}) {
    if (baseUrlOverride != null && baseUrlOverride.trim().isNotEmpty) {
      return baseUrlOverride.trim().replaceFirst(RegExp(r'/+$'), '');
    }

    // Dynamic secure proxy resolution when running in a web browser
    if (kIsWeb) {
      final portPart =
          (Uri.base.port != 80 && Uri.base.port != 443 && Uri.base.port != 0)
          ? ':${Uri.base.port}'
          : '';
      return '${Uri.base.scheme}://${Uri.base.host}$portPart/api-proxy';
    }

    // Priority 1: .env file (for real device and production)
    String? envUrl;
    try {
      envUrl = dotenv.env['API_BASE_URL'];
    } catch (_) {
      // dotenv not initialized, use fallback
    }
    if (envUrl != null && envUrl.trim().isNotEmpty) {
      return envUrl.trim().replaceFirst(RegExp(r'/+$'), '');
    }

    // Priority 2: shared fallback when .env is not bundled or loaded.
    return defaultApiBaseUrl;
  }

  /// WebSocket base for chat realtime (port 3001 by default).
  static String resolveWsUrl({
    required String chatId,
    required String accessToken,
  }) {
    String? wsPort;
    try {
      wsPort = dotenv.env['CHAT_WS_PORT'];
    } catch (_) {}

    final apiBase = resolveBaseUrl();
    final apiUri = Uri.parse(apiBase);
    final host = apiUri.host;
    final port = wsPort ?? '3001';
    final encodedToken = Uri.encodeComponent(accessToken);
    final encodedChat = Uri.encodeComponent(chatId);
    return 'ws://$host:$port?token=$encodedToken&chatId=$encodedChat';
  }

  Future<SendOtpResult> sendOtp(String email) async {
    final http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse('$_baseUrl/auth/send-otp'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email}),
          )
          .timeout(_timeout);
    } on TimeoutException {
      throw const AuthServiceException(
        'Máy chủ không phản hồi. Kiểm tra kết nối và thử lại.',
      );
    } catch (e) {
      throw AuthServiceException('Không thể kết nối máy chủ: $e');
    }

    final body = _decodeBody(response);
    if (response.statusCode != 200 || body['success'] != true) {
      throw AuthServiceException(
        body['error']?.toString() ?? 'Không thể gửi OTP',
      );
    }

    return SendOtpResult(
      message: body['message']?.toString() ?? 'Đã gửi mã OTP',
      devOtp: body['devOtp']?.toString(),
    );
  }

  Future<VerifyOtpResult> verifyOtp({
    required String email,
    required String otp,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/auth/verify-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'otp': otp}),
    );

    final body = _decodeBody(response);
    if (response.statusCode != 200 || body['success'] != true) {
      throw AuthServiceException(
        body['error']?.toString() ?? 'Mã OTP không hợp lệ',
      );
    }

    final data = (body['data'] as Map<String, dynamic>?) ?? {};
    final user = (data['user'] as Map<String, dynamic>?) ?? {};
    final result = VerifyOtpResult(
      userId: user['id']?.toString() ?? '',
      accessToken: data['accessToken']?.toString() ?? '',
      refreshToken: data['refreshToken']?.toString() ?? '',
    );

    if (result.userId.isEmpty ||
        result.accessToken.isEmpty ||
        result.refreshToken.isEmpty) {
      throw const AuthServiceException('Phản hồi đăng nhập không hợp lệ');
    }

    await _storage.write(key: _accessTokenKey, value: result.accessToken);
    await _storage.write(key: _refreshTokenKey, value: result.refreshToken);
    await _storage.write(key: _userIdKey, value: result.userId);

    return result;
  }

  Future<LoginResult> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    final body = _decodeBody(response);
    if (response.statusCode != 200 || body['success'] != true) {
      throw AuthServiceException(
        body['error']?.toString() ?? 'Đăng nhập thất bại',
      );
    }

    final data = (body['data'] as Map<String, dynamic>?) ?? {};
    final user = (data['user'] as Map<String, dynamic>?) ?? {};
    final result = LoginResult(
      userId: user['id']?.toString() ?? '',
      email: user['email']?.toString() ?? '',
      name: user['name']?.toString() ?? '',
      accessToken: data['accessToken']?.toString() ?? '',
      refreshToken: data['refreshToken']?.toString() ?? '',
    );

    if (result.userId.isEmpty ||
        result.accessToken.isEmpty ||
        result.refreshToken.isEmpty) {
      throw const AuthServiceException('Phản hồi đăng nhập không hợp lệ');
    }

    await _storage.write(key: _accessTokenKey, value: result.accessToken);
    await _storage.write(key: _refreshTokenKey, value: result.refreshToken);
    await _storage.write(key: _userIdKey, value: result.userId);

    return result;
  }

  Future<SendOtpResult> requestLoginOtp({
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/auth/login/request-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    final body = _decodeBody(response);
    if (response.statusCode != 200 || body['success'] != true) {
      throw AuthServiceException(
        body['error']?.toString() ?? 'Không thể gửi OTP đăng nhập',
      );
    }

    return SendOtpResult(
      message: body['message']?.toString() ?? 'Đã gửi mã OTP',
      devOtp: body['devOtp']?.toString(),
    );
  }

  Future<void> verifyEmail({required String token}) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/auth/verify-email'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'token': token}),
    );

    final body = _decodeBody(response);
    if (response.statusCode != 200 || body['success'] != true) {
      throw AuthServiceException(
        body['error']?.toString() ?? 'Xác minh email thất bại',
      );
    }
  }

  Future<String> forgotPassword({required String email}) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/auth/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    final body = _decodeBody(response);
    if (response.statusCode != 200 || body['success'] != true) {
      throw AuthServiceException(
        body['error']?.toString() ?? 'Không thể yêu cầu đặt lại mật khẩu',
      );
    }

    return body['devToken']?.toString() ?? '';
  }

  Future<void> resetPassword({
    required String token,
    required String password,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/auth/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'token': token, 'password': password}),
    );

    final body = _decodeBody(response);
    if (response.statusCode != 200 || body['success'] != true) {
      throw AuthServiceException(
        body['error']?.toString() ?? 'Đặt lại mật khẩu thất bại',
      );
    }
  }

  Future<void> setPasswordEmail({
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/auth/set-password-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    final body = _decodeBody(response);
    if (response.statusCode != 200 || body['success'] != true) {
      throw AuthServiceException(
        body['error']?.toString() ?? 'Đặt mật khẩu thất bại',
      );
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/auth/change-password'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${await requireAccessToken()}',
      },
      body: jsonEncode({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }),
    );

    final body = _decodeBody(response);
    if (response.statusCode != 200 || body['success'] != true) {
      throw AuthServiceException(
        body['error']?.toString() ?? 'Đổi mật khẩu thất bại',
      );
    }

    final accessToken = body['accessToken']?.toString() ?? '';
    final refreshToken = body['refreshToken']?.toString() ?? '';
    if (accessToken.isEmpty || refreshToken.isEmpty) {
      throw const AuthServiceException('Phản hồi đổi mật khẩu không hợp lệ');
    }

    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<void> setPassword({required String password}) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/auth/set-password'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${await requireAccessToken()}',
      },
      body: jsonEncode({'password': password}),
    );

    final body = _decodeBody(response);
    if (response.statusCode != 200 || body['success'] != true) {
      throw AuthServiceException(
        body['error']?.toString() ?? 'Tạo mật khẩu thất bại',
      );
    }
  }

  Future<RefreshTokenResult> refreshAccessToken() async {
    final refreshToken = await getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      throw const SessionExpiredException();
    }

    final response = await _client.post(
      Uri.parse('$_baseUrl/auth/refresh'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refreshToken': refreshToken}),
    ).timeout(_timeout);

    final body = _decodeBody(response);
    if (response.statusCode != 200 || body['success'] != true) {
      throw SessionExpiredException(
        body['error']?.toString() ??
            'Phiên đăng nhập đã hết hạn, vui lòng đăng nhập lại',
      );
    }

    final data = (body['data'] as Map<String, dynamic>?) ?? {};
    final result = RefreshTokenResult(
      accessToken: data['accessToken']?.toString() ?? '',
      refreshToken: data['refreshToken']?.toString() ?? '',
    );

    if (result.accessToken.isEmpty || result.refreshToken.isEmpty) {
      throw const AuthServiceException('Phản hồi refresh token không hợp lệ');
    }

    await _storage.write(key: _accessTokenKey, value: result.accessToken);
    await _storage.write(key: _refreshTokenKey, value: result.refreshToken);

    return result;
  }

  Future<SessionRestoreResult> restoreSession() async {
    final refreshToken = await getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      await clearSession();
      return const SessionRestoreResult.unauthenticated();
    }

    final accessToken = await getAccessToken();
    if (accessToken != null && accessToken.isNotEmpty) {
      try {
        final user = await _fetchCurrentUser(
          accessToken,
          sessionExpiredOnUnauthorized: true,
        );
        return SessionRestoreResult.authenticated(user);
      } on SessionExpiredException {
        // Continue to refresh flow below.
      } catch (_) {
        await clearSession();
        return const SessionRestoreResult.expired();
      }
    }

    try {
      final refreshed = await refreshAccessToken();
      final user = await _fetchCurrentUser(
        refreshed.accessToken,
        sessionExpiredOnUnauthorized: true,
      );
      return SessionRestoreResult.authenticated(user);
    } catch (_) {
      await clearSession();
      return const SessionRestoreResult.expired();
    }
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    return _fetchCurrentUser(await requireAccessToken());
  }

  Future<Map<String, dynamic>> _fetchCurrentUser(
    String accessToken, {
    bool sessionExpiredOnUnauthorized = false,
  }) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/auth/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    ).timeout(_timeout);

    final body = _decodeBody(response);
    if (response.statusCode != 200 || body['success'] != true) {
      if (sessionExpiredOnUnauthorized && response.statusCode == 401) {
        throw SessionExpiredException(
          body['error']?.toString() ??
              'Phiên đăng nhập đã hết hạn, vui lòng đăng nhập lại',
        );
      }
      throw AuthServiceException(
        body['error']?.toString() ?? 'Không thể tải thông tin người dùng',
      );
    }

    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw const AuthServiceException('Phản hồi người dùng không hợp lệ');
    }

    return data;
  }

  Future<void> logout() async {
    final accessToken = await getAccessToken();
    final refreshToken = await getRefreshToken();

    try {
      if (accessToken != null &&
          accessToken.isNotEmpty &&
          refreshToken != null &&
          refreshToken.isNotEmpty) {
        await _client.post(
          Uri.parse('$_baseUrl/auth/logout'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
          },
          body: jsonEncode({'refreshToken': refreshToken}),
        );
      }
    } finally {
      await clearSession();
    }
  }

  Future<void> deleteAccount() async {
    final response = await _client.delete(
      Uri.parse('$_baseUrl/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${await requireAccessToken()}',
      },
    );

    final body = _decodeBody(response);
    if (response.statusCode != 200 || body['success'] != true) {
      throw AuthServiceException(
        body['error']?.toString() ?? 'Xóa tài khoản thất bại',
      );
    }
    await clearSession();
  }

  /// Lưu tokens sau đăng nhập OAuth (dùng chung cho Google Sign-In)
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required String userId,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
    await _storage.write(key: _userIdKey, value: userId);
  }

  Future<String?> getAccessToken() => _storage.read(key: _accessTokenKey);

  Future<String?> getToken() => getAccessToken();

  Future<String?> getRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<String?> getCurrentUserId() => _storage.read(key: _userIdKey);

  Future<String> requireAccessToken() async {
    final token = await getAccessToken();
    if (token == null || token.isEmpty) {
      throw const AuthRequiredException();
    }
    return token;
  }

  Future<void> clearSession() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _userIdKey);
  }

  Map<String, dynamic> _decodeBody(http.Response response) {
    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      return {'success': false, 'error': 'Phản hồi server không hợp lệ'};
    }
  }
}
