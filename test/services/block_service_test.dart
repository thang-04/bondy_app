import 'dart:convert';

import 'package:bondy/services/api_client.dart';
import 'package:bondy/services/auth_service.dart';
import 'package:bondy/services/block_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('BlockService', () {
    test('creates block for target user', () async {
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
          expect(request.headers['authorization'], 'Bearer access-token');
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['blockedUserId'], 'blocked-user-id');
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'blockId': 'block-123',
                'blockedAt': '2026-05-18T10:00:00Z',
              },
            }),
            200,
          );
        }),
      );
      final service = BlockService(apiClient);

      final result = await service.createBlock(
        blockedUserId: 'blocked-user-id',
      );

      expect(result.blockId, 'block-123');
      expect(result.blockedAt.isNotEmpty, true);
    });

    test('throws ApiClientException when block fails', () async {
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
            jsonEncode({'success': false, 'error': 'User not found'}),
            404,
          );
        }),
      );
      final service = BlockService(apiClient);

      expect(
        () => service.createBlock(blockedUserId: 'nonexistent'),
        throwsA(isA<ApiClientException>()),
      );
    });

    test('block result parses blockedAt correctly', () async {
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
              'data': {
                'blockId': 'block-456',
                'blockedAt': '2026-05-18T15:30:00Z',
              },
            }),
            200,
          );
        }),
      );
      final service = BlockService(apiClient);

      final result = await service.createBlock(blockedUserId: 'user-to-block');

      expect(result.blockId, 'block-456');
      expect(result.blockedAt, '2026-05-18T15:30:00Z');
    });
  });
}
