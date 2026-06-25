import 'package:flutter/material.dart';

import '../../models/healing/healing_models.dart';
import '../../viewmodels/healing/healing_home_viewmodel.dart';
import '../../widgets/navigation/bondy_bottom_nav_bar.dart';
import 'healing_flow_state.dart';
import 'healing_navigation.dart';
import 'healing_shared_utils.dart';
import 'healing_stitch_style.dart';
import 'widgets/today_checkin_summary_card.dart';
import 'widgets/emotional_checkin_sheet.dart';
import 'widgets/inline_checkin_strip.dart';
import 'widgets/healing_onboarding_sheet.dart';

class HealingModeDashboardScreen extends StatefulWidget {
  final HealingFlowState? initialState;
  final HealingHomeViewModel? viewModel;
  final bool isActive;
  final bool showBottomNavigation;

  const HealingModeDashboardScreen({
    super.key,
    this.initialState,
    this.viewModel,
    this.isActive = true,
    this.showBottomNavigation = true,
  });

  @override
  State<HealingModeDashboardScreen> createState() =>
      _HealingModeDashboardScreenState();
}

class _HealingModeDashboardScreenState
    extends State<HealingModeDashboardScreen> {
  HealingHomeViewModel? _viewModel;
  bool _ownsViewModel = false;
  final Set<int> _expandedJourneyDays = <int>{};
  String? _expandedJourneyAssignmentId;
  int? _expandedJourneyCurrentDay;

  @override
  void initState() {
    super.initState();
    if (widget.initialState == null) {
      _viewModel = widget.viewModel ?? HealingHomeViewModel();
      _ownsViewModel = widget.viewModel == null;
      _viewModel!.loadHome(includeDisplayName: true);
    }
  }

  @override
  void dispose() {
    if (_ownsViewModel) {
      _viewModel?.dispose();
    }
    super.dispose();
  }

  // Redesign §4.1: tab Chữa lành KHÔNG bao giờ tự bật popup. Không còn
  // didChangeDependencies / didUpdateWidget để auto-mở sheet hay dialog.

  @override
  Widget build(BuildContext context) {
    if (widget.initialState != null) {
      return _buildScaffold(context, widget.initialState!, null);
    }

    final viewModel = _viewModel!;
    return AnimatedBuilder(
      animation: viewModel,
      builder: (context, _) {
        if (viewModel.isLoading && viewModel.home == null) {
          return _buildLoadingScaffold();
        }

        if (viewModel.errorMessage != null && viewModel.home == null) {
          return _buildErrorScaffold(viewModel);
        }

        final home = viewModel.home;
        final flow = home == null
            ? HealingFlowState.returningInProgress()
            : _flowFromHome(home);
        return _buildScaffold(context, flow, home, viewModel);
      },
    );
  }

  Widget _buildLoadingScaffold() {
    return const Scaffold(
      backgroundColor: HealingStitchColors.creamBackground,
      body: SafeArea(
        child: Column(
          children: [
            HealingTopBar(title: 'Chữa lành', showBack: false),
            Expanded(
              child: Center(
                child: CircularProgressIndicator(
                  color: HealingStitchColors.pink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScaffold(HealingHomeViewModel viewModel) {
    return Scaffold(
      backgroundColor: HealingStitchColors.creamBackground,
      body: SafeArea(
        child: Column(
          children: [
            const HealingTopBar(title: 'Chữa lành', showBack: false),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Không thể tải Healing lúc này.',
                        textAlign: TextAlign.center,
                        style: healingText(size: 16, weight: FontWeight.w900),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        viewModel.errorMessage ?? '',
                        textAlign: TextAlign.center,
                        style: healingText(
                          size: 12,
                          color: HealingStitchColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScaffold(
    BuildContext context,
    HealingFlowState flow,
    HealingHomeData? home, [
    HealingHomeViewModel? viewModel,
  ]) {
    final localMood = viewModel?.localTodayMood;
    final todayMood = home?.todayMood ?? localMood;
    final hasTodayCheckin =
        flow.hasTodayCheckin || viewModel?.hasLocalTodayCheckin == true;
    final todayItem =
        home?.todayForYou.article ??
        home?.todayForYou.exercise ??
        home?.todayForYou.course;
    final greetingName = _viewModel?.displayName.trim();
    final activePlan = home?.activePlanSummary;
    final recommendedPlan = home?.recommendedPlan;
    _syncExpandedJourneyDays(activePlan);
    final displayName = greetingName?.isNotEmpty == true
        ? greetingName!
        : 'bạn';
    final shellBottomPadding = widget.showBottomNavigation
        ? 0.0
        : BondyBottomNavBar.getReservedHeight(context);

    // Mode + "Thẻ Hôm nay" do resolver quyết định (Redesign §4.2, §5.1).
    final mode = resolveHomeMode(
      hasActivePlan: activePlan != null,
      entry: flow.entry,
    );
    final todayFocus = resolveTodayFocus(
      mode: mode,
      isFirstTime: flow.isFirstTime,
      hasTodayCheckin: hasTodayCheckin,
      lastIntensity: todayMood?.intensity,
      suggestionTitle: todayItem?.title,
      suggestionSummary: todayItem?.summary,
    );

    return Scaffold(
      backgroundColor: HealingStitchColors.creamBackground,
      bottomNavigationBar: widget.showBottomNavigation
          ? BondyBottomNavBar(
              currentIndex: 1,
              onTabSelected: (index) {
                final route = switch (index) {
                  0 => '/home',
                  1 => '/home/healing',
                  2 => '/home/matches',
                  3 => '/home/profile',
                  _ => '/home',
                };
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil(route, (_) => false);
              },
              onMatchTap: () => Navigator.of(context).pushNamed('/discover'),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            HealingTopBar(title: 'Chữa lành', showBack: false),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  10,
                  20,
                  28 + shellBottomPadding,
                ),
                children: [
                  Text(
                    'Chào ${healingGreeting()}, $displayName',
                    style: healingText(size: 29, weight: FontWeight.w900),
                  ),
                  const SizedBox(height: 18),

                  // ── Journey Mode: đang theo một lộ trình ──
                  if (mode == HealingHomeMode.journey && activePlan != null) ...[
                    _JourneyProgressHeader(
                      title: activePlan.title,
                      currentDay: activePlan.currentDay,
                      totalDays: activePlan.durationDays,
                      progressPercent: activePlan.progressPercent,
                    ),
                    const SizedBox(height: 12),
                    HealingGradientButton(
                      label: 'Khám phá Thư viện',
                      icon: Icons.auto_stories_outlined,
                      onTap: () => Navigator.of(context).pushNamed('/content'),
                    ),
                    const SizedBox(height: 16),
                    ...activePlan.days.map(
                      (day) => _JourneyDayTile(
                        day: day,
                        isCurrent: day.dayNumber == activePlan.currentDay,
                        isExpanded: _expandedJourneyDays.contains(
                          day.dayNumber,
                        ),
                        onToggleExpanded: () => _toggleJourneyDay(day),
                        onItemTap: (item) => _openPlanItem(item),
                      ),
                    ),
                    const SizedBox(height: 16),
                    HealingGradientButton(
                      label: 'Tiếp tục ngày hiện tại',
                      icon: Icons.play_arrow,
                      onTap: () => _continuePlanCurrentDay(activePlan),
                    ),
                    const SizedBox(height: 16),
                    _checkinBlock(hasTodayCheckin, todayMood),
                  ]
                  // ── Discovery Mode: khám phá tự do ──
                  else ...[
                    // ① Một trọng tâm "Hôm nay" + 1 CTA chính.
                    _TodayFocusHero(
                      focus: todayFocus,
                      onTap: () => _onTodayFocusTap(todayFocus, todayItem),
                    ),
                    const SizedBox(height: 16),
                    // ② Dải check-in inline (mời gọi, không ép buộc).
                    _checkinBlock(hasTodayCheckin, todayMood),
                    if (recommendedPlan != null) ...[
                      const SizedBox(height: 16),
                      _PlanDiscoveryCard(
                        plan: recommendedPlan,
                        onTap: () async {
                          await Navigator.of(context).pushNamed(
                            healingPlanRoute,
                            arguments: const {'preview': true},
                          );
                          viewModel?.loadHome(includeDisplayName: false);
                        },
                      ),
                    ],
                    const SizedBox(height: 22),
                    // ③ 2 lối tắt phụ: Thư viện · Tâm sự với Bondy.
                    _HomeShortcuts(
                      onLibrary: () =>
                          Navigator.of(context).pushNamed('/content'),
                      onChat: () => Navigator.of(context).pushNamed('/chatbot'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  HealingFlowState _flowFromHome(HealingHomeData home) {
    return HealingFlowState(
      isFirstTime: home.flowState.isFirstTime,
      hasInProgress: home.flowState.hasInProgress,
      hasTodayCheckin:
          home.flowState.hasTodayCheckin ||
          _viewModel?.hasLocalTodayCheckin == true,
      entry: HealingEntry.voluntary,
      lastIntensity: (home.todayMood ?? _viewModel?.localTodayMood)?.intensity,
    );
  }

  void _syncExpandedJourneyDays(HealingPlanTimeline? activePlan) {
    if (activePlan == null) {
      _expandedJourneyAssignmentId = null;
      _expandedJourneyCurrentDay = null;
      _expandedJourneyDays.clear();
      return;
    }

    if (_expandedJourneyAssignmentId == activePlan.assignmentId &&
        _expandedJourneyCurrentDay == activePlan.currentDay) {
      return;
    }

    _expandedJourneyAssignmentId = activePlan.assignmentId;
    _expandedJourneyCurrentDay = activePlan.currentDay;
    _expandedJourneyDays
      ..clear()
      ..add(activePlan.currentDay);
  }

  void _toggleJourneyDay(HealingPlanDayTimeline day) {
    final canToggle =
        (day.isUnlocked || day.isCompleted) && day.items.isNotEmpty;
    if (!canToggle) return;

    setState(() {
      if (!_expandedJourneyDays.remove(day.dayNumber)) {
        _expandedJourneyDays.add(day.dayNumber);
      }
    });
  }

  /// Dải check-in: đã check-in → tóm tắt; chưa → dải emoji inline mời gọi.
  Widget _checkinBlock(bool hasTodayCheckin, HealingLogSnapshot? todayMood) {
    if (hasTodayCheckin) {
      return TodayCheckinSummaryCard(
        todayMood: todayMood,
        onViewResult: () => Navigator.of(context).pushNamed(
          '/healing/checkin-result',
          arguments: _viewModel?.lastCheckin,
        ),
      );
    }
    return InlineCheckinStrip(
      onPick: (mood) => _openQuickCheckin(initialMood: mood),
    );
  }

  void _onTodayFocusTap(
    HealingTodayFocus focus,
    HealingContentPreview? todayItem,
  ) {
    if (focus.kind == HealingTodayFocusKind.onboarding) {
      _openOnboarding();
      return;
    }
    _openContentPreview(todayItem, '/content');
  }

  void _openOnboarding() {
    HealingOnboardingSheet.show(
      context,
      onExercise: () => Navigator.of(context).pushNamed(
        healingExerciseDetailRoute,
        arguments: 'exercise-self-worth-checklist',
      ),
      onReading: () => Navigator.of(context).pushNamed(
        healingArticleDetailRoute,
        arguments: 'article-ghosting-self-worth',
      ),
      onPlan: () async {
        await Navigator.of(
          context,
        ).pushNamed(healingPlanRoute, arguments: const {'preview': true});
        _viewModel?.loadHome(includeDisplayName: false);
      },
    );
  }

  void _openContentPreview(HealingContentPreview? item, String fallbackRoute) {
    if (item == null || item.id.isEmpty) {
      Navigator.of(context).pushNamed(fallbackRoute);
      return;
    }

    final route = switch (item.type) {
      'ARTICLE' => '/healing/article-detail',
      'EXERCISE' => '/healing/exercise-detail',
      'COURSE' => '/healing/course-detail',
      _ => fallbackRoute,
    };
    Navigator.of(context).pushNamed(route, arguments: item.id);
  }

  Future<void> _openQuickCheckin({String? initialMood}) async {
    final viewModel = _viewModel;
    if (viewModel == null) return;

    final submitted = await EmotionalCheckinSheet.show(
      context,
      initialMood: initialMood,
      onSubmit: (mood, intensity, note) async {
        final result = await viewModel.submitCheckin(
          mood: mood,
          intensity: intensity,
          note: note,
        );
        return result != null;
      },
    );

    if (submitted && mounted) {
      Navigator.of(
        context,
      ).pushNamed('/healing/checkin-result', arguments: viewModel.lastCheckin);
    }
  }

  Future<void> _openPlanItem(HealingPlanTimelineItem item) async {
    final itemType = item.type.toUpperCase();
    Object? completed;
    if (itemType == 'RITUAL') {
      // Gộp về màn Đọc/Audio chuẩn (Redesign §5.6).
      completed = await openRitualContent(
        context,
        item.contentId,
        planMode: true,
      );
    } else {
      final route = switch (itemType) {
        'ARTICLE' => '/healing/article-detail',
        'EXERCISE' => '/healing/exercise-detail',
        'AUDIO' => '/healing/audio-player',
        _ => '/healing/article-detail',
      };
      final arguments = switch (itemType) {
        'AUDIO' => {'audioId': item.contentId, 'planMode': true},
        _ => item.contentId,
      };
      completed = await Navigator.of(context).pushNamed(route, arguments: arguments);
    }
    if (completed == true) {
      await _viewModel?.completePlanItem(item.contentId, itemType);
    }
  }

  Future<void> _continuePlanCurrentDay(HealingPlanTimeline plan) async {
    HealingPlanDayTimeline? currentDay;
    for (final day in plan.days) {
      if (day.dayNumber == plan.currentDay) {
        currentDay = day;
        break;
      }
    }
    if (currentDay == null) {
      await Navigator.of(context).pushNamed(healingPlanRoute);
      _viewModel?.loadHome(includeDisplayName: false);
      return;
    }
    for (final item in currentDay.items) {
      if (!item.isCompleted) {
        await _openPlanItem(item);
        return;
      }
    }
    // All items done → open plan screen
    await Navigator.of(context).pushNamed(healingPlanRoute);
    _viewModel?.loadHome(includeDisplayName: false);
  }
}

// ──────────────────────────────────────────────────────
// Journey Mode Widgets
// ──────────────────────────────────────────────────────

class _JourneyProgressHeader extends StatelessWidget {
  final String title;
  final int currentDay;
  final int totalDays;
  final int progressPercent;

  const _JourneyProgressHeader({
    required this.title,
    required this.currentDay,
    required this.totalDays,
    required this.progressPercent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            HealingStitchColors.pink.withValues(alpha: 0.08),
            HealingStitchColors.purple.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: HealingStitchColors.pink.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: HealingStitchColors.pink.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.route_outlined,
                  color: HealingStitchColors.pink,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: healingText(size: 16, weight: FontWeight.w900),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Ngày $currentDay/$totalDays • $progressPercent% hoàn thành',
                      style: healingText(
                        size: 12,
                        color: HealingStitchColors.textSoft,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progressPercent / 100.0,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.7),
              valueColor: const AlwaysStoppedAnimation<Color>(
                HealingStitchColors.pink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _JourneyDayTile extends StatelessWidget {
  final HealingPlanDayTimeline day;
  final bool isCurrent;
  final bool isExpanded;
  final VoidCallback onToggleExpanded;
  final ValueChanged<HealingPlanTimelineItem> onItemTap;

  const _JourneyDayTile({
    required this.day,
    required this.isCurrent,
    required this.isExpanded,
    required this.onToggleExpanded,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    final canOpenTasks = day.isUnlocked || day.isCompleted;
    final canToggle = canOpenTasks && day.items.isNotEmpty;
    final isLocked = !canOpenTasks;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: isCurrent
              ? Colors.white
              : isLocked
              ? const Color(0xFFF9F8F6)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCurrent
                ? HealingStitchColors.pink.withValues(alpha: 0.3)
                : day.isCompleted
                ? const Color(0xFF16A34A).withValues(alpha: 0.25)
                : const Color(0xFFF2F0ED),
            width: isCurrent ? 1.5 : 1,
          ),
          boxShadow: isCurrent ? [healingSoftShadow(0.06)] : null,
        ),
        child: Column(
          children: [
            // Day header
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: canToggle ? onToggleExpanded : null,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                child: Row(
                  children: [
                    _dayStatusIcon(),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ngày ${day.dayNumber}',
                            style: healingText(
                              size: 11,
                              weight: FontWeight.w800,
                              color: isCurrent
                                  ? HealingStitchColors.pink
                                  : HealingStitchColors.textMuted,
                            ),
                          ),
                          Text(
                            day.title.isNotEmpty
                                ? day.title
                                : 'Bài tập ngày ${day.dayNumber}',
                            style: healingText(
                              size: 14,
                              weight: FontWeight.w900,
                              color: isLocked
                                  ? HealingStitchColors.textMuted
                                  : HealingStitchColors.textMain,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isCurrent)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: HealingStitchColors.pink.withValues(
                            alpha: 0.1,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Hôm nay',
                          style: healingText(
                            size: 11,
                            weight: FontWeight.w800,
                            color: HealingStitchColors.pink,
                          ),
                        ),
                      ),
                    if (isLocked)
                      const Icon(
                        Icons.lock_outline,
                        size: 16,
                        color: HealingStitchColors.textMuted,
                      ),
                    if (canToggle)
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        size: 20,
                        color: HealingStitchColors.textMuted,
                      ),
                  ],
                ),
              ),
            ),
            // Expanded items for every day already available on the timeline.
            if (canOpenTasks && isExpanded && day.items.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Divider(height: 1, indent: 14, endIndent: 14),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                child: Column(
                  children: day.items.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () => onItemTap(item),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: item.isCompleted
                                ? const Color(0xFFF0FDF4)
                                : HealingStitchColors.creamBackground,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: item.isCompleted
                                  ? const Color(
                                      0xFF16A34A,
                                    ).withValues(alpha: 0.2)
                                  : const Color(0xFFF2F0ED),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                item.isCompleted
                                    ? Icons.check_circle
                                    : Icons.circle_outlined,
                                size: 20,
                                color: item.isCompleted
                                    ? const Color(0xFF16A34A)
                                    : HealingStitchColors.textMuted,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _itemLabel(item),
                                  style: healingText(
                                    size: 13,
                                    weight: FontWeight.w700,
                                    color: item.isCompleted
                                        ? const Color(0xFF16A34A)
                                        : HealingStitchColors.textMain,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 14,
                                color: item.isCompleted
                                    ? const Color(
                                        0xFF16A34A,
                                      ).withValues(alpha: 0.5)
                                    : HealingStitchColors.textMuted,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ] else
              const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }

  Widget _dayStatusIcon() {
    if (day.isCompleted) {
      return Container(
        width: 28,
        height: 28,
        decoration: const BoxDecoration(
          color: Color(0xFF16A34A),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check, size: 16, color: Colors.white),
      );
    }
    if (isCurrent) {
      return Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: HealingStitchColors.pink,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: HealingStitchColors.pink.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(Icons.play_arrow, size: 16, color: Colors.white),
      );
    }
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFE5E7EB), width: 2),
      ),
      child: Center(
        child: Text(
          '${day.dayNumber}',
          style: healingText(
            size: 11,
            weight: FontWeight.w800,
            color: HealingStitchColors.textMuted,
          ),
        ),
      ),
    );
  }

  String _itemLabel(HealingPlanTimelineItem item) {
    return switch (item.type.toUpperCase()) {
      'ARTICLE' => 'Bài đọc',
      'EXERCISE' => 'Bài tập',
      'AUDIO' => 'Audio',
      'RITUAL' => 'Nghi thức',
      'REFLECTION' => 'Suy ngẫm',
      _ => item.type,
    };
  }
}

class _PlanDiscoveryCard extends StatelessWidget {
  final HealingPlanPreview plan;
  final VoidCallback onTap;

  const _PlanDiscoveryCard({required this.plan, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFF2F0ED)),
          boxShadow: [healingSoftShadow(0.04)],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: HealingStitchColors.paleCoral,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.route_outlined,
                color: HealingStitchColors.pink,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Khám phá lộ trình phù hợp',
                    style: healingText(size: 14, weight: FontWeight.w900),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    plan.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: healingText(
                      size: 12,
                      color: HealingStitchColors.textSoft,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: HealingStitchColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────
// Discovery Mode Widgets (Redesign §5.1)
// ──────────────────────────────────────────────────────

/// Thẻ "Hôm nay" — 1 hero duy nhất + 1 CTA chính. Nội dung do
/// resolveTodayFocus quyết định, UI chỉ hiển thị.
class _TodayFocusHero extends StatelessWidget {
  final HealingTodayFocus focus;
  final VoidCallback onTap;

  const _TodayFocusHero({required this.focus, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('today-focus-hero'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            HealingStitchColors.coral.withValues(alpha: 0.10),
            HealingStitchColors.purple.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: HealingStitchColors.coral.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hôm nay',
            style: healingText(
              size: 11,
              weight: FontWeight.w900,
              color: HealingStitchColors.pink,
            ).copyWith(letterSpacing: 0.8),
          ),
          const SizedBox(height: 8),
          Text(
            focus.title,
            style: healingText(size: 19, weight: FontWeight.w900, height: 1.25),
          ),
          const SizedBox(height: 6),
          Text(
            focus.subtitle,
            style: healingText(
              size: 13,
              color: HealingStitchColors.textSoft,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          HealingGradientButton(
            label: focus.ctaLabel,
            icon: focus.opensContent
                ? Icons.play_arrow_rounded
                : Icons.spa_outlined,
            onTap: onTap,
          ),
        ],
      ),
    );
  }
}

/// 2 lối tắt phụ: Thư viện · Tâm sự với Bondy.
class _HomeShortcuts extends StatelessWidget {
  final VoidCallback onLibrary;
  final VoidCallback onChat;

  const _HomeShortcuts({required this.onLibrary, required this.onChat});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ShortcutTile(
            icon: Icons.auto_stories_outlined,
            label: 'Thư viện',
            onTap: onLibrary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ShortcutTile(
            icon: Icons.forum_outlined,
            label: 'Tâm sự với Bondy',
            onTap: onChat,
          ),
        ),
      ],
    );
  }
}

class _ShortcutTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ShortcutTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF2F0ED)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: HealingStitchColors.pink),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: healingText(size: 13, weight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
