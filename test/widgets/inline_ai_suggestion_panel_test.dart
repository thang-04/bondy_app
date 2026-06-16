import 'dart:async';

import 'package:bondy/services/ai_service.dart';
import 'package:bondy/services/api_client.dart';
import 'package:bondy/viewmodels/ai/ai_coach_viewmodel.dart';
import 'package:bondy/widgets/inline_ai_suggestion_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

class _DelayedAiService extends AiService {
  final Completer<AiChatResponse> completer = Completer<AiChatResponse>();

  _DelayedAiService() : super(ApiClient());

  @override
  Future<AiChatResponse> chatCoach(AiChatRequest request) {
    return completer.future;
  }
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('shows personalized suggestions and returns the selected draft', (
    tester,
  ) async {
    final viewModel = AiCoachViewModel()
      ..quota = AiModeQuota.fromJson({
        'mode': 'coach',
        'feature': 'daily_ai_coach',
        'label': 'Goi y tro chuyen',
        'tier': 'FREE',
        'limit': 3,
        'used': 1,
        'remaining': 2,
        'resetsAt': '2026-06-13T17:00:00.000Z',
      })
      ..suggestions = [
        'Cafe this weekend?',
        'What would you do on a chill afternoon?',
      ];
    String? selectedSuggestion;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InlineAiSuggestionPanel(
            viewModel: viewModel,
            partnerName: 'Linh',
            onClose: () {},
            onRetry: () {},
            onGenerate: () {},
            onIntentSelected: (_) {},
            onSuggestionSelected: (value) => selectedSuggestion = value,
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('inline_ai_suggestion_panel')), findsOneWidget);
    expect(find.text('Cafe this weekend?'), findsOneWidget);

    await tester.tap(find.byKey(const Key('ai_suggestion_0')));

    expect(selectedSuggestion, 'Cafe this weekend?');
  });

  testWidgets('updates the loading message while the provider is slow', (
    tester,
  ) async {
    final service = _DelayedAiService();
    final viewModel = AiCoachViewModel(aiService: service)
      ..selectIntent(AiIntent.continueChat);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListenableBuilder(
            listenable: viewModel,
            builder: (context, _) => InlineAiSuggestionPanel(
              viewModel: viewModel,
              partnerName: 'Linh',
              onClose: () {},
              onRetry: () {},
              onGenerate: () {},
              onIntentSelected: (_) {},
              onSuggestionSelected: (_) {},
            ),
          ),
        ),
      ),
    );

    final request = viewModel.getPersonalizedSuggestions(
      chatId: 'chat-1',
      matchId: 'match-1',
      expectedPartnerId: 'partner-1',
    );
    await tester.pump();
    expect(find.byKey(const Key('ai_suggestion_loading')), findsOneWidget);

    await tester.pump(const Duration(seconds: 16));

    service.completer.complete(
      AiChatResponse.fromJson({
        'success': true,
        'data': {
          'flowVersion': 'coach-v2',
          'chatId': 'chat-1',
          'matchId': 'match-1',
          'partnerId': 'partner-1',
          'partnerName': 'Linh',
          'response': '1. Hello Linh',
          'mode': 'coach',
          'suggestions': ['Hello Linh'],
          'meta': {},
        },
      }),
    );
    await request;
    await tester.pump();

    expect(find.text('Hello Linh'), findsOneWidget);
  });

  testWidgets('requires selecting an intent before generating suggestions', (
    tester,
  ) async {
    final viewModel = AiCoachViewModel();
    var selectedIntentCount = 0;
    var generateCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListenableBuilder(
            listenable: viewModel,
            builder: (context, _) => InlineAiSuggestionPanel(
              viewModel: viewModel,
              partnerName: 'Linh',
              onClose: () {},
              onRetry: () {},
              onGenerate: () => generateCount++,
              onIntentSelected: (intent) {
                selectedIntentCount++;
                viewModel.selectIntent(intent);
              },
              onSuggestionSelected: (_) {},
            ),
          ),
        ),
      ),
    );

    final continueChip = tester.widget<ChoiceChip>(
      find.byKey(const Key('ai_intent_continue')),
    );
    expect(continueChip.selected, isFalse);

    final generateButton = find.byKey(const Key('generate_ai_suggestions'));
    expect(tester.widget<ElevatedButton>(generateButton).onPressed, isNull);

    await tester.tap(find.byKey(const Key('ai_intent_continue')));
    await tester.pump();

    expect(selectedIntentCount, 1);
    expect(generateCount, 0);
    expect(viewModel.selectedIntent, AiIntent.continueChat);
    expect(
      tester
          .widget<ChoiceChip>(find.byKey(const Key('ai_intent_continue')))
          .selected,
      isTrue,
    );
    expect(tester.widget<ElevatedButton>(generateButton).onPressed, isNotNull);

    await tester.tap(generateButton);
    expect(generateCount, 1);
  });
}
