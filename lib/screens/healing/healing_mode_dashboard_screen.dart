import 'package:flutter/material.dart';

import '../../models/healing/healing_models.dart';
import '../../viewmodels/healing/healing_home_viewmodel.dart';
import '../../widgets/navigation/bondy_bottom_nav_bar.dart';
import 'first_time_entry_bottom_sheet.dart';
import 'daily_ritual_personalization.dart';
import 'healing_flow_state.dart';
import 'healing_navigation.dart';
import 'healing_shared_utils.dart';
import 'post_checkin_card_config.dart';
import 'healing_stitch_style.dart';
import 'widgets/today_checkin_summary_card.dart';
import 'widgets/emotional_checkin_dialog.dart';
import '../../services/analytics_service.dart';

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
  bool _didShowFirstTimeSheet = false;
  bool _didAutoOpenQuickCheckin = false;
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _showFirstTimeSheetIfNeeded();
  }

  @override
  void didUpdateWidget(HealingModeDashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _showFirstTimeSheetIfNeeded();
      if (_viewModel?.home != null) {
        _autoOpenQuickCheckinIfNeeded(
          _flowFromHome(_viewModel!.home!),
          _viewModel!.home!,
        );
      }
    }
  }

  void _showFirstTimeSheetIfNeeded() {
    if (!widget.isActive) return;
    if (widget.initialState == null) return;
    if (_didShowFirstTimeSheet) return;
    final flow = widget.initialState!;
    if (!flow.isFirstTime) return;
    _didShowFirstTimeSheet = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showModalBottomSheet<void>(
        context: context,
        builder: (sheetContext) {
          return FirstTimeEntryBottomSheet(
            onCheckin: () {
              Navigator.of(sheetContext).pop();
              _openQuickCheckin(flow);
            },
            onReflection: () {
              Navigator.of(sheetContext).pop();
              Navigator.of(context).pushNamed(flow.reflectionRoute);
            },
            onLater: () => Navigator.of(sheetContext).pop(),
          );
        },
      );
    });
  }

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
        _autoOpenQuickCheckinIfNeeded(flow, home);
        return _buildScaffold(context, flow, home, viewModel);
      },
    );
  }

  void _autoOpenQuickCheckinIfNeeded(
    HealingFlowState flow,
    HealingHomeData? home,
  ) {
    if (!widget.isActive) return;
    if (widget.initialState != null) return;
    if (home == null || _didAutoOpenQuickCheckin) return;
    if (flow.hasTodayCheckin || _viewModel?.hasLocalTodayCheckin == true) {
      return;
    }

    _didAutoOpenQuickCheckin = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _openQuickCheckin(flow);
    });
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
    final reflectionPrompt =
        home?.todayForYou.reflectionPrompt ?? 'Điều mình đang tự trách là gì?';
    final postCheckinConfig = hasTodayCheckin && todayMood != null
        ? PostCheckinCardConfig.fromMood(
            mood: todayMood.mood,
            intensity: todayMood.intensity,
          )
        : null;
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

                  // ── Journey Mode: có active plan ──
                  if (activePlan != null) ...[
                    _JourneyProgressHeader(
                      title: activePlan.title,
                      currentDay: activePlan.currentDay,
                      totalDays: activePlan.durationDays,
                      progressPercent: activePlan.progressPercent,
                    ),
                    const SizedBox(height: 12),
                    HealingGradientButton(
                      label: 'Khám phá Content Hub',
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
                  ]
                  // ── Discovery Mode: chưa có plan ──
                  else ...[
                    if (flow.topBlock == HealingTopBlock.continueJourney)
                      _ContinueJourneyCard(
                        title: 'Tiếp tục hành trình',
                        subtitle: 'Bước hôm trước đang chờ bạn hoàn thành.',
                        onTap: () => _openContinueJourney(home, flow),
                      )
                    else
                      _StartHealingPathCard(
                        onCheckin: () => _openQuickCheckin(flow),
                        onReflection: () async {
                          await Navigator.of(context).pushNamed(
                            '/healing/plan',
                            arguments: const {'preview': true},
                          );
                          viewModel?.loadHome(includeDisplayName: false);
                        },
                        showCheckinAction: !hasTodayCheckin,
                      ),
                    const SizedBox(height: 20),
                    if (recommendedPlan != null) ...[
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
                      const SizedBox(height: 20),
                    ],
                    _SectionHeader(
                      title: 'Hôm nay dành cho bạn',
                      action: 'Xem tất cả',
                      onTap: () => Navigator.of(context).pushNamed('/content'),
                    ),
                    const SizedBox(height: 12),
                    _TodayForYouCard(
                      intent: flow.primaryIntent,
                      title: todayItem?.title,
                      subtitle: todayItem?.summary,
                      onTap: () =>
                          _openContentPreview(todayItem, flow.todayForYouRoute),
                    ),
                  ],

                  // ── Common widgets (both modes) ──
                  const SizedBox(height: 16),
                  if (hasTodayCheckin)
                    TodayCheckinSummaryCard(
                      todayMood: todayMood,
                      onViewResult: () => Navigator.of(context).pushNamed(
                        '/healing/checkin-result',
                        arguments: _viewModel?.lastCheckin,
                      ),
                    )
                  else if (flow.topBlock == HealingTopBlock.continueJourney)
                    _QuickCheckinCard(onTap: () => _openQuickCheckin(flow)),
                  if (postCheckinConfig != null && todayMood != null) ...[
                    const SizedBox(height: 12),
                    _PostCheckinPrimaryActionCard(
                      topMessage: postCheckinConfig.topMessage,
                      ctaLabel: postCheckinConfig.primaryCtaLabel,
                      onTap: () => _openPrimaryMoodAction(todayMood),
                    ),
                  ],
                  const SizedBox(height: 12),
                  _ReflectionPromptCard(
                    prompt: reflectionPrompt,
                    onTap: () => Navigator.of(context).pushNamed('/chatbot'),
                  ),
                  if (activePlan != null) ...[
                    const SizedBox(height: 22),
                    _StageProgressCard(plan: activePlan),
                  ],
                  ..._buildRitualSection(context, home),
                  const SizedBox(height: 24),
                  _CoachCard(
                    onTap: () => Navigator.of(context).pushNamed('/chatbot'),
                  ),
                  const SizedBox(height: 24),
                  _SectionHeader(
                    title: 'Kết nối nhẹ nhàng',
                    action: '',
                    onTap: null,
                  ),
                  const SizedBox(height: 12),
                  _ConnectGentlyCard(
                    onTap: () => Navigator.of(context).pushNamed('/discover'),
                  ),
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

  void _openContinueJourney(HealingHomeData? home, HealingFlowState flow) {
    final courseId = home?.continueJourney?.courseId;
    if (courseId == null || courseId.isEmpty) {
      Navigator.of(context).pushNamed('/healing/plan');
      return;
    }
    Navigator.of(
      context,
    ).pushNamed('/healing/course-detail', arguments: courseId);
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

  void _openQuickCheckin(HealingFlowState flow) async {
    final viewModel = _viewModel;
    if (viewModel == null) return;

    bool submitted = false;
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (dialogContext) {
        return EmotionalCheckinDialog(
          onSubmit: (mood, intensity, note) async {
            final result = await viewModel.submitCheckin(
              mood: mood,
              intensity: intensity,
              note: note,
            );
            submitted = result != null;
          },
        );
      },
    );

    if (submitted && mounted) {
      analytics.healingCheckin();
      Navigator.of(
        context,
      ).pushNamed('/healing/checkin-result', arguments: viewModel.lastCheckin);
    }
  }

  List<Widget> _buildRitualSection(
    BuildContext context,
    HealingHomeData? home,
  ) {
    final rituals = home?.sections.rituals ?? const [];
    final fallback = home?.sections.exercises ?? const [];
    final items = rituals.isNotEmpty
        ? rituals
        : fallback.isNotEmpty
        ? fallback
        : (home?.sections.articles ?? const []);
    if (items.isEmpty) {
      return const [SizedBox.shrink()];
    }
    final visibleItems = items.take(6).toList();
    return [
      const SizedBox(height: 26),
      _SectionHeader(
        title: 'Nghi thức hằng ngày',
        action: 'Xem tất cả',
        onTap: () =>
            Navigator.of(context).pushNamed('/healing/ritual-overview'),
      ),
      const SizedBox(height: 12),
      SizedBox(
        height: 244,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          itemCount: visibleItems.length,
          separatorBuilder: (_, __) => const SizedBox(width: 14),
          itemBuilder: (_, i) {
            final item = visibleItems[i];
            return _SquareRitualCard(
              type: _ritualBadgeFor(item),
              title: item.title,
              duration: _ritualDurationLabel(item),
              image: _ritualImageFor(item, i),
              onTap: () => _openRitualItem(context, item),
            );
          },
        ),
      ),
    ];
  }

  String _ritualBadgeFor(HealingContentPreview item) {
    final type = item.type.toUpperCase();
    if (type == 'AUDIO') return 'AUDIO';
    if (type == 'EXERCISE') return 'BÀI TẬP';
    if (type == 'ARTICLE') return 'ĐỌC';
    final tags = item.tags.map((t) => t.toLowerCase()).toList();
    if (tags.contains('audio') || tags.contains('breathing')) return 'AUDIO';
    return 'ĐỌC';
  }

  String _ritualDurationLabel(HealingContentPreview item) {
    final mins = item.estimatedMinutes ?? 5;
    return '$mins phút';
  }

  String _ritualImageFor(HealingContentPreview item, int index) {
    final type = item.type.toUpperCase();
    if (type == 'AUDIO') return HealingStitchAssets.meditation;
    return index.isEven
        ? HealingStitchAssets.openBook
        : HealingStitchAssets.meditation;
  }

  void _openRitualItem(BuildContext context, HealingContentPreview item) {
    final type = item.type.toUpperCase();
    final tags = item.tags.map((t) => t.toLowerCase()).toList();
    final route = switch (type) {
      'AUDIO' => '/healing/ritual-audio-detail',
      'EXERCISE' => '/healing/exercise-detail',
      'ARTICLE' => '/healing/article-detail',
      'RITUAL' =>
        tags.contains('audio') || tags.contains('breathing')
            ? '/healing/ritual-audio-detail'
            : '/healing/ritual-reading-detail',
      _ => '/healing/ritual-reading-detail',
    };
    Navigator.of(context).pushNamed(route, arguments: item.id);
  }

  void _openPrimaryMoodAction(HealingLogSnapshot mood) {
    final action = resolveActionForMood(
      mood: mood.mood,
      intensity: mood.intensity,
    );
    Navigator.of(context).pushNamed(resolveRoute(action));
  }

  Future<void> _openPlanItem(HealingPlanTimelineItem item) async {
    final itemType = item.type.toUpperCase();
    final route = switch (itemType) {
      'ARTICLE' => '/healing/article-detail',
      'EXERCISE' => '/healing/exercise-detail',
      'AUDIO' => '/healing/audio-player',
      'RITUAL' => '/healing/ritual-reading-detail',
      _ => '/healing/article-detail',
    };
    final arguments = switch (itemType) {
      'AUDIO' => {'audioId': item.contentId, 'planMode': true},
      'RITUAL' => {'ritualId': item.contentId, 'planMode': true},
      _ => item.contentId,
    };
    final completed = await Navigator.of(
      context,
    ).pushNamed(route, arguments: arguments);
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
      'REFLECTION' => 'Reflection',
      _ => item.type,
    };
  }
}

class _PostCheckinPrimaryActionCard extends StatelessWidget {
  final String topMessage;
  final String ctaLabel;
  final VoidCallback onTap;

  const _PostCheckinPrimaryActionCard({
    required this.topMessage,
    required this.ctaLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF2F0ED)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            topMessage,
            style: healingText(size: 14, weight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          HealingGradientButton(label: ctaLabel, onTap: onTap),
        ],
      ),
    );
  }
}

class _ContinueJourneyCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ContinueJourneyCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.1,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [healingSoftShadow(0.1)],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              HealingStitchAssets.dailyAudioWater,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) =>
                  const ColoredBox(color: HealingStitchColors.paleCoral),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.84),
                    Colors.black.withValues(alpha: 0.25),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Text(
                          'ĐANG HỌC',
                          style: healingText(
                            size: 10,
                            weight: FontWeight.w900,
                            color: Colors.white,
                          ).copyWith(letterSpacing: 0.7),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: healingText(
                      size: 25,
                      weight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: healingText(
                      size: 13,
                      weight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.9),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: onTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        gradient: HealingStitchColors.warmGradient,
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          healingGlowShadow(HealingStitchColors.pink),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.play_circle_fill,
                            size: 18,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Tiếp tục ngay',
                            style: healingText(
                              size: 13,
                              weight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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

class _StartHealingPathCard extends StatelessWidget {
  final VoidCallback onCheckin;
  final VoidCallback onReflection;
  final bool showCheckinAction;

  const _StartHealingPathCard({
    required this.onCheckin,
    required this.onReflection,
    required this.showCheckinAction,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.1,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [healingSoftShadow(0.1)],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              HealingStitchAssets.dailyHero,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) =>
                  const ColoredBox(color: HealingStitchColors.paleCoral),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.84),
                    Colors.black.withValues(alpha: 0.25),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Text(
                          'MỚI BẮT ĐẦU',
                          style: healingText(
                            size: 10,
                            weight: FontWeight.w900,
                            color: Colors.white,
                          ).copyWith(letterSpacing: 0.7),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: HealingStitchColors.pink,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.bolt,
                              size: 12,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'SẴN SÀNG',
                              style: healingText(
                                size: 10,
                                weight: FontWeight.w900,
                                color: Colors.white,
                              ).copyWith(letterSpacing: 0.7),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Bắt đầu hành trình',
                    style: healingText(
                      size: 25,
                      weight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Mỗi bước nhỏ đều giúp bạn nhẹ lòng hơn. Hãy để Bondy đồng hành cùng bạn hôm nay.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: healingText(
                      size: 13,
                      weight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.9),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      if (showCheckinAction) ...[
                        Expanded(
                          child: GestureDetector(
                            onTap: onCheckin,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: Colors.white54),
                              ),
                              child: Center(
                                child: Text(
                                  'Check-in',
                                  style: healingText(
                                    size: 13,
                                    weight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: GestureDetector(
                          onTap: onReflection,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            decoration: BoxDecoration(
                              gradient: HealingStitchColors.warmGradient,
                              borderRadius: BorderRadius.circular(999),
                              boxShadow: [
                                healingGlowShadow(HealingStitchColors.pink),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.auto_awesome,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Reflection',
                                  style: healingText(
                                    size: 13,
                                    weight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayForYouCard extends StatelessWidget {
  final HealingPrimaryIntent intent;
  final String? title;
  final String? subtitle;
  final VoidCallback onTap;

  const _TodayForYouCard({
    required this.intent,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fallbackTitle = switch (intent) {
      HealingPrimaryIntent.stabilize => 'Ổn định cảm xúc trước',
      HealingPrimaryIntent.reflect => 'Gợi ý phản tư cho bạn',
      HealingPrimaryIntent.rebuild => 'Tiếp tục xây lại nhịp mới',
    };
    final displayTitle = title ?? fallbackTitle;
    final fallbackSubtitle = switch (intent) {
      HealingPrimaryIntent.stabilize => 'Bài tập giúp bạn bình tâm lại.',
      HealingPrimaryIntent.reflect => 'Dành vài phút viết ra suy nghĩ.',
      HealingPrimaryIntent.rebuild => 'Cùng nhau học cách buông bỏ.',
    };
    final displaySubtitle = subtitle?.isNotEmpty == true
        ? subtitle!
        : fallbackSubtitle;
    final imageAsset = switch (intent) {
      HealingPrimaryIntent.stabilize => HealingStitchAssets.meditation,
      HealingPrimaryIntent.reflect => HealingStitchAssets.openBook,
      HealingPrimaryIntent.rebuild => HealingStitchAssets.dailyAudioBeach,
    };
    final badgeText = switch (intent) {
      HealingPrimaryIntent.stabilize => 'BÌNH TÂM',
      HealingPrimaryIntent.reflect => 'PHẢN TƯ',
      HealingPrimaryIntent.rebuild => 'BƯỚC TIẾP',
    };

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF3F4F6)),
          boxShadow: [healingSoftShadow(0.035)],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(
                imageAsset,
                width: 72,
                height: 72,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    const ColoredBox(color: HealingStitchColors.paleCoral),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    badgeText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: healingText(
                      size: 10,
                      weight: FontWeight.w900,
                      color: HealingStitchColors.pink,
                    ).copyWith(letterSpacing: 0.4),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    displayTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: healingText(size: 14, weight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    displaySubtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: healingText(
                      size: 12,
                      color: HealingStitchColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: HealingStitchColors.paleCoral,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward,
                color: HealingStitchColors.pink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickCheckinCard extends StatelessWidget {
  final VoidCallback onTap;

  const _QuickCheckinCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF3F4F6)),
          boxShadow: [healingSoftShadow(0.04)],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: HealingStitchColors.paleCoral,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.mood,
                color: HealingStitchColors.orange,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Check-in cảm xúc',
                style: healingText(size: 15, weight: FontWeight.w800),
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

class _ReflectionPromptCard extends StatelessWidget {
  final String prompt;
  final VoidCallback onTap;

  const _ReflectionPromptCard({required this.prompt, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF3F4F6)),
          boxShadow: [healingSoftShadow(0.04)],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: HealingStitchColors.purple.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.psychology_alt,
                color: HealingStitchColors.purple,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Gợi ý reflection: $prompt',
                style: healingText(size: 14, weight: FontWeight.w700),
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

class _StageProgressCard extends StatelessWidget {
  final HealingPlanTimeline plan;

  const _StageProgressCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    final totalDays = plan.durationDays == 0 ? 1 : plan.durationDays;
    final clampedCurrent = plan.currentDay.clamp(1, totalDays);
    final percent = ((clampedCurrent / totalDays) * 100).round();
    final fraction = (clampedCurrent / totalDays).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF2F0ED)),
        boxShadow: [healingSoftShadow(0.04)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NGÀY $clampedCurrent / $totalDays',
                      style: healingText(
                        size: 11,
                        weight: FontWeight.w900,
                        color: HealingStitchColors.pink,
                      ).copyWith(letterSpacing: 0.8),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      plan.title,
                      style: healingText(size: 20, weight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              Text(
                '$percent%',
                style: healingText(
                  size: 13,
                  weight: FontWeight.w700,
                  color: HealingStitchColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 10,
              backgroundColor: const Color(0xFFF3F4F6),
              valueColor: AlwaysStoppedAnimation<Color>(
                HealingStitchColors.pink,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Bạn đang làm rất tốt. Hãy đi chậm, không cần vội vàng để chữa lành.',
            style: healingText(
              size: 13,
              height: 1.45,
              color: HealingStitchColors.textSoft,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String action;
  final VoidCallback? onTap;

  const _SectionHeader({
    required this.title,
    required this.action,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: healingText(size: 21, weight: FontWeight.w900),
          ),
        ),
        if (action.isNotEmpty)
          TextButton(
            onPressed: onTap,
            child: Text(
              action,
              style: healingText(
                size: 13,
                weight: FontWeight.w800,
                color: HealingStitchColors.pink,
              ),
            ),
          ),
      ],
    );
  }
}

class _SquareRitualCard extends StatelessWidget {
  final String type;
  final String title;
  final String duration;
  final String image;
  final VoidCallback onTap;

  const _SquareRitualCard({
    required this.type,
    required this.title,
    required this.duration,
    required this.image,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 150,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      image,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const ColoredBox(
                        color: HealingStitchColors.paleCoral,
                      ),
                    ),
                    Align(
                      alignment: Alignment.topRight,
                      child: Container(
                        margin: const EdgeInsets.all(10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          duration,
                          style: healingText(size: 10, weight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: HealingStitchColors.pink.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                type,
                style: healingText(
                  size: 10,
                  weight: FontWeight.w900,
                  color: HealingStitchColors.pink,
                ).copyWith(letterSpacing: 0.6),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: healingText(
                size: 15,
                weight: FontWeight.w900,
                height: 1.15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoachCard extends StatelessWidget {
  final VoidCallback onTap;

  const _CoachCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFF3F4F6)),
          boxShadow: [healingSoftShadow(0.07)],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFFF3F4F6)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.forum,
                    size: 14,
                    color: HealingStitchColors.pink,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'TÂM SỰ',
                    style: healingText(
                      size: 10,
                      weight: FontWeight.w900,
                      color: HealingStitchColors.textSoft,
                    ).copyWith(letterSpacing: 1),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Đang thấy quá tải? Bondy ở đây để lắng nghe mà không phán xét.',
              textAlign: TextAlign.center,
              style: healingText(
                size: 20,
                weight: FontWeight.w700,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 18),
            Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                gradient: HealingStitchColors.warmGradient,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConnectGentlyCard extends StatelessWidget {
  final VoidCallback onTap;

  const _ConnectGentlyCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF5F3F0)),
        boxShadow: [healingSoftShadow(0.035)],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFEDD5)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.spa_outlined,
                  color: HealingStitchColors.orange,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Đi chậm thôi',
                        style: healingText(
                          size: 13,
                          weight: FontWeight.w900,
                          color: const Color(0xFF9A3412),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Kết nối với người cùng hành trình. Không áp lực phải phản hồi ngay.',
                        style: healingText(
                          size: 11,
                          height: 1.35,
                          color: const Color(0xFFB45309),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tìm một người đồng hành',
                      style: healingText(size: 13, weight: FontWeight.w800),
                    ),
                    TextButton.icon(
                      onPressed: onTap,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      iconAlignment: IconAlignment.end,
                      icon: const Icon(Icons.arrow_forward, size: 16),
                      label: Text(
                        'Tìm match',
                        style: healingText(
                          size: 13,
                          weight: FontWeight.w900,
                          color: HealingStitchColors.pink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
