import 'dart:convert';

import 'package:bondy/services/auth_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  late FlutterSecureStorage storage;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    FlutterSecureStorage.setMockInitialValues({});
    storage = const FlutterSecureStorage();
  });

  test('sends OTP to the server', () async {
    final service = AuthService(
      baseUrlOverride: 'https://api.example.com/api',
      storage: storage,
      client: MockClient((request) async {
        expect(request.method, 'POST');
        expect(
          request.url.toString(),
          'https://api.example.com/api/auth/send-otp',
        );
        expect(jsonDecode(request.body), {'email': 'user@example.com'});
        return http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'success': true,
              'message': 'Đã gửi mã OTP',
              'devOtp': '123456',
            }),
          ),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );

    final result = await service.sendOtp('user@example.com');

    expect(result.message, 'Đã gửi mã OTP');
    expect(result.devOtp, '123456');
  });

  test('sendOtp accepts production response without devOtp', () async {
    final service = AuthService(
      baseUrlOverride: 'https://api.example.com/api',
      storage: storage,
      client: MockClient((request) async {
        expect(request.method, 'POST');
        expect(
          request.url.toString(),
          'https://api.example.com/api/auth/send-otp',
        );
        expect(jsonDecode(request.body), {'email': 'user@example.com'});
        return http.Response.bytes(
          utf8.encode(
            jsonEncode({'success': true, 'message': 'Đã gửi mã OTP'}),
          ),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );

    final result = await service.sendOtp('user@example.com');

    expect(result.message, 'Đã gửi mã OTP');
    expect(result.devOtp, isNull);
  });

  test('verifies OTP and persists tokens', () async {
    final service = AuthService(
      baseUrlOverride: 'https://api.example.com/api',
      storage: storage,
      client: MockClient((request) async {
        expect(request.method, 'POST');
        expect(
          request.url.toString(),
          'https://api.example.com/api/auth/verify-otp',
        );
        expect(jsonDecode(request.body), {
          'email': 'user@example.com',
          'otp': '123456',
        });
        return http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'success': true,
              'data': {
                'user': {'id': 'user-id', 'email': 'user@example.com'},
                'accessToken': 'access-token',
                'refreshToken': 'refresh-token',
              },
            }),
          ),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );

    final result = await service.verifyOtp(
      email: 'user@example.com',
      otp: '123456',
    );

    expect(result.userId, 'user-id');
    expect(result.accessToken, 'access-token');
    expect(await service.getAccessToken(), 'access-token');
    expect(await service.getRefreshToken(), 'refresh-token');
    expect(await service.getCurrentUserId(), 'user-id');
  });

  test('requests login OTP after password verification', () async {
    final service = AuthService(
      baseUrlOverride: 'https://api.example.com/api',
      storage: storage,
      client: MockClient((request) async {
        expect(request.method, 'POST');
        expect(
          request.url.toString(),
          'https://api.example.com/api/auth/login/request-otp',
        );
        expect(jsonDecode(request.body), {
          'email': 'user@example.com',
          'password': 'Password123',
        });
        return http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'success': true,
              'message': 'Đã gửi mã OTP',
              'devOtp': '123456',
            }),
          ),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );

    final result = await service.requestLoginOtp(
      email: 'user@example.com',
      password: 'Password123',
    );

    expect(result.message, 'Đã gửi mã OTP');
    expect(result.devOtp, '123456');
  });

  test('requestLoginOtp accepts production response without devOtp', () async {
    final service = AuthService(
      baseUrlOverride: 'https://api.example.com/api',
      storage: storage,
      client: MockClient((request) async {
        expect(request.method, 'POST');
        expect(
          request.url.toString(),
          'https://api.example.com/api/auth/login/request-otp',
        );
        expect(jsonDecode(request.body), {
          'email': 'user@example.com',
          'password': 'Password123',
        });
        return http.Response.bytes(
          utf8.encode(
            jsonEncode({'success': true, 'message': 'Đã gửi mã OTP đăng nhập'}),
          ),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );

    final result = await service.requestLoginOtp(
      email: 'user@example.com',
      password: 'Password123',
    );

    expect(result.message, 'Đã gửi mã OTP đăng nhập');
    expect(result.devOtp, isNull);
  });

  test('sets initial password with bearer token', () async {
    await storage.write(key: 'accessToken', value: 'access-token');
    final service = AuthService(
      baseUrlOverride: 'https://api.example.com/api',
      storage: storage,
      client: MockClient((request) async {
        expect(request.method, 'POST');
        expect(
          request.url.toString(),
          'https://api.example.com/api/auth/set-password',
        );
        expect(request.headers['Authorization'], 'Bearer access-token');
        expect(jsonDecode(request.body), {'password': 'Password123'});
        return http.Response(jsonEncode({'success': true}), 200);
      }),
    );

    await service.setPassword(password: 'Password123');
  });

  test('refreshes access token and persists new tokens', () async {
    await storage.write(key: 'refreshToken', value: 'old-refresh-token');
    final service = AuthService(
      baseUrlOverride: 'https://api.example.com/api',
      storage: storage,
      client: MockClient((request) async {
        expect(request.method, 'POST');
        expect(
          request.url.toString(),
          'https://api.example.com/api/auth/refresh',
        );
        expect(jsonDecode(request.body), {'refreshToken': 'old-refresh-token'});
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'accessToken': 'new-access-token',
              'refreshToken': 'new-refresh-token',
            },
          }),
          200,
        );
      }),
    );

    final result = await service.refreshAccessToken();

    expect(result.accessToken, 'new-access-token');
    expect(result.refreshToken, 'new-refresh-token');
    expect(await service.getAccessToken(), 'new-access-token');
    expect(await service.getRefreshToken(), 'new-refresh-token');
  });

  test('throws session expired when refresh token is rejected', () async {
    await storage.write(key: 'refreshToken', value: 'expired-refresh-token');
    final service = AuthService(
      baseUrlOverride: 'https://api.example.com/api',
      storage: storage,
      client: MockClient((request) async {
        expect(
          request.url.toString(),
          'https://api.example.com/api/auth/refresh',
        );
        expect(jsonDecode(request.body), {
          'refreshToken': 'expired-refresh-token',
        });
        return http.Response.bytes(
          utf8.encode(
            jsonEncode({'success': false, 'error': 'Refresh token hết hạn'}),
          ),
          401,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );

    await expectLater(
      service.refreshAccessToken(),
      throwsA(isA<SessionExpiredException>()),
    );
  });

  test('fetches current user with bearer token', () async {
    await storage.write(key: 'accessToken', value: 'access-token');
    final service = AuthService(
      baseUrlOverride: 'https://api.example.com/api',
      storage: storage,
      client: MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.toString(), 'https://api.example.com/api/auth/me');
        expect(request.headers['Authorization'], 'Bearer access-token');
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {'id': 'user-id', 'email': 'user@example.com'},
          }),
          200,
        );
      }),
    );

    final user = await service.getCurrentUser();

    expect(user['id'], 'user-id');
  });

  test(
    'restoreSession returns unauthenticated without auth calls when no token exists',
    () async {
      var requestCount = 0;
      final service = AuthService(
        baseUrlOverride: 'https://api.example.com/api',
        storage: storage,
        client: MockClient((request) async {
          requestCount++;
          return http.Response('{}', 500);
        }),
      );

      final result = await service.restoreSession();

      expect(result.status, SessionRestoreStatus.unauthenticated);
      expect(result.user, isNull);
      expect(requestCount, 0);
    },
  );

  test(
    'restoreSession fetches current user with a valid access token',
    () async {
      await storage.write(key: 'accessToken', value: 'access-token');
      await storage.write(key: 'refreshToken', value: 'refresh-token');
      final service = AuthService(
        baseUrlOverride: 'https://api.example.com/api',
        storage: storage,
        client: MockClient((request) async {
          expect(request.method, 'GET');
          expect(request.url.toString(), 'https://api.example.com/api/auth/me');
          expect(request.headers['Authorization'], 'Bearer access-token');
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'id': 'user-id',
                'email': 'user@example.com',
                'profile': {
                  'fullName': 'User',
                  'gender': 'MALE',
                  'birthDate': '2000-01-01',
                },
              },
            }),
            200,
          );
        }),
      );

      final result = await service.restoreSession();

      expect(result.status, SessionRestoreStatus.authenticated);
      expect(result.user?['id'], 'user-id');
    },
  );

  test(
    'restoreSession refreshes expired access token and retries current user',
    () async {
      await storage.write(key: 'accessToken', value: 'expired-access-token');
      await storage.write(key: 'refreshToken', value: 'old-refresh-token');
      var requestCount = 0;
      final service = AuthService(
        baseUrlOverride: 'https://api.example.com/api',
        storage: storage,
        client: MockClient((request) async {
          requestCount++;
          if (requestCount == 1) {
            expect(request.method, 'GET');
            expect(
              request.url.toString(),
              'https://api.example.com/api/auth/me',
            );
            expect(
              request.headers['Authorization'],
              'Bearer expired-access-token',
            );
            return http.Response(
              jsonEncode({'success': false, 'error': 'Unauthorized'}),
              401,
            );
          }
          if (requestCount == 2) {
            expect(request.method, 'POST');
            expect(
              request.url.toString(),
              'https://api.example.com/api/auth/refresh',
            );
            expect(jsonDecode(request.body), {
              'refreshToken': 'old-refresh-token',
            });
            return http.Response(
              jsonEncode({
                'success': true,
                'data': {
                  'accessToken': 'new-access-token',
                  'refreshToken': 'new-refresh-token',
                },
              }),
              200,
            );
          }

          expect(request.method, 'GET');
          expect(request.url.toString(), 'https://api.example.com/api/auth/me');
          expect(request.headers['Authorization'], 'Bearer new-access-token');
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {'id': 'user-id', 'email': 'user@example.com'},
            }),
            200,
          );
        }),
      );

      final result = await service.restoreSession();

      expect(result.status, SessionRestoreStatus.authenticated);
      expect(result.user?['id'], 'user-id');
      expect(await service.getAccessToken(), 'new-access-token');
      expect(await service.getRefreshToken(), 'new-refresh-token');
      expect(requestCount, 3);
    },
  );

  test(
    'restoreSession clears storage when refresh token is rejected',
    () async {
      await storage.write(key: 'accessToken', value: 'expired-access-token');
      await storage.write(key: 'refreshToken', value: 'expired-refresh-token');
      await storage.write(key: 'userId', value: 'user-id');
      var requestCount = 0;
      final service = AuthService(
        baseUrlOverride: 'https://api.example.com/api',
        storage: storage,
        client: MockClient((request) async {
          requestCount++;
          if (requestCount == 1) {
            return http.Response(
              jsonEncode({'success': false, 'error': 'Unauthorized'}),
              401,
            );
          }
          expect(
            request.url.toString(),
            'https://api.example.com/api/auth/refresh',
          );
          // Phải khai báo charset=utf-8 để body tiếng Việt giải mã đúng (giống
          // NextResponse.json của server). Nếu không, http dùng latin1 và ném
          // lỗi mã hoá — không phản ánh hành vi thật của server.
          return http.Response.bytes(
            utf8.encode(
              jsonEncode({'success': false, 'error': 'Refresh token hết hạn'}),
            ),
            401,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );

      final result = await service.restoreSession();

      expect(result.status, SessionRestoreStatus.expired);
      expect(await service.getAccessToken(), isNull);
      expect(await service.getRefreshToken(), isNull);
      expect(await service.getCurrentUserId(), isNull);
    },
  );

  test('logout calls server and clears local storage', () async {
    await storage.write(key: 'accessToken', value: 'access-token');
    await storage.write(key: 'refreshToken', value: 'refresh-token');
    await storage.write(key: 'userId', value: 'user-id');
    final service = AuthService(
      baseUrlOverride: 'https://api.example.com/api',
      storage: storage,
      client: MockClient((request) async {
        expect(request.method, 'POST');
        expect(
          request.url.toString(),
          'https://api.example.com/api/auth/logout',
        );
        expect(request.headers['Authorization'], 'Bearer access-token');
        expect(jsonDecode(request.body), {'refreshToken': 'refresh-token'});
        return http.Response(jsonEncode({'success': true}), 200);
      }),
    );

    await service.logout();

    expect(await service.getAccessToken(), isNull);
    expect(await service.getRefreshToken(), isNull);
    expect(await service.getCurrentUserId(), isNull);
  });

  test('logout clears local storage when server logout fails', () async {
    await storage.write(key: 'accessToken', value: 'access-token');
    await storage.write(key: 'refreshToken', value: 'refresh-token');
    await storage.write(key: 'userId', value: 'user-id');
    final service = AuthService(
      baseUrlOverride: 'https://api.example.com/api',
      storage: storage,
      client: MockClient((request) async {
        expect(
          request.url.toString(),
          'https://api.example.com/api/auth/logout',
        );
        return http.Response(jsonEncode({'success': false}), 500);
      }),
    );

    await service.logout();

    expect(await service.getAccessToken(), isNull);
    expect(await service.getRefreshToken(), isNull);
    expect(await service.getCurrentUserId(), isNull);
  });

  test('throws when protected actions require a missing token', () async {
    final service = AuthService(
      baseUrlOverride: 'https://api.example.com/api',
      storage: storage,
      client: MockClient((request) async => http.Response('{}', 200)),
    );

    await expectLater(
      service.requireAccessToken(),
      throwsA(isA<AuthRequiredException>()),
    );
  });

  test('resolves chat websocket URL from the API host on /ws', () {
    final url = AuthService.resolveWsUrl(
      chatId: 'chat 1',
      accessToken: 'token value',
      baseUrlOverride: 'https://api.example.com:8443/api',
      wsUrlOverride: '',
    );

    final uri = Uri.parse(url);
    expect(uri.scheme, 'wss');
    expect(uri.host, 'api.example.com');
    expect(uri.port, 8443);
    expect(uri.path, '/ws');
    expect(uri.queryParameters['chatId'], 'chat 1');
    expect(uri.queryParameters['token'], 'token value');
  });

  test('resolves chat websocket URL from explicit override', () {
    final url = AuthService.resolveWsUrl(
      chatId: 'chat-1',
      accessToken: 'token',
      wsUrlOverride: 'ws://localhost:3000/ws',
    );

    final uri = Uri.parse(url);
    expect(uri.scheme, 'ws');
    expect(uri.host, 'localhost');
    expect(uri.port, 3000);
    expect(uri.path, '/ws');
    expect(uri.queryParameters['chatId'], 'chat-1');
    expect(uri.queryParameters['token'], 'token');
  });
}
