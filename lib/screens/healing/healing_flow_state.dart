enum HealingEntry { voluntary, triggered }

enum HealingPrimaryIntent { stabilize, reflect, rebuild }

enum HealingTopBlock { continueJourney, startPath }

enum HealingRecoveryAction { startReflection, doExercise }

enum HealingRoute { recoveryResult, healingHome }

class HealingFlowState {
  final bool isFirstTime;
  final bool hasInProgress;
  final bool hasTodayCheckin;
  final HealingEntry entry;
  final int? lastIntensity;

  const HealingFlowState({
    required this.isFirstTime,
    required this.hasInProgress,
    required this.hasTodayCheckin,
    required this.entry,
    this.lastIntensity,
  });

  factory HealingFlowState.firstTime() {
    return const HealingFlowState(
      isFirstTime: true,
      hasInProgress: false,
      hasTodayCheckin: false,
      entry: HealingEntry.voluntary,
    );
  }

  factory HealingFlowState.returningInProgress({int? intensity}) {
    return HealingFlowState(
      isFirstTime: false,
      hasInProgress: true,
      hasTodayCheckin: true,
      entry: HealingEntry.voluntary,
      lastIntensity: intensity,
    );
  }

  factory HealingFlowState.postTriggeredReturn({int? intensity}) {
    return HealingFlowState(
      isFirstTime: false,
      hasInProgress: false,
      hasTodayCheckin: true,
      entry: HealingEntry.triggered,
      lastIntensity: intensity,
    );
  }

  HealingTopBlock get topBlock => hasInProgress
      ? HealingTopBlock.continueJourney
      : HealingTopBlock.startPath;

  HealingPrimaryIntent get primaryIntent {
    if ((lastIntensity ?? 0) >= 7) {
      return HealingPrimaryIntent.stabilize;
    }
    if (hasInProgress) {
      return HealingPrimaryIntent.rebuild;
    }
    return HealingPrimaryIntent.reflect;
  }

  HealingRecoveryAction get recoveryPrimaryAction =>
      primaryIntent == HealingPrimaryIntent.stabilize
      ? HealingRecoveryAction.doExercise
      : HealingRecoveryAction.startReflection;

  HealingRoute get routeAfterCheckin => entry == HealingEntry.triggered
      ? HealingRoute.recoveryResult
      : HealingRoute.healingHome;

  bool get shouldPinReflection =>
      entry == HealingEntry.triggered && hasTodayCheckin;

  String get continueJourneyRoute => '/healing/plan';

  String get todayForYouRoute {
    return switch (primaryIntent) {
      HealingPrimaryIntent.stabilize => '/healing/stabilize-quick-actions',
      HealingPrimaryIntent.reflect => '/content',
      HealingPrimaryIntent.rebuild => '/healing/plan',
    };
  }

  String get reflectionRoute => '/healing/plan';
}
