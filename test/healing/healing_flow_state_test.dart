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

  group('resolveHomeMode', () {
    test('active plan → journey', () {
      expect(
        resolveHomeMode(hasActivePlan: true, entry: HealingEntry.voluntary),
        HealingHomeMode.journey,
      );
    });

    test('triggered entry → journey even without a plan', () {
      expect(
        resolveHomeMode(hasActivePlan: false, entry: HealingEntry.triggered),
        HealingHomeMode.journey,
      );
    });

    test('voluntary entry without a plan → discovery', () {
      expect(
        resolveHomeMode(hasActivePlan: false, entry: HealingEntry.voluntary),
        HealingHomeMode.discovery,
      );
    });
  });

  group('resolveTodayFocus', () {
    test('first-time discovery → onboarding invitation', () {
      final focus = resolveTodayFocus(
        mode: HealingHomeMode.discovery,
        isFirstTime: true,
        hasTodayCheckin: false,
      );
      expect(focus.kind, HealingTodayFocusKind.onboarding);
      expect(focus.opensContent, isFalse);
    });

    test('returning discovery → explore suggestion with server title', () {
      final focus = resolveTodayFocus(
        mode: HealingHomeMode.discovery,
        isFirstTime: false,
        hasTodayCheckin: true,
        suggestionTitle: 'Thở 4-7-8',
        suggestionSummary: '3 phút làm dịu',
      );
      expect(focus.kind, HealingTodayFocusKind.exploreSuggestion);
      expect(focus.title, 'Thở 4-7-8');
      expect(focus.opensContent, isTrue);
    });

    test('journey + high intensity → recover focus', () {
      final focus = resolveTodayFocus(
        mode: HealingHomeMode.journey,
        isFirstTime: false,
        hasTodayCheckin: true,
        lastIntensity: 8,
      );
      expect(focus.kind, HealingTodayFocusKind.recover);
      expect(focus.title, 'Cùng bình tâm lại');
    });

    test('journey + low intensity → continue plan with day label', () {
      final focus = resolveTodayFocus(
        mode: HealingHomeMode.journey,
        isFirstTime: false,
        hasTodayCheckin: true,
        lastIntensity: 3,
        planDayLabel: 'Ngày 2',
        planItemTitle: 'Gọi tên cảm xúc',
      );
      expect(focus.kind, HealingTodayFocusKind.continuePlan);
      expect(focus.title, 'Ngày 2');
      expect(focus.subtitle, 'Gọi tên cảm xúc');
      expect(focus.ctaLabel, 'Tiếp tục');
    });
  });
}
