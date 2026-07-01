import 'package:bondy/core/ai_mode_catalog.dart';
import 'package:bondy/services/ai_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('catalog exposes every backend AI mode used by the app', () {
    final modes = AiModeCatalog.modes.map((mode) => mode.mode).toList();

    expect(modes, [
      AiChatMode.defaultMode,
      AiChatMode.healing,
      AiChatMode.coach,
      AiChatMode.plan,
      AiChatMode.aiTuVi,
      AiChatMode.tarot,
    ]);
  });

  test(
    'catalog lists skill-backed mode descriptors without sending skills directly',
    () {
      final tuVi = AiModeCatalog.byMode(AiChatMode.aiTuVi);
      final tarot = AiModeCatalog.byMode(AiChatMode.tarot);

      expect(
        tuVi.skills.map((skill) => skill.key),
        containsAll(['cung-hoang-dao', 'tuong-hop', 'xem-ngay', 'la-so']),
      );
      expect(tarot.skills.single.key, 'tarot');
      expect(tarot.routeName, '/ai-mode-intake');
      expect(tarot.routeArguments, {'mode': 'tarot'});
      expect(
        AiModeCatalog.byMode(AiChatMode.defaultMode).routeName,
        '/bondy-ai',
      );
    },
  );
}
