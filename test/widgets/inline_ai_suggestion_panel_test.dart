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
      ..suggestions = [
        'Cuối tuần này bạn có quán cafe nào muốn thử không?',
        'Nếu chọn một chiều thật chill, bạn sẽ làm gì?',
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
            onIntentSelected: (_) {},
            onSuggestionSelected: (value) => selectedSuggestion = value,
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('inline_ai_suggestion_panel')), findsOneWidget);
    expect(find.text('AI gợi ý cho Linh'), findsOneWidget);
    expect(
      find.text('Cuối tuần này bạn có quán cafe nào muốn thử không?'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('ai_suggestion_0')));

    expect(
      selectedSuggestion,
      'Cuối tuần này bạn có quán cafe nào muốn thử không?',
    );
  });

  testWidgets('updates the loading message while the provider is slow', (
    tester,
  ) async {
    final service = _DelayedAiService();
    final viewModel = AiCoachViewModel(aiService: service);

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
    expect(find.text('Đang đọc cuộc trò chuyện...'), findsOneWidget);

    await tester.pump(const Duration(seconds: 16));
    expect(find.text('Đang cá nhân hóa gợi ý...'), findsOneWidget);

    service.completer.complete(
      AiChatResponse.fromJson({
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
      }),
    );
    await request;
    await tester.pump();

    expect(find.text('Chào Linh'), findsOneWidget);
  });
}
