import 'package:bondy/core/ai_mode_intake.dart';
import 'package:bondy/services/ai_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('default mode does not require intake', () {
    expect(AiModeIntakeConfig.requiresIntake(AiChatMode.defaultMode), isFalse);
    expect(AiModeIntakeConfig.requiresIntake(AiChatMode.aiTuVi), isTrue);
  });

  test('zodiac intake builds structured prompt and readable summary', () {
    final draft = AiModeIntakeDraft(
      mode: AiChatMode.aiTuVi,
      values: const {
        'intent': 'compatibility',
        'birthDate': '1995-05-12',
        'birthTime': '08:30',
        'relationshipStatus': 'Dang tim hieu',
        'partnerBirthInfo': '1994',
        'question': 'Co hop nhau khong?',
      },
    );

    expect(draft.destinationRoute, '/zodiac-ai');
    expect(draft.displayMessage, 'Bắt đầu xem tử vi tình yêu');
    expect(draft.buildInitialMessage(), contains('Mode: ai-tu-vi'));
    expect(draft.buildInitialMessage(), contains('Intent: compatibility'));
    expect(
      draft.buildInitialMessage(),
      contains('User birth date: 1995-05-12'),
    );
    expect(draft.buildInitialMessage(), contains('Partner birth info: 1994'));
    expect(
      draft.buildInitialMessage(),
      contains('Question: Co hop nhau khong?'),
    );
    expect(
      draft.summaryLines,
      containsAll([
        'Chủ đề: Độ hợp nhau',
        'Ngày sinh: 1995-05-12',
        'Giờ sinh: 08:30',
        'Người kia: 1994',
      ]),
    );
  });

  test('each intake mode routes to the matching AI flow', () {
    expect(
      AiModeIntakeDraft(
        mode: AiChatMode.tarot,
        values: const {},
      ).destinationRoute,
      '/tarot-reading',
    );
    expect(
      AiModeIntakeDraft(
        mode: AiChatMode.healing,
        values: const {},
      ).destinationRoute,
      '/chatbot',
    );
    expect(
      AiModeIntakeDraft(
        mode: AiChatMode.coach,
        values: const {},
      ).destinationRoute,
      '/bondy-ai',
    );
    expect(
      AiModeIntakeDraft(
        mode: AiChatMode.plan,
        values: const {},
      ).destinationRoute,
      '/bondy-ai',
    );
  });
}
