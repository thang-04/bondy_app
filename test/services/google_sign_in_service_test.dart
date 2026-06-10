import 'dart:convert';

import 'package:bondy/services/auth_service.dart';
import 'package:bondy/services/google_sign_in_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('loginWithGoogle posts idToken and parses backend tokens', () async {
    final service = GoogleSignInService(
      baseUrlOverride: 'https://api.example.com/api',
      client: MockClient((request) async {
        expect(request.method, 'POST');
        expect(
          request.url.toString(),
          'https://api.example.com/api/auth/google',
        );
        expect(request.headers['Content-Type'], 'application/json');
        expect(jsonDecode(request.body), {'idToken': 'google-id-token'});
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'accessToken': 'access-token',
              'refreshToken': 'refresh-token',
              'user': {
                'id': 'user-id',
                'email': 'user@example.com',
                'name': 'User',
                'image': 'https://example.com/avatar.png',
                'isNewUser': false,
              },
            },
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );

    final result = await service.loginWithGoogle('google-id-token');

    expect(result.userId, 'user-id');
    expect(result.email, 'user@example.com');
    expect(result.accessToken, 'access-token');
    expect(result.refreshToken, 'refresh-token');
    expect(result.name, 'User');
    expect(result.image, 'https://example.com/avatar.png');
    expect(result.isNewUser, isFalse);
  });

  test('loginWithGoogle surfaces account-link conflict', () async {
    final service = GoogleSignInService(
      baseUrlOverride: 'https://api.example.com/api',
      client: MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'code': 'ACCOUNT_EXISTS_LINK',
            'error': 'Email này đã có tài khoản.',
          }),
          409,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );

    await expectLater(
      service.loginWithGoogle('google-id-token'),
      throwsA(
        isA<AccountExistsException>().having(
          (error) => error.message,
          'message',
          'Email này đã có tài khoản.',
        ),
      ),
    );
  });

  test('loginWithGoogle rejects non-json backend responses', () async {
    final service = GoogleSignInService(
      baseUrlOverride: 'https://api.example.com/api',
      client: MockClient((request) async {
        return http.Response(
          '<html>gateway error</html>',
          502,
          headers: {'content-type': 'text/html; charset=utf-8'},
        );
      }),
    );

    await expectLater(
      service.loginWithGoogle('google-id-token'),
      throwsA(
        isA<AuthServiceException>().having(
          (error) => error.message,
          'message',
          contains('Mã lỗi: 502'),
        ),
      ),
    );
  });

  test('confirmLinkAccount sends confirmLink flag', () async {
    final service = GoogleSignInService(
      baseUrlOverride: 'https://api.example.com/api',
      client: MockClient((request) async {
        expect(request.method, 'PUT');
        expect(
          request.url.toString(),
          'https://api.example.com/api/auth/google',
        );
        expect(jsonDecode(request.body), {
          'idToken': 'google-id-token',
          'confirmLink': true,
        });
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'accessToken': 'linked-access-token',
              'refreshToken': 'linked-refresh-token',
              'user': {
                'id': 'user-id',
                'email': 'user@example.com',
                'isNewUser': false,
              },
            },
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );

    final result = await service.confirmLinkAccount('google-id-token');

    expect(result.accessToken, 'linked-access-token');
    expect(result.refreshToken, 'linked-refresh-token');
  });
}
