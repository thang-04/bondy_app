import 'package:bondy/screens/chat/healing_chatbot_coach_screen.dart';
import 'package:bondy/services/ai_service.dart';
import 'package:bondy/services/api_client.dart';
import 'package:bondy/viewmodels/ai/ai_quota_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class _QuotaAiService extends AiService {
  _QuotaAiService() : super(ApiClient());

  @override
  Future<AiQuotaSummary> getQuota() async => AiQuotaSummary.fromJson({
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
  });
}

class _StreamingAiService extends AiService {
  AiStreamChatRequest? lastRequest;

  _StreamingAiService() : super(ApiClient());

  @override
  Stream<AiChatStreamEvent> streamChat(AiStreamChatRequest request) async* {
    lastRequest = request;
    yield AiChatStreamEvent.chunk('Mình đang lắng nghe bạn.');
    yield AiChatStreamEvent.metadata(
      AiChatStreamMetadata.fromJson({
        'mode': 'healing',
        'quota': {
          'mode': 'healing',
          'feature': 'daily_ai_healing',
          'label': 'AI chua lanh',
          'tier': 'FREE',
          'limit': 3,
          'used': 2,
          'remaining': 1,
          'resetsAt': '2026-06-13T17:00:00.000Z',
        },
      }),
    );
  }
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('healing chat shows quota and sends healing mode', (
    tester,
  ) async {
    final quotaViewModel = AiQuotaViewModel(aiService: _QuotaAiService());
    await quotaViewModel.loadQuota();
    final aiService = _StreamingAiService();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: quotaViewModel,
        child: MaterialApp(
          home: HealingChatbotCoachScreen(aiService: aiService),
        ),
      ),
    );

    expect(find.text('Còn 2/3 lượt'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('healing_chat_input')),
      'Hôm nay mình buồn',
    );
    await tester.tap(find.byKey(const Key('healing_chat_send')));
    await tester.pumpAndSettle();

    expect(aiService.lastRequest?.mode, AiChatMode.healing);
    expect(find.textContaining('Mình đang lắng nghe'), findsOneWidget);
    expect(find.text('Còn 1/3 lượt'), findsOneWidget);
  });
}
