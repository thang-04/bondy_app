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
}

// ──────────────────────────────────────────────────────────────────────────
// Home mode + "Hôm nay" focus resolvers
//
// Toàn bộ logic chọn mode (Discovery vs Journey) và quyết định "Thẻ Hôm nay"
// gói gọn ở đây — UI chỉ đọc kết quả, không tự suy luận. (Redesign §4.2, §5.1)
// ──────────────────────────────────────────────────────────────────────────

enum HealingHomeMode { discovery, journey }

enum HealingTodayFocusKind {
  /// Người mới: mời gọi bắt đầu nhẹ nhàng → mở onboarding sheet.
  onboarding,

  /// Quay lại (Discovery): một gợi ý theo tâm trạng → mở nội dung.
  exploreSuggestion,

  /// Đang theo lộ trình: tiếp tục bước kế tiếp của ngày hiện tại.
  continuePlan,

  /// Vào sau check-in cường độ cao: ổn định lại trước.
  recover,
}

/// Nội dung hiển thị cho "Thẻ Hôm nay" (1 hero + 1 CTA chính).
class HealingTodayFocus {
  final HealingTodayFocusKind kind;
  final String title;
  final String subtitle;
  final String ctaLabel;

  const HealingTodayFocus({
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.ctaLabel,
  });

  /// Hành động chính mở một nội dung (vs. mở sheet onboarding).
  bool get opensContent =>
      kind == HealingTodayFocusKind.exploreSuggestion ||
      kind == HealingTodayFocusKind.continuePlan ||
      kind == HealingTodayFocusKind.recover;
}

/// Quy tắc: có active plan **hoặc** vào theo trigger cảm xúc → Journey.
/// Còn lại → Discovery.
HealingHomeMode resolveHomeMode({
  required bool hasActivePlan,
  required HealingEntry entry,
}) {
  if (hasActivePlan || entry == HealingEntry.triggered) {
    return HealingHomeMode.journey;
  }
  return HealingHomeMode.discovery;
}

/// Quyết định nội dung "Thẻ Hôm nay" dựa trên mode + trạng thái.
/// [suggestionTitle]/[suggestionSummary] là gợi ý từ server (todayForYou) nếu có.
HealingTodayFocus resolveTodayFocus({
  required HealingHomeMode mode,
  required bool isFirstTime,
  required bool hasTodayCheckin,
  int? lastIntensity,
  String? planDayLabel,
  String? planItemTitle,
  String? suggestionTitle,
  String? suggestionSummary,
}) {
  final isHighIntensity = (lastIntensity ?? 0) >= 7;

  if (mode == HealingHomeMode.journey) {
    if (isHighIntensity) {
      return HealingTodayFocus(
        kind: HealingTodayFocusKind.recover,
        title: 'Cùng bình tâm lại',
        subtitle: planItemTitle?.trim().isNotEmpty == true
            ? planItemTitle!.trim()
            : 'Một bước nhẹ để ổn định trước khi đi tiếp.',
        ctaLabel: 'Bắt đầu',
      );
    }
    final title = planDayLabel?.trim().isNotEmpty == true
        ? planDayLabel!.trim()
        : 'Bước hôm nay';
    return HealingTodayFocus(
      kind: HealingTodayFocusKind.continuePlan,
      title: title,
      subtitle: planItemTitle?.trim().isNotEmpty == true
          ? planItemTitle!.trim()
          : 'Tiếp tục bước kế tiếp trong lộ trình của bạn.',
      ctaLabel: 'Tiếp tục',
    );
  }

  // Discovery mode
  if (isFirstTime) {
    return const HealingTodayFocus(
      kind: HealingTodayFocusKind.onboarding,
      title: 'Bắt đầu nhẹ nhàng',
      subtitle: 'Chọn một bước nhỏ để Bondy đồng hành cùng bạn hôm nay.',
      ctaLabel: 'Bắt đầu',
    );
  }

  return HealingTodayFocus(
    kind: HealingTodayFocusKind.exploreSuggestion,
    title: suggestionTitle?.trim().isNotEmpty == true
        ? suggestionTitle!.trim()
        : 'Gợi ý cho tâm trạng của bạn',
    subtitle: suggestionSummary?.trim().isNotEmpty == true
        ? suggestionSummary!.trim()
        : 'Một nội dung ngắn, nhẹ nhàng dành riêng cho hôm nay.',
    ctaLabel: 'Khám phá',
  );
}
