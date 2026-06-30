import 'dart:async';

import 'package:bondy/services/ai_service.dart';
import 'package:bondy/services/api_client.dart';
import 'package:bondy/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

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

class _QuotaApiClient extends ApiClient {
  @override
  Future<Map<String, dynamic>> get(
    String path, {
    bool authenticated = false,
    Map<String, dynamic>? queryParams,
  }) async {
    return {
      'success': true,
      'data': {
        'tier': 'FREE',
        'resetsAt': '2026-06-13T17:00:00.000Z',
        'quotas': {
          'healing': {
            'mode': 'healing',
            'feature': 'daily_ai_healing',
            'label': 'AI chua lanh',
            'tier': 'FREE',
            'limit': 3,
            'used': 1,
            'remaining': 2,
            'resetsAt': '2026-06-13T17:00:00.000Z',
          },
          'coach': {
            'mode': 'coach',
            'feature': 'daily_ai_coach',
            'label': 'Goi y tro chuyen',
            'tier': 'FREE',
            'limit': 3,
            'used': 0,
            'remaining': 3,
            'resetsAt': '2026-06-13T17:00:00.000Z',
          },
        },
        'dailyLimitsByTier': {
          'FREE': {'healing': 3, 'coach': 3},
          'PLUS': {'healing': 20, 'coach': 20},
          'PREMIUM': {'healing': 50, 'coach': 50},
          'ELITE': {'healing': 100, 'coach': 100},
        },
      },
    };
  }
}

class _TokenAuthService extends AuthService {
  @override
  Future<String> requireAccessToken() async => 'access-token';
}

class _StreamingClient extends http.BaseClient {
  http.Request? request;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    this.request = request as http.Request;
    final stream = Stream<List<int>>.fromIterable([
      'event: chunk\ndata: "Xin chao "\n\n'.codeUnits,
      'event: chunk\ndata: "ban"\n\n'.codeUnits,
      'event: metadata\ndata: {"mode":"healing","quota":{"mode":"healing","feature":"daily_ai_healing","label":"AI chua lanh","tier":"FREE","limit":3,"used":2,"remaining":1,"resetsAt":"2026-06-13T17:00:00.000Z"}}\n\n'
          .codeUnits,
    ]);
    return http.StreamedResponse(
      stream,
      200,
      headers: {'content-type': 'text/event-stream'},
    );
  }
}

void main() {
  test('parses daily AI quota summary by mode and tier', () async {
    final service = AiService(_QuotaApiClient());

    final summary = await service.getQuota();

    expect(summary.tier, 'FREE');
    expect(summary.quotaFor(AiChatMode.healing)?.remaining, 2);
    expect(summary.quotaFor(AiChatMode.coach)?.limit, 3);
    expect(summary.limitForTier('ELITE', AiChatMode.healing), 100);
    expect(summary.limitForTier('PLUS', AiChatMode.coach), 20);
  });

  test('streams healing chat chunks and metadata quota', () async {
    final httpClient = _StreamingClient();
    final service = AiService(
      ApiClient(baseUrlOverride: 'https://api.example.com/api'),
      authService: _TokenAuthService(),
      httpClient: httpClient,
    );

    final events = await service
        .streamChat(
          AiStreamChatRequest(
            messages: const [
              AiChatMessage(
                role: AiChatMessageRole.user,
                content: 'Hom nay minh buon',
              ),
            ],
            mode: AiChatMode.healing,
            sessionId: 'healing-session-1',
          ),
        )
        .toList();

    expect(httpClient.request?.url.path, '/api/ai/chat');
    expect(httpClient.request?.body, isNot(contains('"message"')));
    expect(httpClient.request?.body, contains('"messages"'));
    expect(httpClient.request?.body, contains('"role":"user"'));
    expect(httpClient.request?.body, contains('"content":"Hom nay minh buon"'));
    expect(httpClient.request?.body, contains('"mode":"healing"'));
    expect(
      httpClient.request?.body,
      contains('"sessionId":"healing-session-1"'),
    );
    expect(
      events.where((event) => event.type == AiStreamEventType.chunk),
      hasLength(2),
    );
    expect(events.last.metadata?.quota?.remaining, 1);
  });

  test('supports all AI chat modes exposed by the server', () {
    expect(AiChatMode.fromJson('default'), AiChatMode.defaultMode);
    expect(AiChatMode.fromJson('healing'), AiChatMode.healing);
    expect(AiChatMode.fromJson('coach'), AiChatMode.coach);
    expect(AiChatMode.fromJson('plan'), AiChatMode.plan);
    expect(AiChatMode.fromJson('ai-tu-vi'), AiChatMode.aiTuVi);
    expect(AiChatMode.fromJson('tarot'), AiChatMode.tarot);
    expect(AiChatMode.tarot.apiValue, 'tarot');
  });

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
