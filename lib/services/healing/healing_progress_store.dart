import '../../models/healing/healing_models.dart';

class HealingProgressStore {
  HealingLogSnapshot? _todayMood;
  final Set<String> _completedContentIds = <String>{};
  final Map<String, Set<String>> _completedLessonIdsByCourse =
      <String, Set<String>>{};
  final Map<String, HealingCourseProgress> _courseProgressById =
      <String, HealingCourseProgress>{};

  HealingProgressStore._();

  static final HealingProgressStore instance = HealingProgressStore._();

  HealingLogSnapshot? get todayMood {
    final mood = _todayMood;
    if (mood == null) return null;
    return _isSameLocalDate(mood.createdAt, DateTime.now()) ? mood : null;
  }

  bool get hasTodayCheckin => todayMood != null;

  bool isContentCompleted(String id) => _completedContentIds.contains(id);

  bool isLessonCompleted(String courseId, String lessonId) {
    return _completedLessonIdsByCourse[courseId]?.contains(lessonId) ?? false;
  }

  Set<String> completedLessonIdsFor(String courseId) {
    return Set<String>.from(_completedLessonIdsByCourse[courseId] ?? const {});
  }

  HealingCourseProgress? progressFor(String courseId) {
    return _courseProgressById[courseId];
  }

  void rememberTodayCheckin(HealingLogSnapshot mood) {
    _todayMood = mood;
  }

  void markContentCompleted(String id) {
    if (id.isEmpty) return;
    _completedContentIds.add(id);
  }

  void markLessonCompleted(String courseId, String lessonId) {
    if (courseId.isEmpty || lessonId.isEmpty) return;
    _completedLessonIdsByCourse
        .putIfAbsent(courseId, () => <String>{})
        .add(lessonId);
  }

  void rememberCourseProgress(HealingCourseProgress progress) {
    final existing = _courseProgressById[progress.courseId];
    if (existing == null) {
      _courseProgressById[progress.courseId] = progress;
      return;
    }

    _courseProgressById[progress.courseId] = HealingCourseProgress(
      courseId: progress.courseId,
      status: progress.status == 'COMPLETED'
          ? progress.status
          : existing.status,
      startedAt: progress.startedAt.isNotEmpty
          ? progress.startedAt
          : existing.startedAt,
      currentDay: _max(existing.currentDay, progress.currentDay),
      lastCompletedDay: _max(
        existing.lastCompletedDay,
        progress.lastCompletedDay,
      ),
    );
  }

  void syncCourse(HealingCourse course) {
    final progress = course.progress;
    if (progress != null) {
      rememberCourseProgress(progress);
    }
    for (final lesson in course.lessons) {
      if (lesson.status.toUpperCase() == 'COMPLETED') {
        markLessonCompleted(course.id, lesson.id);
      }
    }
  }

  void clear() {
    _todayMood = null;
    _completedContentIds.clear();
    _completedLessonIdsByCourse.clear();
    _courseProgressById.clear();
  }
}

bool _isSameLocalDate(String isoDate, DateTime now) {
  final parsed = DateTime.tryParse(isoDate);
  if (parsed == null) return true;
  final local = parsed.toLocal();
  return local.year == now.year &&
      local.month == now.month &&
      local.day == now.day;
}

int _max(int a, int b) => a > b ? a : b;
