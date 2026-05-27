import 'package:bondy/models/healing/healing_models.dart';
import 'package:bondy/screens/healing/healing_exercise_detail_screen.dart';
import 'package:bondy/services/healing/healing_data_source.dart';
import 'package:bondy/services/healing/healing_progress_store.dart';
import 'package:bondy/viewmodels/healing/healing_detail_viewmodels.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() => HealingProgressStore.instance.clear());

  testWidgets('returns true after completing an exercise', (tester) async {
    Object? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => HealingExerciseDetailScreen(
                    contentId: 'exercise-1',
                    viewModel: HealingExerciseViewModel(
                      service: _FakeExerciseDataSource(),
                    ),
                  ),
                ),
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hoàn thành bài tập'));
    await tester.pumpAndSettle();

    expect(result, isTrue);
  });

  testWidgets('marks every step complete after finishing an exercise', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HealingExerciseDetailScreen(
          contentId: 'exercise-1',
          autoPopOnComplete: false,
          viewModel: HealingExerciseViewModel(
            service: _FakeExerciseDataSource(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.check), findsNothing);

    await tester.tap(find.text('Hoàn thành bài tập'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.check), findsNWidgets(2));
  });
}

class _FakeExerciseDataSource implements HealingDataSource {
  @override
  Future<HealingExercise> fetchExercise(String id) async =>
      HealingExercise.fromJson({
        'id': id,
        'title': 'Exercise',
        'summary': 'Summary',
        'exerciseType': 'BREATHING',
        'durationMinutes': 5,
        'difficulty': 'EASY',
        'steps': ['Step 1', 'Step 2'],
        'completionCriteria': 'complete',
      });

  @override
  Future<HealingCompletionResult> completeExercise(
    String id, {
    int? durationSeconds,
    Object? answers,
  }) async =>
      HealingCompletionResult.fromJson({'completed': true});

  @override
  Future<HealingHomeData> fetchHome() => throw UnimplementedError();

  @override
  Future<HealingCheckinResult> checkIn({
    required String mood,
    required int intensity,
    String? context,
    String source = 'VOLUNTARY',
    String? note,
  }) =>
      throw UnimplementedError();

  @override
  Future<HealingArticle> fetchArticle(String id) => throw UnimplementedError();

  @override
  Future<HealingCompletionResult> completeArticle(
    String id, {
    int? durationSeconds,
    Object? answers,
  }) =>
      throw UnimplementedError();

  @override
  Future<HealingAudio> fetchAudio(String id) => throw UnimplementedError();

  @override
  Future<HealingRitual> fetchRitual(String id) => throw UnimplementedError();

  @override
  Future<HealingCourse> fetchCourse(String id) => throw UnimplementedError();

  @override
  Future<HealingCourseStartResult> startCourse(String id) =>
      throw UnimplementedError();

  @override
  Future<HealingCompletionResult> completeLesson(
    String courseId,
    String lessonId, {
    int? durationSeconds,
    Object? answers,
  }) =>
      throw UnimplementedError();

  @override
  Future<HealingEntryState> fetchEntryState({String entry = 'VOLUNTARY'}) =>
      throw UnimplementedError();

  @override
  Future<HealingPlanTimeline> fetchActivePlanTimeline() =>
      throw UnimplementedError();

  @override
  Future<HealingPlanPreview> fetchRecommendedPlanPreview() =>
      throw UnimplementedError();

  @override
  Future<HealingPlanStartResult> startRecommendedPlan() =>
      throw UnimplementedError();

  @override
  Future<HealingCompletionResult> completePlanItem(
    String id, {
    required String completionType,
    int? durationSeconds,
    Object? answers,
  }) =>
      throw UnimplementedError();
}
