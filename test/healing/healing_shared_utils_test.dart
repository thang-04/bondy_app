import 'package:bondy/screens/healing/healing_shared_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('healingGreeting', () {
    test('returns buổi sáng before noon', () {
      expect(healingGreeting(DateTime(2026, 1, 1, 9, 0)), 'buổi sáng');
      expect(healingGreeting(DateTime(2026, 1, 1, 0, 0)), 'buổi sáng');
      expect(healingGreeting(DateTime(2026, 1, 1, 11, 59)), 'buổi sáng');
    });

    test('returns buổi chiều between noon and 6pm', () {
      expect(healingGreeting(DateTime(2026, 1, 1, 12, 0)), 'buổi chiều');
      expect(healingGreeting(DateTime(2026, 1, 1, 15, 30)), 'buổi chiều');
      expect(healingGreeting(DateTime(2026, 1, 1, 17, 59)), 'buổi chiều');
    });

    test('returns buổi tối after 6pm', () {
      expect(healingGreeting(DateTime(2026, 1, 1, 18, 0)), 'buổi tối');
      expect(healingGreeting(DateTime(2026, 1, 1, 23, 59)), 'buổi tối');
    });
  });

  group('readinessFromIntensity', () {
    test('high intensity → NOT_READY', () {
      expect(readinessFromIntensity(7), 'NOT_READY');
      expect(readinessFromIntensity(10), 'NOT_READY');
    });

    test('mid intensity → EXPLORING', () {
      expect(readinessFromIntensity(4), 'EXPLORING');
      expect(readinessFromIntensity(6), 'EXPLORING');
    });

    test('low intensity → READY', () {
      expect(readinessFromIntensity(0), 'READY');
      expect(readinessFromIntensity(3), 'READY');
    });
  });

  group('needsFromMood', () {
    test('maps ANXIOUS / STRESSED → CALM_DOWN', () {
      expect(needsFromMood('ANXIOUS'), ['CALM_DOWN']);
      expect(needsFromMood('STRESSED'), ['CALM_DOWN']);
      expect(needsFromMood('anxious'), ['CALM_DOWN']);
    });

    test('maps SAD → SELF_COMPASSION', () {
      expect(needsFromMood('SAD'), ['SELF_COMPASSION']);
    });

    test('maps ANGRY → COOL_OFF', () {
      expect(needsFromMood('ANGRY'), ['COOL_OFF']);
    });

    test('other moods → REFLECTION fallback', () {
      expect(needsFromMood('CALM'), ['REFLECTION']);
      expect(needsFromMood('UNKNOWN'), ['REFLECTION']);
    });
  });
}
