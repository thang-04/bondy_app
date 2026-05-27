import 'dart:convert';

import 'package:bondy/services/api_client.dart';
import 'package:bondy/services/auth_service.dart';
import 'package:bondy/services/chat_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('lists chats for the authenticated user', () async {
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
        expect(request.method, 'GET');
        expect(request.headers['authorization'], 'Bearer access-token');
        return http.Response(
          jsonEncode({
            'success': true,
            'data': [
              {
                'id': 'chat-1',
                'matchId': 'match-1',
                'otherUser': {
                  'id': 'user-2',
                  'firstName': 'Minh',
                  'lastName': 'Anh',
                  'photo': null,
                },
                'lastMessage': {
                  'content': 'Xin chao',
                  'createdAt': '2026-04-29T10:00:00Z',
                  'isMine': false,
                },
                'updatedAt': '2026-04-29T10:00:00Z',
              },
            ],
          }),
          200,
        );
      }),
    );
    final service = ChatService(apiClient);

    final chats = await service.listChats();

    expect(chats.length, 1);
    expect(chats[0].id, 'chat-1');
    expect(chats[0].otherUser.displayName, 'Minh Anh');
  });

  test('lists messages for a chat', () async {
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
        expect(request.method, 'GET');
        expect(request.headers['authorization'], 'Bearer access-token');
        return http.Response(
          jsonEncode({
            'success': true,
            'data': [
              {
                'id': 'msg-1',
                'content': 'Xin chao',
                'senderId': 'user-2',
                'isRead': false,
                'createdAt': '2026-04-29T10:00:00Z',
              },
            ],
          }),
          200,
        );
      }),
    );
    final service = ChatService(apiClient);

    final messages = await service.listMessages('chat-1');

    expect(messages.length, 1);
    expect(messages[0].id, 'msg-1');
    expect(messages[0].content, 'Xin chao');
  });

  test('sends text messages to a chat', () async {
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
        expect(jsonDecode(request.body), {
          'content': 'Hello',
          'messageType': 'TEXT',
        });
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'id': 'msg-2',
              'content': 'Hello',
              'senderId': 'user-1',
              'isRead': false,
              'createdAt': '2026-04-29T10:05:00Z',
            },
          }),
          200,
        );
      }),
    );
    final service = ChatService(apiClient);

    final message = await service.sendMessage('chat-1', 'Hello');

    expect(message.id, 'msg-2');
    expect(message.content, 'Hello');
  });
}
