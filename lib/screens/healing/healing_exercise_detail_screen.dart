import 'package:flutter/material.dart';

import '../../viewmodels/healing/healing_detail_viewmodels.dart';
import 'healing_stitch_style.dart';

class HealingExerciseDetailScreen extends StatefulWidget {
  final String? contentId;
  final HealingExerciseViewModel? viewModel;
  final bool autoPopOnComplete;

  const HealingExerciseDetailScreen({
    super.key,
    this.contentId,
    this.viewModel,
    this.autoPopOnComplete = true,
  });

  @override
  State<HealingExerciseDetailScreen> createState() =>
      _HealingExerciseDetailScreenState();
}

class _HealingExerciseDetailScreenState
    extends State<HealingExerciseDetailScreen> {
  late final HealingExerciseViewModel _viewModel;
  bool _ownsViewModel = false;
  bool _didLoad = false;

  @override
  void initState() {
    super.initState();
    _viewModel = widget.viewModel ?? HealingExerciseViewModel();
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
      _viewModel.loadExercise(id);
    }

    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        final exercise = _viewModel.exercise;
        return Scaffold(
          backgroundColor: HealingStitchColors.creamBackground,
          body: SafeArea(
            child: Column(
              children: [
                HealingTopBar(
                  title: 'Bài tập',
                  onBack: () => Navigator.of(context).maybePop(),
                ),
                if (_viewModel.isLoading && exercise == null)
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
                          exercise?.title ?? 'Bài tập chữa lành',
                          style: healingText(size: 28, weight: FontWeight.w900),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          exercise?.summary ?? '',
                          style: healingText(
                            size: 14,
                            color: HealingStitchColors.textSoft,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ...List.generate(exercise?.steps.length ?? 0, (index) {
                          final step = exercise!.steps[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFFF2F0ED),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor:
                                      HealingStitchColors.paleCoral,
                                  child: _viewModel.isCompleted
                                      ? const Icon(
                                          Icons.check,
                                          size: 16,
                                          color: HealingStitchColors.pink,
                                        )
                                      : Text(
                                          '${index + 1}',
                                          style: healingText(
                                            size: 12,
                                            weight: FontWeight.w900,
                                            color: HealingStitchColors.pink,
                                          ),
                                        ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    step,
                                    style: healingText(size: 14, height: 1.4),
                                  ),
                                ),
                              ],
                            ),
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
                label: _viewModel.isCompleted
                    ? 'Đã hoàn thành'
                    : _viewModel.isCompleting
                    ? 'Đang hoàn thành...'
                    : 'Hoàn thành bài tập',
                icon: _viewModel.isCompleted
                    ? Icons.check_circle
                    : Icons.task_alt,
                onTap: _viewModel.isCompleting
                    ? () {}
                    : _viewModel.isCompleted
                    ? () => Navigator.of(context).pop(true)
                    : () async {
                        final navigator = Navigator.of(context);
                        await _viewModel.complete(
                          durationSeconds:
                              (exercise?.durationMinutes ?? 0) * 60,
                        );
                        if (!mounted || !_viewModel.isCompleted) return;
                        if (widget.autoPopOnComplete) {
                          navigator.pop(true);
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
    return ModalRoute.of(context)?.settings.arguments?.toString() ??
        'exercise-self-worth-checklist';
  }
}
