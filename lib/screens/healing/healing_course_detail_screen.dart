import 'package:flutter/material.dart';

import '../../models/healing/healing_models.dart';
import '../../viewmodels/healing/healing_detail_viewmodels.dart';
import 'healing_navigation.dart';
import 'healing_stitch_style.dart';

class HealingCourseDetailScreen extends StatefulWidget {
  final String? contentId;
  final HealingCourseViewModel? viewModel;

  const HealingCourseDetailScreen({super.key, this.contentId, this.viewModel});

  @override
  State<HealingCourseDetailScreen> createState() =>
      _HealingCourseDetailScreenState();
}

class _HealingCourseDetailScreenState extends State<HealingCourseDetailScreen> {
  late final HealingCourseViewModel _viewModel;
  bool _ownsViewModel = false;
  bool _didLoad = false;

  @override
  void initState() {
    super.initState();
    _viewModel = widget.viewModel ?? HealingCourseViewModel();
    _ownsViewModel = widget.viewModel == null;
  }

  @override
  void dispose() {
    if (_ownsViewModel) _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final id = _contentId(context);
    if (!_didLoad) {
      _didLoad = true;
      _viewModel.loadCourse(id);
    }

    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        final course = _viewModel.course;
        return Scaffold(
          backgroundColor: HealingStitchColors.creamBackground,
          body: SafeArea(
            child: Column(
              children: [
                HealingTopBar(
                  title: 'Lộ trình',
                  onBack: () => Navigator.of(context).maybePop(),
                ),
                if (_viewModel.isLoading && course == null)
                  const Expanded(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: HealingStitchColors.pink,
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
                      children: [
                        Text(
                          course?.title ?? 'Lộ trình chữa lành',
                          style: healingText(size: 28, weight: FontWeight.w900),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          course?.summary ?? '',
                          style: healingText(
                            size: 14,
                            color: HealingStitchColors.textSoft,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _ProgressCard(course: course),
                        const SizedBox(height: 20),
                        ...List.generate(course?.lessons.length ?? 0, (index) {
                          final lesson = course!.lessons[index];
                          final isCompleted = _viewModel.isLessonCompleted(
                            lesson,
                          );
                          return _LessonTile(
                            lesson: lesson,
                            isCompleted: isCompleted,
                            onTap: isCompleted
                                ? null
                                : () => _openLesson(lesson),
                          );
                        }),
                        if (_viewModel.errorMessage != null)
                          Text(
                            _viewModel.errorMessage!,
                            style: healingText(
                              size: 12,
                              color: HealingStitchColors.pink,
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
          floatingActionButton: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              child: HealingGradientButton(
                label: _viewModel.isCourseCompleted
                    ? 'Đã hoàn thành'
                    : course?.progress == null
                    ? 'Bắt đầu lộ trình'
                    : 'Tiếp tục',
                icon: _viewModel.isCourseCompleted
                    ? Icons.check_circle
                    : Icons.play_circle_fill,
                onTap: _viewModel.isMutating || _viewModel.isCourseCompleted
                    ? () {}
                    : () {
                        if (course?.progress == null) {
                          _viewModel.startCourse();
                        } else {
                          _openCurrentLesson(course);
                        }
                      },
              ),
            ),
          ),
        );
      },
    );
  }

  String _contentId(BuildContext context) {
    if (widget.contentId?.isNotEmpty == true) return widget.contentId!;
    // Trước đây fallback về 'course-ghost-confidence' nên route bị thiếu id
    // sẽ silent load nhầm course → user thấy nội dung không phải họ chọn.
    // Trả chuỗi rỗng để loadCourse báo lỗi rõ thay vì show ghost content.
    return ModalRoute.of(context)?.settings.arguments?.toString() ?? '';
  }

  void _openCurrentLesson(HealingCourse? course) {
    if (course == null) return;
    final available = course.lessons.where(
      (lesson) => !lesson.isLocked && !_viewModel.isLessonCompleted(lesson),
    );
    if (available.isEmpty) return;
    _openLesson(available.first);
  }

  Future<void> _openLesson(HealingCourseLesson lesson) async {
    if (lesson.isLocked) return;
    Object? completed;
    if (lesson.articleContentId?.isNotEmpty == true) {
      completed = await Navigator.of(context).pushNamed(
        healingArticleDetailRoute,
        arguments: lesson.articleContentId,
      );
    } else if (lesson.exerciseContentId?.isNotEmpty == true) {
      completed = await Navigator.of(context).pushNamed(
        healingExerciseDetailRoute,
        arguments: lesson.exerciseContentId,
      );
    } else {
      await _viewModel.completeLesson(lesson);
      return;
    }
    if (mounted && completed == true) {
      await _viewModel.completeLesson(lesson);
    }
  }
}

class _ProgressCard extends StatelessWidget {
  final HealingCourse? course;

  const _ProgressCard({required this.course});

  @override
  Widget build(BuildContext context) {
    final currentDay = course?.progress?.currentDay ?? 1;
    final totalDays = course?.durationDays ?? 1;
    final value = totalDays <= 0
        ? 0.0
        : (currentDay / totalDays).clamp(0, 1).toDouble();

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
            value: value,
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

class _LessonTile extends StatelessWidget {
  final HealingCourseLesson lesson;
  final bool isCompleted;
  final VoidCallback? onTap;

  const _LessonTile({
    required this.lesson,
    required this.isCompleted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: lesson.isLocked || isCompleted ? null : onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFF2F0ED)),
            ),
            child: Row(
              children: [
                Icon(
                  isCompleted
                      ? Icons.check_circle
                      : lesson.isLocked
                      ? Icons.lock_outline
                      : Icons.play_arrow,
                  color: lesson.isLocked
                      ? HealingStitchColors.textMuted
                      : isCompleted
                      ? const Color(0xFF16A34A)
                      : HealingStitchColors.pink,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lesson.title,
                        style: healingText(size: 14, weight: FontWeight.w900),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${lesson.estimatedMinutes} phút',
                        style: healingText(
                          size: 12,
                          color: HealingStitchColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  isCompleted
                      ? 'Đã xong'
                      : lesson.isLocked
                      ? 'Đang khoá'
                      : 'Có thể học',
                  style: healingText(
                    size: 12,
                    weight: FontWeight.w900,
                    color: lesson.isLocked
                        ? HealingStitchColors.textMuted
                        : isCompleted
                        ? const Color(0xFF16A34A)
                        : HealingStitchColors.pink,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
