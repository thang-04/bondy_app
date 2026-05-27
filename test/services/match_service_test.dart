import 'dart:convert';

import 'package:bondy/services/api_client.dart';
import 'package:bondy/services/auth_service.dart';
import 'package:bondy/services/match_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('MatchService', () {
    test('deletes match via DELETE', () async {
      final storage = FlutterSecureStorage();
      await storage.write(key: 'accessToken', value: 'access-token');
      final authService = AuthService(
        baseUrlOverride: 'https://api.example.com/api',
        storage: storage,
      );
      final apiClient = ApiClient(
        baseUrlOverride: 'https://api.example.com/api',
        authService: authService,
        client: MockClient((request) async {
          expect(request.method, 'DELETE');
          expect(request.headers['authorization'], 'Bearer access-token');
          expect(request.url.path, '/api/matches/match-123');
          return http.Response(jsonEncode({'success': true}), 200);
        }),
      );
      final service = MatchService(apiClient);

      final result = await service.unmatch('match-123');

      expect(result, true);
    });

    test('unmatch throws ApiClientException when match not found', () async {
      final storage = FlutterSecureStorage();
      await storage.write(key: 'accessToken', value: 'access-token');
      final authService = AuthService(
        baseUrlOverride: 'https://api.example.com/api',
        storage: storage,
      );
      final apiClient = ApiClient(
        baseUrlOverride: 'https://api.example.com/api',
        authService: authService,
        client: MockClient((request) async {
          return http.Response(
            jsonEncode({'success': false, 'error': 'Match not found'}),
            404,
          );
        }),
      );
      final service = MatchService(apiClient);

      expect(
        () => service.unmatch('nonexistent'),
        throwsA(isA<ApiClientException>()),
      );
    });

    test('confirmMatch calls correct endpoint', () async {
      final storage = FlutterSecureStorage();
      await storage.write(key: 'accessToken', value: 'access-token');
      final authService = AuthService(
        baseUrlOverride: 'https://api.example.com/api',
        storage: storage,
      );
      final apiClient = ApiClient(
        baseUrlOverride: 'https://api.example.com/api',
        authService: authService,
        client: MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.path, '/api/matches/match-123/confirm');
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'matchId': 'match-123',
                'status': 'CONFIRMED',
                'chatId': 'chat-456',
              },
            }),
            200,
          );
        }),
      );
      final service = MatchService(apiClient);

      final result = await service.confirmMatch('match-123');

      expect(result.isConfirmed, true);
      expect(result.chatId, 'chat-456');
    });

    test(
      'confirmMatch returns PENDING when other user not confirmed',
      () async {
        final storage = FlutterSecureStorage();
        await storage.write(key: 'accessToken', value: 'access-token');
        final authService = AuthService(
          baseUrlOverride: 'https://api.example.com/api',
          storage: storage,
        );
        final apiClient = ApiClient(
          baseUrlOverride: 'https://api.example.com/api',
          authService: authService,
          client: MockClient((request) async {
            return http.Response(
              jsonEncode({
                'success': true,
                'data': {'matchId': 'match-123', 'status': 'PENDING'},
              }),
              200,
            );
          }),
        );
        final service = MatchService(apiClient);

        final result = await service.confirmMatch('match-123');

        expect(result.isConfirmed, false);
      },
    );
  });
}
