import 'dart:async';

import 'package:bondy/services/ai_service.dart';
import 'package:bondy/services/api_client.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordingApiClient extends ApiClient {
  String? path;
  Map<String, dynamic>? body;

  @override
  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = false,
  }) async {
    this.path = path;
    this.body = body;
    return {
      'success': true,
      'data': {
        'flowVersion': 'coach-v2',
        'chatId': 'chat-1',
        'matchId': 'match-1',
        'partnerId': 'partner-1',
        'partnerName': 'Linh',
        'response': '1. Chào Linh',
        'mode': 'coach',
        'suggestions': ['Chào Linh'],
        'meta': {},
      },
    };
  }
}

class _PendingApiClient extends ApiClient {
  @override
  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = false,
  }) {
    return Completer<Map<String, dynamic>>().future;
  }
}

void main() {
  test('coach chat request sends the explicit match contract', () {
    final request = AiChatRequest(
      chatId: 'chat-1',
      message: 'Gợi ý tin nhắn tiếp theo',
      matchId: 'match-1',
      intent: 'continue',
      tone: 'casual',
      count: 3,
    );

    expect(request.toJson(), {
      'chatId': 'chat-1',
      'matchId': 'match-1',
      'message': 'Gợi ý tin nhắn tiếp theo',
      'intent': 'continue',
      'tone': 'casual',
      'count': 3,
      'language': 'vi',
    });
  });

  test('coach chat uses the dedicated JSON endpoint', () async {
    final apiClient = _RecordingApiClient();
    final service = AiService(apiClient);
    final request = AiChatRequest(
      chatId: 'chat-1',
      matchId: 'match-1',
      message: 'Gợi ý',
    );

    final response = await service.chatCoach(request);

    expect(apiClient.path, '/ai/coach/suggestions');
    expect(apiClient.body, request.toJson());
    expect(response.data?.flowVersion, 'coach-v2');
  });

  test('coach chat defaults to a 120 second timeout', () {
    final service = AiService(_RecordingApiClient());

    expect(service.coachTimeout, const Duration(seconds: 120));
  });

  test('coach chat surfaces timeout after the configured limit', () async {
    final service = AiService(
      _PendingApiClient(),
      coachTimeout: const Duration(milliseconds: 5),
    );

    await expectLater(
      service.chatCoach(
        AiChatRequest(chatId: 'chat-1', matchId: 'match-1', message: 'Gợi ý'),
      ),
      throwsA(isA<TimeoutException>()),
    );
  });
}
