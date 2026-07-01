import 'package:bondy/screens/chat/ai_mode_intake_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('zodiac intake collects info before opening chat', (
    tester,
  ) async {
    Object? capturedArguments;

    await tester.pumpWidget(
      MaterialApp(
        initialRoute: '/intake',
        onGenerateRoute: (settings) {
          if (settings.name == '/intake') {
            return MaterialPageRoute<void>(
              settings: const RouteSettings(
                name: '/intake',
                arguments: {'mode': 'ai-tu-vi'},
              ),
              builder: (_) => const AiModeIntakeScreen(),
            );
          }
          if (settings.name == '/zodiac-ai') {
            capturedArguments = settings.arguments;
            return MaterialPageRoute<void>(
              builder: (_) => const Scaffold(body: Text('zodiac target')),
            );
          }
          return null;
        },
      ),
    );

    await tester.enterText(
      find.byKey(const Key('ai_intake_field_birthDate')),
      '1995-05-12',
    );
    await tester.enterText(
      find.byKey(const Key('ai_intake_field_partnerBirthInfo')),
      '1994',
    );
    await tester.enterText(
      find.byKey(const Key('ai_intake_field_question')),
      'Co hop nhau khong?',
    );
    await tester.ensureVisible(find.byKey(const Key('ai_intake_submit')));
    await tester.tap(find.byKey(const Key('ai_intake_submit')));
    await tester.pumpAndSettle();

    expect(find.text('zodiac target'), findsOneWidget);
    final args = capturedArguments as Map<String, dynamic>;
    expect(args['mode'], 'ai-tu-vi');
    expect(args['displayMessage'], 'Bắt đầu xem tử vi tình yêu');
    expect(args['initialMessage'], contains('Mode: ai-tu-vi'));
    expect(args['initialMessage'], contains('Question: Co hop nhau khong?'));
    expect(args['intakeSummary'], contains('Người kia: 1994'));
  });
}
