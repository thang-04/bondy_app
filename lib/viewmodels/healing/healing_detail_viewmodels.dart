import 'package:flutter/foundation.dart';

import '../../core/bondy_error_mapper.dart';
import '../../models/healing/healing_models.dart';
import '../../services/api_client.dart';
import '../../services/healing/healing_progress_store.dart';
import '../../services/healing/healing_service.dart';
import '../../services/analytics_service.dart';

class HealingArticleViewModel extends ChangeNotifier {
  final HealingDataSource _service;
  final HealingProgressStore _progressStore;

  HealingArticle? article;
  bool isLoading = false;
  bool isCompleting = false;
  bool isCompleted = false;
  String? errorMessage;

  HealingArticleViewModel({
    HealingDataSource? service,
    HealingProgressStore? progressStore,
  }) : _service = service ?? HealingService(),
       _progressStore = progressStore ?? HealingProgressStore.instance;

  Future<void> loadArticle(String id) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      article = await _service.fetchArticle(id);
      isCompleted = _progressStore.isContentCompleted(article!.id);
    } catch (error) {
      errorMessage = BondyErrorMapper.message(error);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> complete() async {
    final current = article;
    if (current == null || isCompleted) return;

    isCompleting = true;
    errorMessage = null;
    notifyListeners();

    try {
      // Trước đây chỉ mark local store, refresh app là mất tiến độ. Giờ gọi
      // POST /healing/articles/[id]/complete để server lưu lại HealingContentLog
      // — local store vẫn được mark sau khi server confirm để UI mượt.
      await _service.completeArticle(current.id);
      _progressStore.markContentCompleted(current.id);
      isCompleted = true;
    } catch (error) {
      errorMessage = BondyErrorMapper.message(error);
    } finally {
      isCompleting = false;
      notifyListeners();
    }
  }
}

class HealingExerciseViewModel extends ChangeNotifier {
  final HealingDataSource _service;
  final HealingProgressStore _progressStore;

  HealingExercise? exercise;
  bool isLoading = false;
  bool isCompleting = false;
  bool isCompleted = false;
  String? errorMessage;

  HealingExerciseViewModel({
    HealingDataSource? service,
    HealingProgressStore? progressStore,
  }) : _service = service ?? HealingService(),
       _progressStore = progressStore ?? HealingProgressStore.instance;

  Future<void> loadExercise(String id) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      exercise = await _service.fetchExercise(id);
      isCompleted = _progressStore.isContentCompleted(exercise!.id);
    } catch (error) {
      errorMessage = BondyErrorMapper.message(error);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> complete({int? durationSeconds, Object? answers}) async {
    final current = exercise;
    if (current == null || isCompleted) return;

    isCompleting = true;
    errorMessage = null;
    notifyListeners();

    try {
      final result = await _service.completeExercise(
        current.id,
        durationSeconds: durationSeconds,
        answers: answers,
      );
      isCompleted = result.completed;
      if (result.completed) {
        _progressStore.markContentCompleted(current.id);
      }
    } catch (error) {
      errorMessage = BondyErrorMapper.message(error);
    } finally {
      isCompleting = false;
      notifyListeners();
    }
  }
}

class HealingCourseViewModel extends ChangeNotifier {
  final HealingDataSource _service;
  final HealingProgressStore _progressStore;

  HealingCourse? course;
  final Set<String> _completedLessonIds = <String>{};
  bool isLoading = false;
  bool isMutating = false;
  String? errorMessage;

  HealingCourseViewModel({
    HealingDataSource? service,
    HealingProgressStore? progressStore,
  }) : _service = service ?? HealingService(),
       _progressStore = progressStore ?? HealingProgressStore.instance;

  bool isLessonCompleted(HealingCourseLesson lesson) {
    final courseId = course?.id;
    return _completedLessonIds.contains(lesson.id) ||
        (courseId != null &&
            _progressStore.isLessonCompleted(courseId, lesson.id)) ||
        lesson.status.toUpperCase() == 'COMPLETED';
  }

  bool get isCourseCompleted {
    final current = course;
    if (current == null) return false;
    if (current.progress?.status.toUpperCase() == 'COMPLETED') return true;
    return current.lessons.isNotEmpty &&
        current.lessons.every(isLessonCompleted);
  }

  Future<void> loadCourse(String id) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    if (id.trim().isEmpty) {
      // Trước đây screen fallback về course mặc định khi thiếu id → user
      // không biết mình đang xem nhầm course. Giờ báo lỗi rõ để gọi screen
      // điều hướng lại.
      errorMessage = 'Thiếu mã lộ trình. Vui lòng mở từ màn hình đề xuất.';
      isLoading = false;
      notifyListeners();
      return;
    }

    try {
      course = _withStoredProgress(await _service.fetchCourse(id));
    } catch (error) {
      errorMessage = BondyErrorMapper.message(error);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> startCourse({bool replaceActive = false}) async {
    final current = course;
    if (current == null) return;

    isMutating = true;
    errorMessage = null;
    notifyListeners();

    try {
      final result = await _service.startCourse(
        current.id,
        replaceActive: replaceActive,
      );
      final progress = _progressFromObject(result.progress, current.progress);
      if (progress != null) {
        _progressStore.rememberCourseProgress(progress);
      }
      course = _withStoredProgress(await _service.fetchCourse(current.id));
      analytics.healingCourseStarted(current.id);
    } catch (error) {
      if (error is ApiClientException &&
          error.code == 'ACTIVE_COURSE_CONFIRMATION_REQUIRED') {
        rethrow;
      }
      errorMessage = BondyErrorMapper.message(error);
    } finally {
      isMutating = false;
      notifyListeners();
    }
  }

  Future<void> completeLesson(HealingCourseLesson lesson) async {
    final current = course;
    if (current == null || lesson.isLocked || isLessonCompleted(lesson)) return;

    isMutating = true;
    errorMessage = null;
    notifyListeners();

    try {
      final result = await _service.completeLesson(current.id, lesson.id);
      _completedLessonIds.add(lesson.id);
      _progressStore.markLessonCompleted(current.id, lesson.id);
      if (lesson.articleContentId?.isNotEmpty == true) {
        _progressStore.markContentCompleted(lesson.articleContentId!);
      }
      if (lesson.exerciseContentId?.isNotEmpty == true) {
        _progressStore.markContentCompleted(lesson.exerciseContentId!);
      }

      final progress = _progressAfterLessonComplete(
        current,
        lesson,
        result.progress,
      );
      if (progress != null) {
        _progressStore.rememberCourseProgress(progress);
      }
      course = _withStoredProgress(await _service.fetchCourse(current.id));
    } catch (error) {
      errorMessage = BondyErrorMapper.message(error);
    } finally {
      isMutating = false;
      notifyListeners();
    }
  }

  HealingCourse _withStoredProgress(HealingCourse source) {
    _progressStore.syncCourse(source);

    final completedIds = _progressStore.completedLessonIdsFor(source.id)
      ..addAll(_completedLessonIds);
    final progress = _progressWithCompletedLessons(
      source,
      _progressStore.progressFor(source.id) ?? source.progress,
      completedIds,
    );
    if (progress != null) {
      _progressStore.rememberCourseProgress(progress);
    }

    final lessons = source.lessons.map((lesson) {
      final completed =
          completedIds.contains(lesson.id) ||
          lesson.status.toUpperCase() == 'COMPLETED';
      final shouldUnlock =
          progress != null && progress.currentDay >= lesson.dayNumber;
      return _copyLesson(
        lesson,
        status: completed
            ? 'COMPLETED'
            : shouldUnlock && lesson.status.toUpperCase() == 'LOCKED'
            ? 'AVAILABLE'
            : lesson.status,
        isLocked: completed ? false : lesson.isLocked && !shouldUnlock,
      );
    }).toList();

    return _copyCourse(source, progress: progress, lessons: lessons);
  }
}

HealingCourseProgress? _progressAfterLessonComplete(
  HealingCourse course,
  HealingCourseLesson lesson,
  Object? resultProgress,
) {
  final parsed = _progressFromObject(resultProgress, course.progress);
  final completedIds = <String>{lesson.id};
  return _progressWithCompletedLessons(
    course,
    parsed ?? course.progress,
    completedIds,
  );
}

HealingCourseProgress? _progressWithCompletedLessons(
  HealingCourse course,
  HealingCourseProgress? base,
  Set<String> completedLessonIds,
) {
  var lastCompletedDay = base?.lastCompletedDay ?? 0;
  for (final lesson in course.lessons) {
    if (completedLessonIds.contains(lesson.id) ||
        lesson.status.toUpperCase() == 'COMPLETED') {
      lastCompletedDay = _max(lastCompletedDay, lesson.dayNumber);
    }
  }

  if (base == null && lastCompletedDay == 0) return null;

  final totalDays = _totalDaysFor(course);
  var currentDay = base?.currentDay ?? 1;
  if (lastCompletedDay > 0) {
    currentDay = _max(currentDay, lastCompletedDay + 1);
  }
  if (totalDays > 0 && currentDay > totalDays) {
    currentDay = totalDays;
  }

  final allLessonsCompleted =
      course.lessons.isNotEmpty &&
      course.lessons.every(
        (lesson) =>
            completedLessonIds.contains(lesson.id) ||
            lesson.status.toUpperCase() == 'COMPLETED',
      );

  return HealingCourseProgress(
    courseId: course.id,
    status:
        allLessonsCompleted || (totalDays > 0 && lastCompletedDay >= totalDays)
        ? 'COMPLETED'
        : base?.status ?? 'IN_PROGRESS',
    startedAt: base?.startedAt ?? DateTime.now().toIso8601String(),
    currentDay: currentDay,
    lastCompletedDay: lastCompletedDay,
  );
}

HealingCourseProgress? _progressFromObject(
  Object? value,
  HealingCourseProgress? fallback,
) {
  final data = _objectMap(value);
  if (data.isEmpty) return fallback;
  return HealingCourseProgress.fromJson({
    'courseId': data['courseId'] ?? fallback?.courseId,
    'status': data['status'] ?? fallback?.status ?? 'IN_PROGRESS',
    'startedAt':
        data['startedAt'] ??
        fallback?.startedAt ??
        DateTime.now().toIso8601String(),
    'currentDay': data['currentDay'] ?? fallback?.currentDay ?? 1,
    'lastCompletedDay':
        data['lastCompletedDay'] ?? fallback?.lastCompletedDay ?? 0,
  });
}

Map<String, dynamic> _objectMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  return const {};
}

HealingCourse _copyCourse(
  HealingCourse source, {
  HealingCourseProgress? progress,
  List<HealingCourseLesson>? lessons,
}) {
  return HealingCourse(
    id: source.id,
    title: source.title,
    summary: source.summary,
    accessLevel: source.accessLevel,
    durationDays: source.durationDays,
    goal: source.goal,
    scheduleType: source.scheduleType,
    progress: progress,
    lessons: lessons ?? source.lessons,
  );
}

HealingCourseLesson _copyLesson(
  HealingCourseLesson source, {
  String? status,
  bool? isLocked,
}) {
  return HealingCourseLesson(
    id: source.id,
    dayNumber: source.dayNumber,
    title: source.title,
    articleContentId: source.articleContentId,
    exerciseContentId: source.exerciseContentId,
    reflectionPrompt: source.reflectionPrompt,
    estimatedMinutes: source.estimatedMinutes,
    unlockRule: source.unlockRule,
    status: status ?? source.status,
    isLocked: isLocked ?? source.isLocked,
  );
}

int _totalDaysFor(HealingCourse course) {
  var total = course.durationDays;
  for (final lesson in course.lessons) {
    total = _max(total, lesson.dayNumber);
  }
  return total;
}

int _max(int a, int b) => a > b ? a : b;
