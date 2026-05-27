import '../../models/healing/healing_models.dart';

abstract class HealingDataSource {
  Future<HealingHomeData> fetchHome();

  Future<HealingCheckinResult> checkIn({
    required String mood,
    required int intensity,
    String? context,
    String source = 'VOLUNTARY',
    String? note,
  });

  Future<HealingArticle> fetchArticle(String id);

  Future<HealingCompletionResult> completeArticle(
    String id, {
    int? durationSeconds,
    Object? answers,
  });

  Future<HealingAudio> fetchAudio(String id);

  Future<HealingRitual> fetchRitual(String id);

  Future<HealingExercise> fetchExercise(String id);

  Future<HealingCompletionResult> completeExercise(
    String id, {
    int? durationSeconds,
    Object? answers,
  });

  Future<HealingCourse> fetchCourse(String id);

  Future<HealingCourseStartResult> startCourse(String id);

  Future<HealingCompletionResult> completeLesson(
    String courseId,
    String lessonId, {
    int? durationSeconds,
    Object? answers,
  });

  Future<HealingEntryState> fetchEntryState({String entry = 'VOLUNTARY'});

  Future<HealingPlanTimeline> fetchActivePlanTimeline();

  Future<HealingPlanPreview> fetchRecommendedPlanPreview();

  Future<HealingPlanStartResult> startRecommendedPlan();

  Future<HealingCompletionResult> completePlanItem(
    String id, {
    required String completionType,
    int? durationSeconds,
    Object? answers,
  });
}
