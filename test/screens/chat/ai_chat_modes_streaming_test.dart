import 'package:bondy/screens/chat/bondy_ai_chat_screen.dart';
import 'package:bondy/screens/chat/emotional_checkin_ai_screen.dart';
import 'package:bondy/screens/chat/tarot_reading_screen.dart';
import 'package:bondy/screens/chat/zodiac_ai_chat_screen.dart';
import 'package:bondy/services/ai_service.dart';
import 'package:bondy/services/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

class _RecordingAiService extends AiService {
  final requests = <AiStreamChatRequest>[];

  _RecordingAiService() : super(ApiClient());

  @override
  Stream<AiChatStreamEvent> streamChat(AiStreamChatRequest request) async* {
    requests.add(request);
    yield AiChatStreamEvent.chunk('## Goi y\n\n1. **AI streamed response**');
    yield AiChatStreamEvent.metadata(
      AiChatStreamMetadata.fromJson({'mode': request.mode.apiValue}),
    );
  }
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('Bondy AI sends generic chat through default mode', (
    tester,
  ) async {
    final aiService = _RecordingAiService();

    await tester.pumpWidget(
      MaterialApp(home: BondyAIChatScreen(aiService: aiService)),
    );

    await tester.enterText(
      find.byKey(const Key('bondy_ai_chat_input')),
      'hello',
    );
    await tester.tap(find.byKey(const Key('bondy_ai_chat_send')));
    await tester.pumpAndSettle();

    expect(aiService.requests.single.mode, AiChatMode.defaultMode);
    expect(aiService.requests.single.messages.last.content, 'hello');
    expect(
      find.textContaining('AI streamed response', findRichText: true),
      findsOneWidget,
    );
    expect(find.textContaining('##', findRichText: true), findsNothing);
    expect(find.textContaining('**', findRichText: true), findsNothing);
  });

  testWidgets('Zodiac AI sends chat through ai-tu-vi mode', (tester) async {
    final aiService = _RecordingAiService();

    await tester.pumpWidget(
      MaterialApp(home: ZodiacAiChatScreen(aiService: aiService)),
    );

    await tester.enterText(
      find.byKey(const Key('zodiac_ai_chat_input')),
      'tu vi tinh yeu',
    );
    await tester.tap(find.byKey(const Key('zodiac_ai_chat_send')));
    await tester.pumpAndSettle();

    expect(aiService.requests.single.mode, AiChatMode.aiTuVi);
    expect(
      find.textContaining('AI streamed response', findRichText: true),
      findsOneWidget,
    );
    expect(find.textContaining('##', findRichText: true), findsNothing);
    expect(find.textContaining('**', findRichText: true), findsNothing);
  });

  testWidgets('Tarot AI sends follow-up chat through tarot mode', (
    tester,
  ) async {
    final aiService = _RecordingAiService();

    await tester.pumpWidget(
      MaterialApp(home: TarotReadingScreen(aiService: aiService)),
    );

    await tester.enterText(
      find.byKey(const Key('tarot_ai_chat_input')),
      'giai nghia them',
    );
    await tester.tap(find.byKey(const Key('tarot_ai_chat_send')));
    await tester.pumpAndSettle();

    expect(aiService.requests.single.mode, AiChatMode.tarot);
    expect(
      find.textContaining('AI streamed response', findRichText: true),
      findsOneWidget,
    );
    expect(find.textContaining('##', findRichText: true), findsNothing);
    expect(find.textContaining('**', findRichText: true), findsNothing);
  });

  testWidgets('Emotional check-in sends selected mood through healing mode', (
    tester,
  ) async {
    final aiService = _RecordingAiService();

    await tester.pumpWidget(
      MaterialApp(home: EmotionalCheckinAiScreen(aiService: aiService)),
    );

    await tester.tap(find.byKey(const Key('emotion_checkin_1')));
    await tester.enterText(
      find.byKey(const Key('emotion_checkin_text')),
      'can tam su',
    );
    await tester.tap(find.byKey(const Key('emotion_checkin_submit')));
    await tester.pumpAndSettle();

    expect(aiService.requests.single.mode, AiChatMode.healing);
    expect(
      aiService.requests.single.messages.last.content,
      contains('can tam su'),
    );
    expect(
      find.textContaining('AI streamed response', findRichText: true),
      findsOneWidget,
    );
    expect(find.textContaining('##', findRichText: true), findsNothing);
    expect(find.textContaining('**', findRichText: true), findsNothing);
  });
}
