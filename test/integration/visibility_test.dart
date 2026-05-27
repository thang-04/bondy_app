import 'dart:convert';

import 'package:bondy/services/api_client.dart';
import 'package:bondy/services/auth_service.dart';
import 'package:bondy/services/chat_service.dart';
import 'package:bondy/services/discover_service.dart';
import 'package:bondy/services/home_service.dart';
import 'package:bondy/services/profile_service.dart';
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
    final authService = AuthService(baseUrlOverride: 'https://api.example.com/api', storage: storage);
    return ApiClient(
      baseUrlOverride: 'https://api.example.com/api',
      authService: authService,
      client: client,
    );
  }

  test('profile service calls backend profile and interests endpoints', () async {
    final seen = <String>[];
    final apiClient = await authenticatedClient(MockClient((request) async {
      seen.add('${request.method} ${request.url.path}');
      switch (request.url.path) {
        case '/api/profile/me':
          expect(request.method, 'PATCH');
          expect(request.headers['authorization'], 'Bearer access-token');
          return http.Response(jsonEncode({'success': true, 'data': {'id': 'profile-id'}}), 200);
        case '/api/profile/location':
          expect(request.method, 'PATCH');
          expect(request.headers['authorization'], 'Bearer access-token');
          return http.Response(jsonEncode({'success': true, 'data': {'city': 'Ho Chi Minh'}}), 200);
        case '/api/profile/interests':
          expect(request.method, 'PUT');
          expect(request.headers['authorization'], 'Bearer access-token');
          expect(jsonDecode(request.body), {'interestIds': ['int-1']});
          return http.Response(jsonEncode({'success': true, 'data': {'saved': 1}}), 200);
        default:
          fail('Unexpected authenticated profile request: ${request.method} ${request.url}');
      }
    }));
    final service = ProfileService(apiClient: apiClient);

    await service.updateProfile(fullName: 'Linh', gender: 'Nữ', birthDate: '2000-01-02');
    await service.updateLocation(city: 'Ho Chi Minh', latitude: 10.762622, longitude: 106.660172);
    await service.saveInterests(['int-1']);

    expect(seen, containsAll(['PATCH /api/profile/me', 'PATCH /api/profile/location', 'PUT /api/profile/interests']));
  });

  test('profile service fetches interests without auth', () async {
    final apiClient = ApiClient(
      baseUrlOverride: 'https://api.example.com/api',
      client: MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/interests');
        expect(request.headers.containsKey('authorization'), false);
        return http.Response(jsonEncode({
          'success': true,
          'data': [
            {'id': 'int-1', 'name': 'Music'},
          ],
        }), 200);
      }),
    );
    final service = ProfileService(apiClient: apiClient);

    final result = await service.getInterests();

    expect(result.single['id'], 'int-1');
  });

  test('discover service calls discover and swipe endpoints', () async {
    final seen = <String>[];
    final apiClient = await authenticatedClient(MockClient((request) async {
      seen.add('${request.method} ${request.url.path}');
      expect(request.headers['authorization'], 'Bearer access-token');
      if (request.url.path == '/api/discover/profiles') {
        expect(request.method, 'GET');
        return http.Response(jsonEncode({'success': true, 'data': []}), 200);
      }
      if (request.url.path == '/api/swipes') {
        expect(request.method, 'POST');
        expect(jsonDecode(request.body), {'targetUserId': 'user-2', 'action': 'LIKE'});
        return http.Response(jsonEncode({'success': true, 'data': {}}), 200);
      }
      fail('Unexpected discover request: ${request.method} ${request.url}');
    }));
    final service = DiscoverService(apiClient: apiClient);

    await service.fetchProfiles();
    await service.swipe(targetUserId: 'user-2', action: 'LIKE');

    expect(seen, containsAll(['GET /api/discover/profiles', 'POST /api/swipes']));
  });

  test('chat service calls chat list and message endpoints', () async {
    final seen = <String>[];
    final apiClient = await authenticatedClient(MockClient((request) async {
      seen.add('${request.method} ${request.url.path}');
      expect(request.headers['authorization'], 'Bearer access-token');
      if (request.url.path == '/api/chats') {
        expect(request.method, 'GET');
        return http.Response(jsonEncode({'success': true, 'data': []}), 200);
      }
      if (request.url.path == '/api/chats/chat-1/messages' && request.method == 'GET') {
        return http.Response(jsonEncode({'success': true, 'data': []}), 200);
      }
      if (request.url.path == '/api/chats/chat-1/messages' && request.method == 'POST') {
        expect(jsonDecode(request.body), {'content': 'Hi'});
        return http.Response(jsonEncode({
          'success': true,
          'data': {
            'id': 'msg-1',
            'content': 'Hi',
            'senderId': 'user-1',
            'isRead': false,
            'createdAt': '2026-04-29T00:00:00.000Z',
          },
        }), 200);
      }
      fail('Unexpected chat request: ${request.method} ${request.url}');
    }));
    final service = ChatService(apiClient);

    await service.listChats();
    await service.listMessages('chat-1');
    await service.sendMessage('chat-1', 'Hi');

    expect(seen, containsAll(['GET /api/chats', 'GET /api/chats/chat-1/messages', 'POST /api/chats/chat-1/messages']));
  });

  test('home service calls home content endpoint', () async {
    final apiClient = ApiClient(
      baseUrlOverride: 'https://api.example.com/api',
      client: MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/home/content');
        expect(request.url.queryParameters['userId'], 'user-1');
        return http.Response(jsonEncode({
          'success': true,
          'data': {'widgets': []},
        }), 200);
      }),
    );
    final service = HomeService(apiClient: apiClient);

    final result = await service.fetchHomeContent('user-1');

    expect(result, isEmpty);
  });
}
