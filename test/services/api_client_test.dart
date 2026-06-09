import 'dart:convert';

import 'package:bondy/services/api_client.dart';
import 'package:bondy/services/auth_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _MockAuthService implements AuthService {
  String _accessToken;
  String _refreshToken;
  int refreshCallCount = 0;
  bool clearSessionCalled = false;

  _MockAuthService({required String accessToken, required String refreshToken})
    : _accessToken = accessToken,
      _refreshToken = refreshToken;

  String get currentAccessToken => _accessToken;

  @override
  Future<String> requireAccessToken() async => _accessToken;

  @override
  Future<void> clearSession() async {
    clearSessionCalled = true;
    _accessToken = '';
    _refreshToken = '';
  }

  @override
  Future<RefreshTokenResult> refreshAccessToken() async {
    refreshCallCount++;
    _accessToken = 'new-access-token';
    _refreshToken = 'new-refresh-token';
    return const RefreshTokenResult(
      accessToken: 'new-access-token',
      refreshToken: 'new-refresh-token',
    );
  }

  @override
  Future<SessionRestoreResult> restoreSession() async =>
      throw UnimplementedError();

  // Stub the rest of the interface to satisfy `implements AuthService`
  @override
  Future<SendOtpResult> sendOtp(String email) async =>
      throw UnimplementedError();
  @override
  Future<VerifyOtpResult> verifyOtp({
    required String email,
    required String otp,
  }) async => throw UnimplementedError();
  @override
  Future<LoginResult> login({
    required String email,
    required String password,
  }) async => throw UnimplementedError();
  @override
  Future<SendOtpResult> requestLoginOtp({
    required String email,
    required String password,
  }) async => throw UnimplementedError();
  @override
  Future<void> verifyEmail({required String token}) async =>
      throw UnimplementedError();
  @override
  Future<String> forgotPassword({required String email}) async =>
      throw UnimplementedError();
  @override
  Future<void> resetPassword({
    required String token,
    required String password,
  }) async => throw UnimplementedError();
  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async => throw UnimplementedError();
  @override
  Future<void> setPassword({required String password}) async =>
      throw UnimplementedError();
  @override
  Future<void> setPasswordEmail({
    required String email,
    required String password,
  }) async => throw UnimplementedError();
  @override
  Future<Map<String, dynamic>> getCurrentUser() async =>
      throw UnimplementedError();
  @override
  Future<void> deleteAccount() async => throw UnimplementedError();
  @override
  Future<void> logout() async {}
  @override
  Future<String?> getAccessToken() async => _accessToken;
  @override
  Future<String?> getRefreshToken() async => _refreshToken;
  @override
  Future<String?> getCurrentUserId() async => null;
  @override
  Future<String?> getToken() async => _accessToken;
  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required String userId,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }
  String get baseUrl => 'https://api.example.com/api';
}

void main() {
  late FlutterSecureStorage storage;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    FlutterSecureStorage.setMockInitialValues({});
    storage = const FlutterSecureStorage();
  });

  test('resolves configured base URL without trailing slash', () {
    expect(
      ApiClient.resolveBaseUrl(baseUrlOverride: 'https://api.example.com/api/'),
      'https://api.example.com/api',
    );
  });

  test(
    'attaches bearer token to authenticated requests and decodes JSON',
    () async {
      await storage.write(key: 'accessToken', value: 'access-token');
      final authService = AuthService(
        baseUrlOverride: 'https://api.example.com/api',
        storage: storage,
      );
      final client = ApiClient(
        baseUrlOverride: 'https://api.example.com/api',
        authService: authService,
        client: MockClient((request) async {
          expect(request.method, 'GET');
          expect(
            request.url.toString(),
            'https://api.example.com/api/profile/me',
          );
          expect(request.headers['authorization'], 'Bearer access-token');
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {'id': 'profile-id'},
            }),
            200,
          );
        }),
      );

      final body = await client.get('/profile/me', authenticated: true);

      expect(body, {
        'success': true,
        'data': {'id': 'profile-id'},
      });
    },
  );

  test('authenticated false requests do not require bearer token', () async {
    final client = ApiClient(
      baseUrlOverride: 'https://api.example.com/api',
      client: MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.toString(), 'https://api.example.com/api/public');
        expect(request.headers.containsKey('authorization'), isFalse);
        return http.Response(jsonEncode({'success': true}), 200);
      }),
    );

    await expectLater(
      client.get('/public', authenticated: false),
      completion({'success': true}),
    );
  });

  test('sends JSON body for post requests', () async {
    final client = ApiClient(
      baseUrlOverride: 'https://api.example.com/api',
      client: MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.headers['content-type'], 'application/json');
        expect(jsonDecode(request.body), {'phone': '0912345678'});
        return http.Response(jsonEncode({'success': true}), 200);
      }),
    );

    await expectLater(
      client.post('/auth/send-otp', body: {'phone': '0912345678'}),
      completion({'success': true}),
    );
  });

  test(
    'authenticated 401 refreshes token and retries original request exactly once',
    () async {
      final authService = _MockAuthService(
        accessToken: 'old-access-token',
        refreshToken: 'refresh-token',
      );
      var protectedRequestCount = 0;
      final client = ApiClient(
        baseUrlOverride: 'https://api.example.com/api',
        authService: authService,
        client: MockClient((request) async {
          if (request.url.path == '/api/profile/me') {
            protectedRequestCount++;
            if (protectedRequestCount == 1) {
              expect(
                request.headers['authorization'],
                'Bearer old-access-token',
              );
              return http.Response(jsonEncode({'success': false}), 401);
            }
            expect(request.headers['authorization'], 'Bearer new-access-token');
            return http.Response(
              jsonEncode({
                'success': true,
                'data': {'id': 'profile-id'},
              }),
              200,
            );
          }
          return http.Response('{}', 404);
        }),
      );

      final body = await client.get('/profile/me', authenticated: true);

      expect(body['success'], isTrue);
      expect(protectedRequestCount, 2);
      expect(authService.refreshCallCount, 1);
      expect(authService.currentAccessToken, 'new-access-token');
    },
  );

  test(
    'refresh failure clears session and surfaces session expired state',
    () async {
      await storage.write(key: 'accessToken', value: 'old-access-token');
      await storage.write(key: 'refreshToken', value: 'expired-refresh-token');
      await storage.write(key: 'userId', value: 'user-id');
      final authService = AuthService(
        baseUrlOverride: 'https://api.example.com/api',
        storage: storage,
      );
      final client = ApiClient(
        baseUrlOverride: 'https://api.example.com/api',
        authService: authService,
        client: MockClient((request) async {
          if (request.url.path == '/api/auth/refresh') {
            return http.Response.bytes(
              utf8.encode(
                jsonEncode({
                  'success': false,
                  'error': 'Refresh token hết hạn',
                }),
              ),
              401,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          }
          return http.Response(
            jsonEncode({'success': false, 'error': 'Unauthorized'}),
            401,
          );
        }),
      );

      await expectLater(
        client.get('/profile/me', authenticated: true),
        throwsA(isA<ApiClientException>()),
      );
      expect(await storage.read(key: 'accessToken'), isNull);
      expect(await storage.read(key: 'refreshToken'), isNull);
      expect(await storage.read(key: 'userId'), isNull);
    },
  );

  test('unauthenticated 401 does not trigger refresh', () async {
    await storage.write(key: 'refreshToken', value: 'refresh-token');
    final authService = AuthService(
      baseUrlOverride: 'https://api.example.com/api',
      storage: storage,
    );
    var refreshRequestCount = 0;
    final client = ApiClient(
      baseUrlOverride: 'https://api.example.com/api',
      authService: authService,
      client: MockClient((request) async {
        if (request.url.path == '/api/auth/refresh') {
          refreshRequestCount++;
        }
        return http.Response(
          jsonEncode({'success': false, 'error': 'Unauthorized'}),
          401,
        );
      }),
    );

    await expectLater(
      client.get('/public', authenticated: false),
      throwsA(isA<ApiClientException>()),
    );
    expect(refreshRequestCount, 0);
  });

  test(
    'throws AuthRequiredException before authenticated request without token',
    () async {
      final authService = AuthService(
        baseUrlOverride: 'https://api.example.com/api',
        storage: storage,
      );
      final client = ApiClient(
        baseUrlOverride: 'https://api.example.com/api',
        authService: authService,
        client: MockClient((request) async => http.Response('{}', 200)),
      );

      await expectLater(
        client.get('/profile/me', authenticated: true),
        throwsA(isA<AuthRequiredException>()),
      );
    },
  );

  test('exposes baseUrl for environment detection', () {
    final devClient = ApiClient(baseUrlOverride: 'http://localhost:3000/api');
    expect(devClient.baseUrl, 'http://localhost:3000/api');

    final prodClient = ApiClient(baseUrlOverride: 'https://api.bondy.com/api');
    expect(prodClient.baseUrl, 'https://api.bondy.com/api');
  });
}
