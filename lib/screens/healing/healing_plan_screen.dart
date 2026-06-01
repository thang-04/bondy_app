import 'package:flutter/material.dart';

import '../../core/bondy_error_mapper.dart';
import '../../models/healing/healing_models.dart';
import '../../services/healing/healing_service.dart';
import 'healing_audio_player_screen.dart';
import 'healing_navigation.dart';
import 'healing_stitch_style.dart';
import 'ritual_reading_detail_screen.dart';

class HealingPlanScreen extends StatefulWidget {
  final HealingDataSource? service;
  final bool? preview;

  const HealingPlanScreen({super.key, this.service, this.preview});

  @override
  State<HealingPlanScreen> createState() => _HealingPlanScreenState();
}

class _HealingPlanScreenState extends State<HealingPlanScreen> {
  late final HealingDataSource _service;
  HealingPlanPreview? _preview;
  HealingPlanTimeline? _timeline;
  bool _showPreview = false;
  bool _didResolveMode = false;
  bool _isLoading = true;
  bool _isMutating = false;
  String? _errorMessage;

  bool get _isPreview => _showPreview;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? HealingService();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didResolveMode) return;
    _didResolveMode = true;
    _showPreview =
        widget.preview ??
        ((ModalRoute.of(context)?.settings.arguments as Map?)?['preview'] ==
            true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      if (_isPreview) {
        _preview = await _service.fetchRecommendedPlanPreview();
      } else {
        try {
          _timeline = await _service.fetchActivePlanTimeline();
        } catch (_) {
          // Fallback sang preview khi fetch timeline lỗi (VD: server trả về 404 do chưa có active plan)
          _showPreview = true;
          _preview = await _service.fetchRecommendedPlanPreview();
        }
      }
    } catch (error) {
      _errorMessage = BondyErrorMapper.message(error);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _startPlan() async {
    setState(() => _isMutating = true);
    try {
      await _service.startRecommendedPlan();
      if (!mounted) return;
      // Đổi sang chế độ timeline NGAY sau khi server confirm start. Nếu fetch
      // timeline phía dưới throw thì UI vẫn rời preview và hiện error state
      // thay vì treo ở preview với _preview=null gây null pointer.
      setState(() {
        _preview = null;
        _showPreview = false;
        _timeline = null;
      });
      final timeline = await _service.fetchActivePlanTimeline();
      if (!mounted) return;
      setState(() => _timeline = timeline);
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = BondyErrorMapper.message(error));
    } finally {
      if (mounted) {
        setState(() => _isMutating = false);
      }
    }
  }

  /// Bug fix: hiển thị bottom sheet với danh sách các task của ngày được chọn
  /// để user tự chọn task muốn làm, thay vì auto-mở task đầu tiên chưa hoàn
  /// thành như _continueCurrentDay() vẫn làm.
  ///
  /// UX:
  ///   - Ngày khóa (chưa unlock): chỉ show preview, không cho mở task
  ///   - Ngày current/đã unlock: mỗi task có icon (done/play/lock) + onTap
  ///   - Task đã hoàn thành: hiển thị status xanh, vẫn cho tap để xem lại
  Future<void> _showDayTaskList(HealingPlanDayTimeline day) async {
    if (!mounted) return;
    final canStartTasks = day.isUnlocked || day.isCompleted;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              color: HealingStitchColors.creamBackground,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: HealingStitchColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      day.isCompleted
                          ? Icons.check_circle
                          : day.isUnlocked
                              ? Icons.play_circle_outline
                              : Icons.lock_outline,
                      color: day.isCompleted
                          ? const Color(0xFF16A34A)
                          : day.isUnlocked
                              ? HealingStitchColors.pink
                              : HealingStitchColors.textMuted,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Ngày ${day.dayNumber}: ${day.title}',
                        style: healingText(size: 18, weight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
                if (day.reflectionPrompt != null &&
                    day.reflectionPrompt!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    day.reflectionPrompt!,
                    style: healingText(
                      size: 13,
                      color: HealingStitchColors.textSoft,
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  '${day.items.where((i) => i.isCompleted).length}/${day.items.length} mục hoàn thành',
                  style: healingText(
                    size: 12,
                    color: HealingStitchColors.textMuted,
                  ),
                ),
                const SizedBox(height: 16),
                if (day.items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'Ngày này chưa có nội dung. Hãy quay lại sau nhé.',
                        style: healingText(color: HealingStitchColors.textMuted),
                      ),
                    ),
                  )
                else
                  ...day.items.map(
                    (item) => _PlanItemListTile(
                      item: item,
                      enabled: canStartTasks,
                      onTap: canStartTasks
                          ? () async {
                              Navigator.of(sheetContext).pop();
                              await _openItem(item);
                            }
                          : null,
                    ),
                  ),
                if (!canStartTasks) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: HealingStitchColors.paleCoral,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lock_outline,
                            color: HealingStitchColors.coral, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Hoàn thành các ngày trước để mở khoá ngày này',
                            style: healingText(
                              size: 12,
                              color: HealingStitchColors.coral,
                              weight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _continueCurrentDay() async {
    final timeline = _timeline;
    if (timeline == null) return;
    final day = _currentDay(timeline);
    if (day == null) return;
    final next = _firstIncompleteItem(day.items);
    if (next == null) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(healingHomeRoute, (_) => false);
      return;
    }
    await _openItem(next);
  }

  Future<void> _openItem(HealingPlanTimelineItem item) async {
    Object? completed;
    if (item.type == 'ARTICLE') {
      completed = await Navigator.of(
        context,
      ).pushNamed(healingArticleDetailRoute, arguments: item.contentId);
      if (completed == true) {
        await _service.completePlanItem(
          item.contentId,
          completionType: item.type,
        );
      }
    } else if (item.type == 'EXERCISE') {
      completed = await Navigator.of(
        context,
      ).pushNamed(healingExerciseDetailRoute, arguments: item.contentId);
      // Trước đó EXERCISE bị bỏ sót completePlanItem nên server vẫn coi như
      // chưa hoàn thành dù user đã làm xong, dẫn đến day không bao giờ
      // unlock task kế tiếp.
      if (completed == true) {
        await _service.completePlanItem(
          item.contentId,
          completionType: item.type,
        );
      }
    } else if (item.type == 'AUDIO') {
      // Trước đây không truyền audioId nên player tự fallback null và không
      // play được gì — user thấy màn loading rỗng → tưởng app treo.
      completed = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => HealingAudioPlayerScreen(
            planMode: true,
            audioId: item.contentId,
          ),
        ),
      );
      if (completed == true) {
        await _service.completePlanItem(
          item.contentId,
          completionType: item.type,
        );
      }
    } else if (item.type == 'RITUAL') {
      // Trước đây không truyền ritualId nên screen luôn show content cứng cho
      // mọi ritual của plan. Giờ pass id để load đúng nội dung từ server.
      completed = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => RitualReadingDetailScreen(
            planMode: true,
            ritualId: item.contentId,
          ),
        ),
      );
      if (completed == true) {
        await _service.completePlanItem(
          item.contentId,
          completionType: item.type,
        );
      }
    }

    if (completed != true || !mounted) return;
    final refreshed = await _service.fetchActivePlanTimeline();
    if (!mounted) return;
    setState(() => _timeline = refreshed);

    final current = _currentDay(refreshed);
    if (current == null || current.isCompleted) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(healingHomeRoute, (_) => false);
      return;
    }

    final next = _firstIncompleteItem(current.items);
    if (next != null) {
      await _openItem(next);
    }
  }

  HealingPlanDayTimeline? _currentDay(HealingPlanTimeline timeline) {
    for (final day in timeline.days) {
      if (day.dayNumber == timeline.currentDay) return day;
    }
    return null;
  }

  HealingPlanTimelineItem? _firstIncompleteItem(
    List<HealingPlanTimelineItem> items,
  ) {
    for (final item in items) {
      if (!item.isCompleted) return item;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final preview = _preview;
    final timeline = _timeline;
    final title = preview?.title ?? timeline?.title ?? 'Lộ trình chữa lành';
    final description = preview?.description ?? timeline?.description ?? '';
    final days =
        preview?.days ?? timeline?.days ?? const <HealingPlanDayTimeline>[];
    final totalDays =
        preview?.durationDays ?? timeline?.durationDays ?? days.length;
    final currentDay = timeline?.currentDay;
    final progress = timeline?.progressPercent ?? 0;

    return Scaffold(
      backgroundColor: HealingStitchColors.creamBackground,
      body: SafeArea(
        child: Column(
          children: [
            HealingTopBar(
              title: _isPreview ? 'Xem trước lộ trình' : 'Lộ trình',
              onBack: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: HealingStitchColors.pink,
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
                      children: [
                        Text(
                          title,
                          style: healingText(size: 28, weight: FontWeight.w900),
                        ),
                        if (description.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            description,
                            style: healingText(
                              size: 14,
                              color: HealingStitchColors.textSoft,
                              height: 1.4,
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                        if (!_isPreview && timeline != null)
                          _PlanProgressCard(
                            currentDay: currentDay ?? 1,
                            totalDays: totalDays,
                            progressPercent: progress,
                          ),
                        const SizedBox(height: 16),
                        ...days.map(
                          (day) => _PlanDayTile(
                            day: day,
                            isCurrent:
                                !_isPreview &&
                                currentDay != null &&
                                day.dayNumber == currentDay,
                            // Bug fix: cho phép tap vào ngày để xem danh sách
                            // việc cần làm thay vì auto-mở bài tập đầu tiên.
                            // Preview mode (chưa bắt đầu lộ trình) thì không có
                            // gì để mở — tile sẽ không tappable.
                            onTap: _isPreview
                                ? null
                                : () => _showDayTaskList(day),
                          ),
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _errorMessage!,
                            style: healingText(
                              size: 12,
                              color: HealingStitchColors.pink,
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SizedBox(
          width: double.infinity,
          child: HealingGradientButton(
            label: _isPreview
                ? (_isMutating ? 'Đang bắt đầu...' : 'Bắt đầu lộ trình')
                : 'Tiếp tục ngày hiện tại',
            icon: _isPreview ? Icons.play_circle_fill : Icons.arrow_forward,
            onTap: _isPreview
                ? (_isMutating ? () {} : () => _startPlan())
                : () => _continueCurrentDay(),
          ),
        ),
      ),
    );
  }
}

class _PlanProgressCard extends StatelessWidget {
  final int currentDay;
  final int totalDays;
  final int progressPercent;

  const _PlanProgressCard({
    required this.currentDay,
    required this.totalDays,
    required this.progressPercent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF2F0ED)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ngày $currentDay/$totalDays',
            style: healingText(size: 14, weight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: (progressPercent / 100).clamp(0, 1).toDouble(),
            minHeight: 8,
            backgroundColor: const Color(0xFFF3F4F6),
            valueColor: const AlwaysStoppedAnimation<Color>(
              HealingStitchColors.pink,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanDayTile extends StatelessWidget {
  final HealingPlanDayTimeline day;
  final bool isCurrent;
  final VoidCallback? onTap;

  const _PlanDayTile({
    required this.day,
    required this.isCurrent,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isCurrent
                  ? HealingStitchColors.pink
                  : const Color(0xFFF2F0ED),
            ),
          ),
          child: Row(
            children: [
              Icon(
                day.isCompleted
                    ? Icons.check_circle
                    : day.isUnlocked || isCurrent
                        ? Icons.play_circle_outline
                        : Icons.lock_outline,
                color: day.isCompleted
                    ? const Color(0xFF16A34A)
                    : day.isUnlocked || isCurrent
                        ? HealingStitchColors.pink
                        : HealingStitchColors.textMuted,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ngày ${day.dayNumber}: ${day.title}',
                      style: healingText(size: 14, weight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${day.items.where((item) => item.isCompleted).length}/${day.items.length} mục hoàn thành',
                      style: healingText(
                        size: 12,
                        color: HealingStitchColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.chevron_right,
                  color: HealingStitchColors.textMuted.withValues(alpha: 0.5),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Single task tile rendered in the day-detail bottom sheet (see
/// _showDayTaskList). Each item shows its type (article/exercise/audio/ritual),
/// title, duration, and a play/done indicator. Locked days disable the tap.
class _PlanItemListTile extends StatelessWidget {
  final HealingPlanTimelineItem item;
  final bool enabled;
  final VoidCallback? onTap;

  const _PlanItemListTile({
    required this.item,
    required this.enabled,
    this.onTap,
  });

  /// Fallback label when the server hasn't filled in `title` (older content
  /// without seed entry). Returns a human-friendly description by item type.
  String _fallbackTitle(HealingPlanTimelineItem item) {
    return switch (item.type) {
      'ARTICLE' => 'Bài đọc hôm nay',
      'EXERCISE' => 'Bài tập chữa lành',
      'AUDIO' => 'Phiên audio',
      'RITUAL' => 'Nghi thức kết thúc ngày',
      _ => item.contentId,
    };
  }

  @override
  Widget build(BuildContext context) {
    final typeLabel = switch (item.type) {
      'ARTICLE' => 'Bài đọc',
      'EXERCISE' => 'Bài tập',
      'AUDIO' => 'Audio',
      'RITUAL' => 'Nghi thức',
      _ => item.type,
    };
    final typeIcon = switch (item.type) {
      'ARTICLE' => Icons.menu_book_outlined,
      'EXERCISE' => Icons.self_improvement,
      'AUDIO' => Icons.headphones_outlined,
      'RITUAL' => Icons.spa_outlined,
      _ => Icons.task_alt_outlined,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: item.isCompleted
                  ? const Color(0xFFF0FDF4)
                  : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: item.isCompleted
                    ? const Color(0xFF86EFAC)
                    : const Color(0xFFF2F0ED),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: item.isCompleted
                        ? const Color(0xFFDCFCE7)
                        : HealingStitchColors.paleCoral,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    item.isCompleted ? Icons.check : typeIcon,
                    color: item.isCompleted
                        ? const Color(0xFF16A34A)
                        : HealingStitchColors.coral,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: HealingStitchColors.paleCoral,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              typeLabel,
                              style: healingText(
                                size: 10,
                                weight: FontWeight.w800,
                                color: HealingStitchColors.coral,
                              ),
                            ),
                          ),
                          if (item.estimatedMinutes != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              '${item.estimatedMinutes} phút',
                              style: healingText(
                                size: 11,
                                color: HealingStitchColors.textMuted,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.title ?? _fallbackTitle(item),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: healingText(
                          size: 14,
                          weight: FontWeight.w700,
                          color: enabled
                              ? HealingStitchColors.textMain
                              : HealingStitchColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  enabled
                      ? (item.isCompleted ? Icons.replay : Icons.play_arrow)
                      : Icons.lock_outline,
                  color: enabled
                      ? HealingStitchColors.coral
                      : HealingStitchColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
