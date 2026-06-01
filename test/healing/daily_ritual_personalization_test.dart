import 'package:bondy/screens/healing/daily_ritual_personalization.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveRoute', () {
    test('maps stabilize to stabilize quick actions route', () {
      expect(
        resolveRoute(PostCheckinAction.stabilize),
        stabilizeQuickActionsRoute,
      );
    });

    test('maps exercise to exercise detail route', () {
      expect(
        resolveRoute(PostCheckinAction.exercise),
        '/healing/exercise-detail',
      );
    });

    test('maps journal to chatbot', () {
      expect(resolveRoute(PostCheckinAction.journal), '/chatbot');
    });

    test('maps continuePlan to plan route', () {
      expect(resolveRoute(PostCheckinAction.continuePlan), '/healing/plan');
    });

    test('maps browseContent to content hub', () {
      expect(resolveRoute(PostCheckinAction.browseContent), '/content');
    });
  });

  group('buildDailyRitualModel.action mapping', () {
    test('high intensity (>=7) returns stabilize action', () {
      final model = buildDailyRitualModel(mood: 'ANXIOUS', intensity: 8);
      expect(model.action, PostCheckinAction.stabilize);
    });

    test('mid intensity (4-6) returns exercise action', () {
      final model = buildDailyRitualModel(mood: 'SAD', intensity: 5);
      expect(model.action, PostCheckinAction.exercise);
    });

    test('low intensity CALM mood returns continuePlan action', () {
      final model = buildDailyRitualModel(mood: 'CALM', intensity: 2);
      expect(model.action, PostCheckinAction.continuePlan);
    });

    test('low intensity OK mood returns continuePlan action', () {
      final model = buildDailyRitualModel(mood: 'OK', intensity: 1);
      expect(model.action, PostCheckinAction.continuePlan);
    });

    test('low intensity neutral mood returns journal action', () {
      final model = buildDailyRitualModel(mood: 'NEUTRAL', intensity: 2);
      expect(model.action, PostCheckinAction.journal);
    });
  });

  group('resolveActionForMood (route-stable)', () {
    test('changing ctaLabel does NOT break routing (enum-based)', () {
      // M10 regression: trước đây route match bằng ctaLabel string.
      // Bây giờ route được resolve qua enum action, không qua string.
      final action = resolveActionForMood(mood: 'ANXIOUS', intensity: 8);
      expect(action, PostCheckinAction.stabilize);
      // Đảm bảo route resolve không phụ thuộc text.
      expect(resolveRoute(action), stabilizeQuickActionsRoute);
    });
  });
}
