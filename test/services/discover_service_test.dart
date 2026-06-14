import 'dart:convert';

import 'package:bondy/models/discover/discover_profile_model.dart';
import 'package:bondy/services/api_client.dart';
import 'package:bondy/services/auth_service.dart';
import 'package:bondy/services/discover_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    FlutterSecureStorage.setMockInitialValues({});
  });

  Future<ApiClient> authenticatedClient(http.Client client) async {
    const storage = FlutterSecureStorage();
    await storage.write(key: 'accessToken', value: 'access-token');
    final authService = AuthService(
      baseUrlOverride: 'https://api.example.com/api',
      storage: storage,
    );
    return ApiClient(
      baseUrlOverride: 'https://api.example.com/api',
      authService: authService,
      client: client,
    );
  }

  test('loads discover candidates', () async {
    final apiClient = await authenticatedClient(
      MockClient((request) async {
        expect(request.method, 'GET');
        expect(
          request.url.toString(),
          'https://api.example.com/api/discover/profiles?limit=50',
        );
        expect(request.headers['authorization'], 'Bearer access-token');
        return http.Response(
          jsonEncode({
            'success': true,
            'data': [
              {
                'userId': 'candidate-id',
                'name': 'Linh',
                'age': 24,
                'city': 'Ho Chi Minh',
                'bio': 'Xin chao',
                'commonInterests': ['Music'],
                'photos': [
                  {'url': 'https://example.com/photo.jpg', 'isPrimary': true},
                ],
              },
            ],
          }),
          200,
        );
      }),
    );
    final service = DiscoverService(apiClient: apiClient);

    final profiles = await service.fetchProfiles();

    expect(profiles.single.id, 'candidate-id');
    expect(profiles.single.name, 'Linh');
    expect(profiles.single.tags, ['Music']);
  });

  test('sends swipe actions', () async {
    final apiClient = await authenticatedClient(
      MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.toString(), 'https://api.example.com/api/swipes');
        expect(request.headers['authorization'], 'Bearer access-token');
        expect(jsonDecode(request.body), {
          'targetUserId': 'candidate-id',
          'action': 'LIKE',
        });
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {'matched': false, 'matchId': null},
          }),
          200,
        );
      }),
    );
    final service = DiscoverService(apiClient: apiClient);

    await expectLater(
      service.swipe(targetUserId: 'candidate-id', action: 'LIKE'),
      completes,
    );
  });

  test('parses instant match chat id from swipe response', () async {
    final apiClient = await authenticatedClient(
      MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.toString(), 'https://api.example.com/api/swipes');
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'matched': true,
              'matchId': 'match-123',
              'conversationId': 'chat-456',
            },
          }),
          200,
        );
      }),
    );
    final service = DiscoverService(apiClient: apiClient);

    final result = await service.swipe(
      targetUserId: 'candidate-id',
      action: 'LIKE',
    );

    expect(result.matched, true);
    expect(result.matchId, 'match-123');
    expect(result.conversationId, 'chat-456');
  });

  test('parses instant match preview users from swipe response', () async {
    final apiClient = await authenticatedClient(
      MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'matched': true,
              'matchId': 'match-123',
              'conversationId': 'chat-456',
              'matchPreview': {
                'matchId': 'match-123',
                'conversationId': 'chat-456',
                'users': {
                  'current': {
                    'id': 'me',
                    'name': 'An',
                    'photo': 'https://example.com/me.jpg',
                  },
                  'other': {
                    'id': 'candidate-id',
                    'name': 'Linh',
                    'photo': 'https://example.com/linh.jpg',
                  },
                },
              },
            },
          }),
          200,
        );
      }),
    );
    final service = DiscoverService(apiClient: apiClient);

    final result = await service.swipe(
      targetUserId: 'candidate-id',
      action: 'LIKE',
    );

    expect(result.matchPreview?.current.photo, 'https://example.com/me.jpg');
    expect(result.matchPreview?.other.name, 'Linh');
    expect(result.matchPreview?.other.photo, 'https://example.com/linh.jpg');
  });

  test('saves canonical discover gender filters', () async {
    final apiClient = await authenticatedClient(
      MockClient((request) async {
        expect(request.method, 'POST');
        expect(
          request.url.toString(),
          'https://api.example.com/api/discover/filters',
        );
        expect(request.headers['authorization'], 'Bearer access-token');
        expect(jsonDecode(request.body), {
          'minAge': 24,
          'maxAge': 36,
          'distanceKm': 25,
          'genders': ['FEMALE'],
          'goals': ['LONG_TERM'],
          'minCompatibility': 70,
        });
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'ageMin': 24,
              'ageMax': 36,
              'distanceKm': 25,
              'genders': ['FEMALE'],
              'goals': ['LONG_TERM'],
              'minCompatibility': 70,
            },
          }),
          200,
        );
      }),
    );
    final service = DiscoverService(apiClient: apiClient);

    await service.saveFilters(
      const DiscoverFilters(
        minAge: 24,
        maxAge: 36,
        maxDistance: 25,
        genders: ['FEMALE'],
        goals: ['LONG_TERM'],
        minCompatibility: 70,
      ),
    );
  });
}
