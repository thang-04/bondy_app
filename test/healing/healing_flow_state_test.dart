import 'package:bondy/screens/healing/healing_flow_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HealingFlowState.recoveryPrimaryAction', () {
    test('returns doExercise when intensity >= 7 (stabilize intent)', () {
      const state = HealingFlowState(
        isFirstTime: false,
        hasInProgress: false,
        hasTodayCheckin: true,
        entry: HealingEntry.voluntary,
        lastIntensity: 8,
      );
      expect(state.primaryIntent, HealingPrimaryIntent.stabilize);
      expect(state.recoveryPrimaryAction, HealingRecoveryAction.doExercise);
    });

    test('returns startReflection for low intensity', () {
      const state = HealingFlowState(
        isFirstTime: false,
        hasInProgress: false,
        hasTodayCheckin: true,
        entry: HealingEntry.voluntary,
        lastIntensity: 2,
      );
      expect(state.primaryIntent, HealingPrimaryIntent.reflect);
      expect(
        state.recoveryPrimaryAction,
        HealingRecoveryAction.startReflection,
      );
    });

    test('returns startReflection for rebuild intent (in-progress, low)', () {
      const state = HealingFlowState(
        isFirstTime: false,
        hasInProgress: true,
        hasTodayCheckin: true,
        entry: HealingEntry.voluntary,
        lastIntensity: 4,
      );
      expect(state.primaryIntent, HealingPrimaryIntent.rebuild);
      expect(
        state.recoveryPrimaryAction,
        HealingRecoveryAction.startReflection,
      );
    });
  });

  group('HealingFlowState factory constructors', () {
    test('returningInProgress accepts dynamic intensity', () {
      final state = HealingFlowState.returningInProgress(intensity: 6);
      expect(state.lastIntensity, 6);
      expect(state.hasInProgress, true);
    });

    test('returningInProgress with null intensity keeps null', () {
      final state = HealingFlowState.returningInProgress();
      expect(state.lastIntensity, isNull);
    });

    test('postTriggeredReturn accepts dynamic intensity', () {
      final state = HealingFlowState.postTriggeredReturn(intensity: 9);
      expect(state.lastIntensity, 9);
      expect(state.entry, HealingEntry.triggered);
    });
  });
}
