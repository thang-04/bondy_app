import 'dart:async';

import 'package:bondy/services/ai_service.dart';
import 'package:bondy/services/api_client.dart';
import 'package:bondy/viewmodels/ai/ai_coach_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAiService extends AiService {
  final Future<AiChatResponse> Function(AiChatRequest request) handler;
  AiChatRequest? lastRequest;
  int chatCoachCallCount = 0;

  _FakeAiService(AiChatResponse response)
    : handler = ((_) async => response),
      super(ApiClient());

  _FakeAiService.handler(this.handler) : super(ApiClient());

  @override
  Future<AiChatResponse> chatCoach(AiChatRequest request) async {
    chatCoachCallCount++;
    lastRequest = request;
    return handler(request);
  }
}

AiChatResponse _successResponse({
  String chatId = 'chat-1',
  String matchId = 'match-1',
  String partnerId = 'partner-1',
}) {
  return AiChatResponse.fromJson({
    'success': true,
    'data': {
      'flowVersion': 'coach-v2',
      'chatId': chatId,
      'matchId': matchId,
      'partnerId': partnerId,
      'partnerName': 'Linh',
      'response': '1. Chào Linh',
      'mode': 'coach',
      'suggestions': ['Chào Linh'],
      'meta': {
        'tokensUsed': 10,
        'latencyMs': 20,
        'quota': {
          'mode': 'coach',
          'feature': 'daily_ai_coach',
          'label': 'Goi y tro chuyen',
          'tier': 'FREE',
          'limit': 3,
          'used': 1,
          'remaining': 2,
          'resetsAt': '2026-06-13T17:00:00.000Z',
        },
      },
    },
  });
}

void main() {
  test('starts without a selected intent', () {
    final viewModel = AiCoachViewModel();

    expect(viewModel.selectedIntent, isNull);
  });

  test('reset clears the selected intent', () {
    final viewModel = AiCoachViewModel()
      ..selectIntent(AiIntent.continueChat)
      ..suggestions = ['Chao Linh'];

    viewModel.reset();

    expect(viewModel.selectedIntent, isNull);
    expect(viewModel.suggestions, isEmpty);
  });

  test(
    'does not request personalized suggestions without selected intent',
    () async {
      final service = _FakeAiService(_successResponse());
      final viewModel = AiCoachViewModel(aiService: service);

      await viewModel.getPersonalizedSuggestions(
        chatId: 'chat-1',
        matchId: 'match-1',
        expectedPartnerId: 'partner-1',
      );

      expect(service.chatCoachCallCount, 0);
      expect(service.lastRequest, isNull);
      expect(viewModel.isLoading, isFalse);
      expect(viewModel.suggestions, isEmpty);
    },
  );

  test(
    'requests structured personalized suggestions for the selected match',
    () async {
      final service = _FakeAiService(_successResponse());
      final viewModel = AiCoachViewModel(aiService: service)
        ..selectIntent(AiIntent.continueChat);

      await viewModel.getPersonalizedSuggestions(
        chatId: 'chat-1',
        matchId: 'match-1',
        expectedPartnerId: 'partner-1',
      );

      expect(service.lastRequest?.chatId, 'chat-1');
      expect(service.lastRequest?.matchId, 'match-1');
      expect(service.lastRequest?.intent, 'continue');
      expect(service.lastRequest?.tone, 'casual');
      expect(service.lastRequest?.count, 3);
      expect(viewModel.quota?.remaining, 2);
      expect(viewModel.suggestions, ['Chào Linh']);
      expect(viewModel.errorMessage, isNull);
    },
  );

  test('does not expose a failed pipeline response as a suggestion', () async {
    final service = _FakeAiService(
      AiChatResponse.fromJson({
        'success': true,
        'data': {
          'flowVersion': 'coach-v2',
          'chatId': 'chat-1',
          'matchId': 'match-1',
          'partnerId': 'partner-1',
          'partnerName': 'Linh',
          'response': 'Mình xin lỗi, có lỗi xảy ra.',
          'mode': 'coach',
          'meta': {'failed': true},
        },
      }),
    );
    final viewModel = AiCoachViewModel(aiService: service);
    viewModel.selectIntent(AiIntent.continueChat);

    await viewModel.getPersonalizedSuggestions(
      chatId: 'chat-1',
      matchId: 'match-1',
      expectedPartnerId: 'partner-1',
    );

    expect(viewModel.suggestions, isEmpty);
    expect(viewModel.errorMessage, isNotNull);
  });

  test('rejects a response for another partner', () async {
    final service = _FakeAiService(
      _successResponse(partnerId: 'partner-other'),
    );
    final viewModel = AiCoachViewModel(aiService: service);
    viewModel.selectIntent(AiIntent.continueChat);

    await viewModel.getPersonalizedSuggestions(
      chatId: 'chat-1',
      matchId: 'match-1',
      expectedPartnerId: 'partner-1',
    );

    expect(viewModel.suggestions, isEmpty);
    expect(viewModel.errorMessage, contains('không khớp'));
  });

  test('ignores a stale response after the panel is closed', () async {
    final completer = Completer<AiChatResponse>();
    final service = _FakeAiService.handler((_) => completer.future);
    final viewModel = AiCoachViewModel(aiService: service);
    viewModel.selectIntent(AiIntent.continueChat);

    final request = viewModel.getPersonalizedSuggestions(
      chatId: 'chat-1',
      matchId: 'match-1',
      expectedPartnerId: 'partner-1',
    );
    viewModel.cancelPendingRequest();
    completer.complete(_successResponse());
    await request;

    expect(viewModel.isLoading, isFalse);
    expect(viewModel.suggestions, isEmpty);
  });
}
