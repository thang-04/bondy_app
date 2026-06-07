import '../../models/healing/healing_models.dart';
import '../api_client.dart';
import 'healing_data_source.dart';

export 'healing_data_source.dart';

class HealingService implements HealingDataSource {
  final HealingDataSource _api;

  HealingService({HealingDataSource? api})
    : _api = api ?? HealingApiDataSource();

  @override
  Future<HealingHomeData> fetchHome() async {
    return _read((source) => source.fetchHome());
  }

  @override
  Future<HealingCheckinResult> checkIn({
    required String mood,
    required int intensity,
    String? context,
    String source = 'VOLUNTARY',
    String? note,
  }) async {
    return _read(
      (dataSource) => dataSource.checkIn(
        mood: mood,
        intensity: intensity,
        context: context,
        source: source,
        note: note,
      ),
    );
  }

  @override
  Future<HealingArticle> fetchArticle(String id) async {
    return _read((source) => source.fetchArticle(id));
  }

  @override
  Future<HealingCompletionResult> completeArticle(
    String id, {
    int? durationSeconds,
    Object? answers,
  }) async {
    return _read(
      (source) => source.completeArticle(
        id,
        durationSeconds: durationSeconds,
        answers: answers,
      ),
    );
  }

  @override
  Future<HealingAudio> fetchAudio(String id) async {
    return _read((source) => source.fetchAudio(id));
  }

  @override
  Future<HealingRitual> fetchRitual(String id) async {
    return _read((source) => source.fetchRitual(id));
  }

  @override
  Future<HealingExercise> fetchExercise(String id) async {
    return _read((source) => source.fetchExercise(id));
  }

  @override
  Future<HealingCompletionResult> completeExercise(
    String id, {
    int? durationSeconds,
    Object? answers,
  }) async {
    return _read(
      (source) => source.completeExercise(
        id,
        durationSeconds: durationSeconds,
        answers: answers,
      ),
    );
  }

  @override
  Future<HealingCourse> fetchCourse(String id) async {
    return _read((source) => source.fetchCourse(id));
  }

  @override
  Future<HealingCourseStartResult> startCourse(
    String id, {
    bool replaceActive = false,
  }) async {
    return _read(
      (source) => source.startCourse(id, replaceActive: replaceActive),
    );
  }

  @override
  Future<HealingCompletionResult> completeLesson(
    String courseId,
    String lessonId, {
    int? durationSeconds,
    Object? answers,
  }) async {
    return _read(
      (source) => source.completeLesson(
        courseId,
        lessonId,
        durationSeconds: durationSeconds,
        answers: answers,
      ),
    );
  }

  @override
  Future<HealingEntryState> fetchEntryState({
    String entry = 'VOLUNTARY',
  }) async {
    return _read((source) => source.fetchEntryState(entry: entry));
  }

  @override
  Future<HealingPlanTimeline> fetchActivePlanTimeline() async {
    return _read((source) => source.fetchActivePlanTimeline());
  }

  @override
  Future<HealingPlanPreview> fetchRecommendedPlanPreview() async {
    return _read((source) => source.fetchRecommendedPlanPreview());
  }

  @override
  Future<HealingPlanStartResult> startRecommendedPlan() async {
    return _read((source) => source.startRecommendedPlan());
  }

  @override
  Future<HealingCompletionResult> completePlanItem(
    String id, {
    required String completionType,
    int? durationSeconds,
    Object? answers,
  }) async {
    return _read(
      (source) => source.completePlanItem(
        id,
        completionType: completionType,
        durationSeconds: durationSeconds,
        answers: answers,
      ),
    );
  }

  Future<T> _read<T>(Future<T> Function(HealingDataSource source) read) async {
    return read(_api);
  }
}

class HealingApiDataSource implements HealingDataSource {
  final ApiClient _apiClient;

  HealingApiDataSource({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  @override
  Future<HealingHomeData> fetchHome() async {
    final response = await _apiClient.get('/healing/home', authenticated: true);
    return HealingHomeData.fromJson(_data(response));
  }

  @override
  Future<HealingCheckinResult> checkIn({
    required String mood,
    required int intensity,
    String? context,
    String source = 'VOLUNTARY',
    String? note,
  }) async {
    final response = await _apiClient.post(
      '/healing/checkin',
      authenticated: true,
      body: {
        'mood': mood,
        'readiness': _readinessFromIntensity(intensity),
        'needs': _needsFromMood(mood),
        'trigger': context ?? 'USER_SELF_REPORT',
        'smallGoal': _smallGoalFromInput(note),
        'source': source,
      },
    );
    return HealingCheckinResult.fromJson(_data(response));
  }

  @override
  Future<HealingArticle> fetchArticle(String id) async {
    final response = await _apiClient.get(
      '/healing/articles/$id',
      authenticated: true,
    );
    return HealingArticle.fromJson(_data(response));
  }

  @override
  Future<HealingCompletionResult> completeArticle(
    String id, {
    int? durationSeconds,
    Object? answers,
  }) async {
    final response = await _apiClient.post(
      '/healing/articles/$id/complete',
      authenticated: true,
      body: {'durationSeconds': durationSeconds, 'answers': answers},
    );
    return HealingCompletionResult.fromJson(_data(response));
  }

  @override
  Future<HealingAudio> fetchAudio(String id) async {
    final response = await _apiClient.get(
      '/healing/audios/$id',
      authenticated: true,
    );
    return HealingAudio.fromJson(_data(response));
  }

  @override
  Future<HealingRitual> fetchRitual(String id) async {
    final response = await _apiClient.get(
      '/healing/rituals/$id',
      authenticated: true,
    );
    return HealingRitual.fromJson(_data(response));
  }

  @override
  Future<HealingExercise> fetchExercise(String id) async {
    final response = await _apiClient.get(
      '/healing/exercises/$id',
      authenticated: true,
    );
    return HealingExercise.fromJson(_data(response));
  }

  @override
  Future<HealingCompletionResult> completeExercise(
    String id, {
    int? durationSeconds,
    Object? answers,
  }) async {
    final response = await _apiClient.post(
      '/healing/exercises/$id/complete',
      authenticated: true,
      body: {'durationSeconds': durationSeconds, 'answers': answers},
    );
    return HealingCompletionResult.fromJson(_data(response));
  }

  @override
  Future<HealingCourse> fetchCourse(String id) async {
    final response = await _apiClient.get(
      '/healing/courses/$id',
      authenticated: true,
    );
    return HealingCourse.fromJson(_data(response));
  }

  @override
  Future<HealingCourseStartResult> startCourse(
    String id, {
    bool replaceActive = false,
  }) async {
    final response = await _apiClient.post(
      '/healing/courses/$id/start',
      authenticated: true,
      body: {'replaceActive': replaceActive},
    );
    return HealingCourseStartResult.fromJson(_data(response));
  }

  @override
  Future<HealingCompletionResult> completeLesson(
    String courseId,
    String lessonId, {
    int? durationSeconds,
    Object? answers,
  }) async {
    final response = await _apiClient.post(
      '/healing/courses/$courseId/lessons/$lessonId/complete',
      authenticated: true,
      body: {'durationSeconds': durationSeconds, 'answers': answers},
    );
    return HealingCompletionResult.fromJson(_data(response));
  }

  @override
  Future<HealingEntryState> fetchEntryState({
    String entry = 'VOLUNTARY',
  }) async {
    final response = await _apiClient.get(
      '/healing/entry?entry=$entry',
      authenticated: true,
    );
    return HealingEntryState.fromJson(_data(response));
  }

  @override
  Future<HealingPlanTimeline> fetchActivePlanTimeline() async {
    final response = await _apiClient.get(
      '/healing/plan/timeline',
      authenticated: true,
    );
    return HealingPlanTimeline.fromJson(_data(response));
  }

  @override
  Future<HealingPlanPreview> fetchRecommendedPlanPreview() async {
    final response = await _apiClient.get(
      '/healing/plan/preview',
      authenticated: true,
    );
    return HealingPlanPreview.fromJson(_data(response));
  }

  @override
  Future<HealingPlanStartResult> startRecommendedPlan() async {
    final response = await _apiClient.post(
      '/healing/plan/start',
      authenticated: true,
    );
    return HealingPlanStartResult.fromJson(_data(response));
  }

  @override
  Future<HealingCompletionResult> completePlanItem(
    String id, {
    required String completionType,
    int? durationSeconds,
    Object? answers,
  }) async {
    final response = await _apiClient.post(
      '/healing/plan/items/$id/complete',
      authenticated: true,
      body: {
        'completionType': completionType,
        'durationSeconds': durationSeconds,
        'answers': answers,
      },
    );
    return HealingCompletionResult.fromJson(_data(response));
  }

  Map<String, dynamic> _data(Map<String, dynamic> response) {
    if (response['success'] != true) {
      throw ApiClientException(
        response['error']?.toString() ?? 'Healing API request failed',
      );
    }

    final data = response['data'];
    if (data == null) return const {};
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }

    throw const ApiClientException('Healing API response is invalid');
  }
}

String _readinessFromIntensity(int intensity) {
  if (intensity >= 7) return 'NOT_READY';
  if (intensity >= 4) return 'EXPLORING';
  return 'READY';
}

List<String> _needsFromMood(String mood) {
  return switch (mood.toUpperCase()) {
    'ANXIOUS' || 'STRESSED' => const ['CALM_DOWN'],
    'SAD' => const ['SELF_COMPASSION'],
    'ANGRY' => const ['COOL_OFF'],
    _ => const ['REFLECTION'],
  };
}

String _smallGoalFromInput(String? note) {
  final trimmed = note?.trim();
  return trimmed?.isNotEmpty == true ? trimmed! : 'Take one gentle step';
}
