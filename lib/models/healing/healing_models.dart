import '../../core/media_url.dart';

Map<String, dynamic> _mapFrom(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  return const {};
}

List<Map<String, dynamic>> _mapListFrom(Object? value) {
  if (value is! List) return const [];
  return value.map(_mapFrom).where((item) => item.isNotEmpty).toList();
}

List<String> _stringListFrom(Object? value) {
  if (value is! List) return const [];
  return value.map((item) => item.toString()).toList();
}

String _stringFrom(Object? value, [String fallback = '']) {
  return value?.toString() ?? fallback;
}

int _intFrom(Object? value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

int? _nullableIntFrom(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

bool _boolFrom(Object? value, [bool fallback = false]) {
  if (value is bool) return value;
  if (value is String) return value.toLowerCase() == 'true';
  return fallback;
}

class HealingContentPreview {
  final String id;
  final String type;
  final String sourceType;
  final String title;
  final String summary;
  final String? thumbnailUrl;
  final String category;
  final List<String> tags;
  final List<String> moodTargets;
  final List<String> contextTargets;
  final String accessLevel;
  final int? estimatedMinutes;
  final int? durationDays;
  final bool isLocked;

  const HealingContentPreview({
    required this.id,
    required this.type,
    required this.sourceType,
    required this.title,
    required this.summary,
    required this.thumbnailUrl,
    required this.category,
    required this.tags,
    required this.moodTargets,
    required this.contextTargets,
    required this.accessLevel,
    required this.estimatedMinutes,
    required this.durationDays,
    required this.isLocked,
  });

  factory HealingContentPreview.fromJson(Map<String, dynamic> json) {
    return HealingContentPreview(
      id: _stringFrom(json['id']),
      type: _stringFrom(json['type']),
      sourceType: _stringFrom(json['sourceType']),
      title: _stringFrom(json['title'], 'Healing content'),
      summary: _stringFrom(json['summary']),
      thumbnailUrl: rewriteMediaUrl(json['thumbnailUrl']?.toString()),
      category: _stringFrom(json['category']),
      tags: _stringListFrom(json['tags']),
      moodTargets: _stringListFrom(json['moodTargets']),
      contextTargets: _stringListFrom(json['contextTargets']),
      accessLevel: _stringFrom(json['accessLevel'], 'FREE'),
      estimatedMinutes: _nullableIntFrom(json['estimatedMinutes']),
      durationDays: _nullableIntFrom(json['durationDays']),
      isLocked: _boolFrom(json['isLocked']),
    );
  }
}

class HealingFlowStateData {
  final bool isFirstTime;
  final bool hasInProgress;
  final bool hasTodayCheckin;
  final String primaryIntent;
  final String topBlock;

  const HealingFlowStateData({
    required this.isFirstTime,
    required this.hasInProgress,
    required this.hasTodayCheckin,
    required this.primaryIntent,
    required this.topBlock,
  });

  factory HealingFlowStateData.fromJson(Map<String, dynamic> json) {
    return HealingFlowStateData(
      isFirstTime: _boolFrom(json['isFirstTime']),
      hasInProgress: _boolFrom(json['hasInProgress']),
      hasTodayCheckin: _boolFrom(json['hasTodayCheckin']),
      primaryIntent: _stringFrom(json['primaryIntent'], 'REFLECT'),
      topBlock: _stringFrom(json['topBlock'], 'START_PATH'),
    );
  }
}

class HealingLogSnapshot {
  final String mood;
  final int intensity;
  final String? context;
  final String readiness;
  final List<String> needs;
  final String? smallGoal;
  final String source;
  final String createdAt;

  const HealingLogSnapshot({
    required this.mood,
    required this.intensity,
    required this.context,
    required this.readiness,
    required this.needs,
    required this.smallGoal,
    required this.source,
    required this.createdAt,
  });

  factory HealingLogSnapshot.fromJson(Map<String, dynamic> json) {
    final readiness = _stringFrom(json['readiness']);
    return HealingLogSnapshot(
      mood: _stringFrom(json['mood']),
      intensity: _intFrom(
        json['intensity'],
        _intensityFromReadiness(readiness),
      ),
      context: json['context']?.toString() ?? json['trigger']?.toString(),
      readiness: readiness,
      needs: _stringListFrom(json['needs']),
      smallGoal: json['smallGoal']?.toString(),
      source: _stringFrom(json['source']),
      createdAt: _stringFrom(json['createdAt']),
    );
  }
}

class ActiveHealingCourseSnapshot {
  final String courseId;
  final String status;
  final String startedAt;
  final int currentDay;
  final int lastCompletedDay;

  const ActiveHealingCourseSnapshot({
    required this.courseId,
    required this.status,
    required this.startedAt,
    required this.currentDay,
    required this.lastCompletedDay,
  });

  factory ActiveHealingCourseSnapshot.fromJson(Map<String, dynamic> json) {
    return ActiveHealingCourseSnapshot(
      courseId: _stringFrom(json['courseId']),
      status: _stringFrom(json['status']),
      startedAt: _stringFrom(json['startedAt']),
      currentDay: _intFrom(json['currentDay'], 1),
      lastCompletedDay: _intFrom(json['lastCompletedDay']),
    );
  }
}

class HealingRecommendation {
  final HealingContentPreview? article;
  final HealingContentPreview? exercise;
  final HealingContentPreview? course;
  final String reflectionPrompt;

  const HealingRecommendation({
    required this.article,
    required this.exercise,
    required this.course,
    required this.reflectionPrompt,
  });

  factory HealingRecommendation.fromJson(Map<String, dynamic> json) {
    final article = _mapFrom(json['article']);
    final exercise = _mapFrom(json['exercise']);
    final course = _mapFrom(json['course']);
    return HealingRecommendation(
      article: article.isEmpty ? null : HealingContentPreview.fromJson(article),
      exercise: exercise.isEmpty
          ? null
          : HealingContentPreview.fromJson(exercise),
      course: course.isEmpty ? null : HealingContentPreview.fromJson(course),
      reflectionPrompt: _stringFrom(json['reflectionPrompt']),
    );
  }
}

class HealingHomeSections {
  final List<HealingContentPreview> articles;
  final List<HealingContentPreview> exercises;
  final List<HealingContentPreview> audios;
  final List<HealingContentPreview> rituals;
  final List<HealingContentPreview> courses;

  const HealingHomeSections({
    required this.articles,
    required this.exercises,
    required this.audios,
    required this.rituals,
    required this.courses,
  });

  factory HealingHomeSections.fromJson(Map<String, dynamic> json) {
    return HealingHomeSections(
      articles: _mapListFrom(
        json['articles'],
      ).map(HealingContentPreview.fromJson).toList(),
      exercises: _mapListFrom(
        json['exercises'],
      ).map(HealingContentPreview.fromJson).toList(),
      audios: _mapListFrom(
        json['audios'],
      ).map(HealingContentPreview.fromJson).toList(),
      rituals: _mapListFrom(
        json['rituals'],
      ).map(HealingContentPreview.fromJson).toList(),
      courses: _mapListFrom(
        json['courses'],
      ).map(HealingContentPreview.fromJson).toList(),
    );
  }
}

class HealingHomeData {
  final HealingFlowStateData flowState;
  final HealingLogSnapshot? todayMood;
  final HealingRecommendation todayForYou;
  final ActiveHealingCourseSnapshot? continueJourney;
  final HealingPlanPreview? recommendedPlan;
  final HealingPlanTimeline? activePlanSummary;
  final List<HealingLogSnapshot> journalPreview;
  final HealingHomeSections sections;
  final String? fallbackNotice;

  const HealingHomeData({
    required this.flowState,
    required this.todayMood,
    required this.todayForYou,
    required this.continueJourney,
    required this.recommendedPlan,
    required this.activePlanSummary,
    required this.journalPreview,
    required this.sections,
    required this.fallbackNotice,
  });

  factory HealingHomeData.fromJson(Map<String, dynamic> json) {
    final todayMood = _mapFrom(json['todayMood']).isNotEmpty
        ? _mapFrom(json['todayMood'])
        : _mapFrom(json['todayCheckin']);
    final continueJourney = _mapFrom(json['continueJourney']);
    final recommendedPlan = _mapFrom(json['recommendedPlan']);
    final activePlanSummary = _mapFrom(json['activePlanSummary']);
    final sections = _mapFrom(json['sections']).isNotEmpty
        ? _mapFrom(json['sections'])
        : {
            'articles': json['articles'],
            'exercises': json['exercises'],
            'audios': json['audios'],
            'rituals': json['rituals'],
            'courses': json['courses'],
          };
    return HealingHomeData(
      flowState: HealingFlowStateData.fromJson(_mapFrom(json['flowState'])),
      todayMood: todayMood.isEmpty
          ? null
          : HealingLogSnapshot.fromJson(todayMood),
      todayForYou: HealingRecommendation.fromJson(
        _mapFrom(json['todayForYou']),
      ),
      continueJourney: continueJourney.isEmpty
          ? null
          : ActiveHealingCourseSnapshot.fromJson(continueJourney),
      recommendedPlan: recommendedPlan.isEmpty
          ? null
          : HealingPlanPreview.fromJson(recommendedPlan),
      activePlanSummary: activePlanSummary.isEmpty
          ? null
          : HealingPlanTimeline.fromJson(activePlanSummary),
      journalPreview: _mapListFrom(
        json['journalPreview'],
      ).map(HealingLogSnapshot.fromJson).toList(),
      sections: HealingHomeSections.fromJson(sections),
      fallbackNotice: json['fallbackNotice']?.toString(),
    );
  }
}

class HealingArticle {
  final String id;
  final String type;
  final String sourceType;
  final String title;
  final String summary;
  final String? thumbnailUrl;
  final String category;
  final List<String> tags;
  final List<String> moodTargets;
  final List<String> contextTargets;
  final String accessLevel;
  final String language;
  final String reviewStatus;
  final bool isPublished;
  final String body;
  final int estimatedReadMinutes;
  final String authorName;
  final String? sourceName;
  final String? externalUrl;
  final String? copyrightNote;
  final bool isExternalPreview;
  final String whySuggested;

  const HealingArticle({
    required this.id,
    required this.type,
    required this.sourceType,
    required this.title,
    required this.summary,
    required this.thumbnailUrl,
    required this.category,
    required this.tags,
    required this.moodTargets,
    required this.contextTargets,
    required this.accessLevel,
    required this.language,
    required this.reviewStatus,
    required this.isPublished,
    required this.body,
    required this.estimatedReadMinutes,
    required this.authorName,
    required this.sourceName,
    required this.externalUrl,
    required this.copyrightNote,
    required this.isExternalPreview,
    required this.whySuggested,
  });

  factory HealingArticle.fromJson(Map<String, dynamic> json) {
    return HealingArticle(
      id: _stringFrom(json['id']),
      type: _stringFrom(json['type'], 'ARTICLE'),
      sourceType: _stringFrom(json['sourceType']),
      title: _stringFrom(json['title'], 'Healing article'),
      summary: _stringFrom(json['summary']),
      thumbnailUrl: rewriteMediaUrl(json['thumbnailUrl']?.toString()),
      category: _stringFrom(json['category']),
      tags: _stringListFrom(json['tags']),
      moodTargets: _stringListFrom(json['moodTargets']),
      contextTargets: _stringListFrom(json['contextTargets']),
      accessLevel: _stringFrom(json['accessLevel'], 'FREE'),
      language: _stringFrom(json['language'], 'vi'),
      reviewStatus: _stringFrom(json['reviewStatus'], 'APPROVED'),
      isPublished: _boolFrom(json['isPublished'], true),
      body: _stringFrom(json['body']),
      estimatedReadMinutes: _intFrom(json['estimatedReadMinutes']),
      authorName: _stringFrom(json['authorName'], 'Bondy'),
      sourceName: json['sourceName']?.toString(),
      externalUrl: json['externalUrl']?.toString(),
      copyrightNote: json['copyrightNote']?.toString(),
      isExternalPreview: _boolFrom(
        json['isExternalPreview'],
        _stringFrom(json['sourceType']) == 'EXTERNAL',
      ),
      whySuggested: _stringFrom(json['whySuggested']),
    );
  }
}

class HealingAudio {
  final String id;
  final String title;
  final String summary;
  final String? thumbnailUrl;
  final String category;
  final String audioUrl;
  final int durationSeconds;
  final String? transcript;
  final String? narratorName;

  const HealingAudio({
    required this.id,
    required this.title,
    required this.summary,
    required this.thumbnailUrl,
    required this.category,
    required this.audioUrl,
    required this.durationSeconds,
    required this.transcript,
    required this.narratorName,
  });

  factory HealingAudio.fromJson(Map<String, dynamic> json) {
    return HealingAudio(
      id: _stringFrom(json['id']),
      title: _stringFrom(json['title'], 'Audio session'),
      summary: _stringFrom(json['summary']),
      thumbnailUrl: rewriteMediaUrl(json['thumbnailUrl']?.toString()),
      category: _stringFrom(json['category']),
      audioUrl: rewriteMediaUrl(_stringFrom(json['audioUrl'])) ?? '',
      durationSeconds: _intFrom(json['durationSeconds'], 900),
      transcript: json['transcript']?.toString(),
      narratorName: json['narratorName']?.toString(),
    );
  }
}

class HealingRitual {
  final String id;
  final String title;
  final String summary;
  final String? thumbnailUrl;
  final String category;
  final String? readingContentId;
  final String? audioContentId;
  final int durationMinutes;
  final String? completionPrompt;

  const HealingRitual({
    required this.id,
    required this.title,
    required this.summary,
    required this.thumbnailUrl,
    required this.category,
    required this.readingContentId,
    required this.audioContentId,
    required this.durationMinutes,
    required this.completionPrompt,
  });

  factory HealingRitual.fromJson(Map<String, dynamic> json) {
    return HealingRitual(
      id: _stringFrom(json['id']),
      title: _stringFrom(json['title'], 'Bài ritual'),
      summary: _stringFrom(json['summary']),
      thumbnailUrl: rewriteMediaUrl(json['thumbnailUrl']?.toString()),
      category: _stringFrom(json['category']),
      readingContentId: json['readingContentId']?.toString(),
      audioContentId: json['audioContentId']?.toString(),
      durationMinutes: _intFrom(json['durationMinutes'], 5),
      completionPrompt: json['completionPrompt']?.toString(),
    );
  }
}

class HealingExercise {
  final String id;
  final String title;
  final String summary;
  final String exerciseType;
  final int durationMinutes;
  final String difficulty;
  final List<String> steps;
  final String completionCriteria;
  final String? safetyNote;

  const HealingExercise({
    required this.id,
    required this.title,
    required this.summary,
    required this.exerciseType,
    required this.durationMinutes,
    required this.difficulty,
    required this.steps,
    required this.completionCriteria,
    required this.safetyNote,
  });

  factory HealingExercise.fromJson(Map<String, dynamic> json) {
    return HealingExercise(
      id: _stringFrom(json['id']),
      title: _stringFrom(json['title'], 'Healing exercise'),
      summary: _stringFrom(json['summary']),
      exerciseType: _stringFrom(json['exerciseType']),
      durationMinutes: _intFrom(json['durationMinutes']),
      difficulty: _stringFrom(json['difficulty'], 'EASY'),
      steps: _stringListFrom(json['steps']),
      completionCriteria: _stringFrom(json['completionCriteria']),
      safetyNote: json['safetyNote']?.toString(),
    );
  }
}

class HealingCourseProgress {
  final String courseId;
  final String status;
  final String startedAt;
  final int currentDay;
  final int lastCompletedDay;

  const HealingCourseProgress({
    required this.courseId,
    required this.status,
    required this.startedAt,
    required this.currentDay,
    required this.lastCompletedDay,
  });

  factory HealingCourseProgress.fromJson(Map<String, dynamic> json) {
    return HealingCourseProgress(
      courseId: _stringFrom(json['courseId']),
      status: _stringFrom(json['status']),
      startedAt: _stringFrom(json['startedAt']),
      currentDay: _intFrom(json['currentDay'], 1),
      lastCompletedDay: _intFrom(json['lastCompletedDay']),
    );
  }
}

class HealingCourseLesson {
  final String id;
  final int dayNumber;
  final String title;
  final String? articleContentId;
  final String? exerciseContentId;
  final String? reflectionPrompt;
  final int estimatedMinutes;
  final String unlockRule;
  final String status;
  final bool isLocked;

  const HealingCourseLesson({
    required this.id,
    required this.dayNumber,
    required this.title,
    required this.articleContentId,
    required this.exerciseContentId,
    required this.reflectionPrompt,
    required this.estimatedMinutes,
    required this.unlockRule,
    required this.status,
    required this.isLocked,
  });

  factory HealingCourseLesson.fromJson(Map<String, dynamic> json) {
    return HealingCourseLesson(
      id: _stringFrom(json['id']),
      dayNumber: _intFrom(json['dayNumber']),
      title: _stringFrom(json['title'], 'Lesson'),
      articleContentId: json['articleContentId']?.toString(),
      exerciseContentId: json['exerciseContentId']?.toString(),
      reflectionPrompt: json['reflectionPrompt']?.toString(),
      estimatedMinutes: _intFrom(json['estimatedMinutes']),
      unlockRule: _stringFrom(json['unlockRule'], 'IMMEDIATE'),
      status: _stringFrom(json['status'], 'AVAILABLE'),
      isLocked: _boolFrom(json['isLocked']),
    );
  }
}

class HealingCourse {
  final String id;
  final String title;
  final String summary;
  final String accessLevel;
  final int durationDays;
  final String goal;
  final String scheduleType;
  final HealingCourseProgress? progress;
  final List<HealingCourseLesson> lessons;

  const HealingCourse({
    required this.id,
    required this.title,
    required this.summary,
    required this.accessLevel,
    required this.durationDays,
    required this.goal,
    required this.scheduleType,
    required this.progress,
    required this.lessons,
  });

  factory HealingCourse.fromJson(Map<String, dynamic> json) {
    final progress = _mapFrom(json['progress']);
    return HealingCourse(
      id: _stringFrom(json['id']),
      title: _stringFrom(json['title'], 'Healing course'),
      summary: _stringFrom(json['summary']),
      accessLevel: _stringFrom(json['accessLevel'], 'FREE'),
      durationDays: _intFrom(json['durationDays']),
      goal: _stringFrom(json['goal']),
      scheduleType: _stringFrom(json['scheduleType']),
      progress: progress.isEmpty
          ? null
          : HealingCourseProgress.fromJson(progress),
      lessons: _mapListFrom(
        json['lessons'],
      ).map(HealingCourseLesson.fromJson).toList(),
    );
  }
}

class HealingRecoveryBundle {
  final String primaryIntent;
  final String acknowledgement;
  final String groundingMessage;
  final String? safetyMessage;
  final HealingContentPreview? suggestedExercise;
  final HealingContentPreview? suggestedArticle;
  final HealingContentPreview? suggestedCourse;
  final String reflectionPrompt;
  final List<String> exitActions;

  const HealingRecoveryBundle({
    required this.primaryIntent,
    required this.acknowledgement,
    required this.groundingMessage,
    required this.safetyMessage,
    required this.suggestedExercise,
    required this.suggestedArticle,
    required this.suggestedCourse,
    required this.reflectionPrompt,
    required this.exitActions,
  });

  factory HealingRecoveryBundle.fromJson(Map<String, dynamic> json) {
    final exercise = _mapFrom(json['suggestedExercise']);
    final article = _mapFrom(json['suggestedArticle']);
    final course = _mapFrom(json['suggestedCourse']);
    return HealingRecoveryBundle(
      primaryIntent: _stringFrom(json['primaryIntent'], 'REFLECT'),
      acknowledgement: _stringFrom(json['acknowledgement']),
      groundingMessage: _stringFrom(json['groundingMessage']),
      safetyMessage: json['safetyMessage']?.toString(),
      suggestedExercise: exercise.isEmpty
          ? null
          : HealingContentPreview.fromJson(exercise),
      suggestedArticle: article.isEmpty
          ? null
          : HealingContentPreview.fromJson(article),
      suggestedCourse: course.isEmpty
          ? null
          : HealingContentPreview.fromJson(course),
      reflectionPrompt: _stringFrom(json['reflectionPrompt']),
      exitActions: _stringListFrom(json['exitActions']),
    );
  }
}

class HealingCheckinResult {
  final Object? emotionalLog;
  final bool persisted;
  final String routeAfterCheckin;
  final HealingRecoveryBundle recoveryBundle;

  const HealingCheckinResult({
    required this.emotionalLog,
    required this.persisted,
    required this.routeAfterCheckin,
    required this.recoveryBundle,
  });

  factory HealingCheckinResult.fromJson(Map<String, dynamic> json) {
    return HealingCheckinResult(
      emotionalLog: json['emotionalLog'],
      persisted: _boolFrom(json['persisted']),
      routeAfterCheckin: _stringFrom(json['routeAfterCheckin']),
      recoveryBundle: HealingRecoveryBundle.fromJson(
        _mapFrom(json['recoveryBundle']),
      ),
    );
  }
}

class HealingCompletionResult {
  final bool completed;
  final Object? completion;
  final Object? progress;

  const HealingCompletionResult({
    required this.completed,
    required this.completion,
    required this.progress,
  });

  factory HealingCompletionResult.fromJson(Map<String, dynamic> json) {
    return HealingCompletionResult(
      completed: _boolFrom(json['completed']),
      completion: json['completion'],
      progress: json['progress'],
    );
  }
}

class HealingCourseStartResult {
  final bool started;
  final Object? progress;
  final HealingContentPreview? course;

  const HealingCourseStartResult({
    required this.started,
    required this.progress,
    required this.course,
  });

  factory HealingCourseStartResult.fromJson(Map<String, dynamic> json) {
    final course = _mapFrom(json['course']);
    return HealingCourseStartResult(
      started: _boolFrom(json['started']),
      progress: json['progress'],
      course: course.isEmpty ? null : HealingContentPreview.fromJson(course),
    );
  }
}

class HealingEntryState {
  final String entry;
  final bool requiresAssessment;
  final String? assessmentType;
  final Map<String, dynamic>? assessment;
  final HealingPlanPreview? recommendedPlan;
  final Map<String, dynamic>? assignment;

  const HealingEntryState({
    required this.entry,
    required this.requiresAssessment,
    required this.assessmentType,
    required this.assessment,
    required this.recommendedPlan,
    required this.assignment,
  });

  factory HealingEntryState.fromJson(Map<String, dynamic> json) {
    final assessment = _mapFrom(json['assessment']);
    final recommendedPlan = _mapFrom(json['recommendedPlan']);
    final assignment = _mapFrom(json['assignment']);
    return HealingEntryState(
      entry: _stringFrom(json['entry'], 'VOLUNTARY'),
      requiresAssessment: _boolFrom(json['requiresAssessment']),
      assessmentType: json['assessmentType']?.toString(),
      assessment: assessment.isEmpty ? null : assessment,
      recommendedPlan: recommendedPlan.isEmpty
          ? null
          : HealingPlanPreview.fromJson(recommendedPlan),
      assignment: assignment.isEmpty ? null : assignment,
    );
  }
}

class HealingPlanDayTimeline {
  final String? id;
  final int dayNumber;
  final String title;
  final String? articleContentId;
  final String? exerciseContentId;
  final String? audioContentId;
  final String? ritualContentId;
  final String? reflectionPrompt;
  final int? estimatedMinutes;
  final bool isUnlocked;
  final bool isCompleted;
  final List<HealingPlanTimelineItem> items;

  const HealingPlanDayTimeline({
    required this.id,
    required this.dayNumber,
    required this.title,
    required this.articleContentId,
    required this.exerciseContentId,
    required this.audioContentId,
    required this.ritualContentId,
    required this.reflectionPrompt,
    required this.estimatedMinutes,
    required this.isUnlocked,
    required this.isCompleted,
    required this.items,
  });

  factory HealingPlanDayTimeline.fromJson(Map<String, dynamic> json) {
    return HealingPlanDayTimeline(
      id: json['id']?.toString(),
      dayNumber: _intFrom(json['dayNumber']),
      title: _stringFrom(json['title']),
      articleContentId: json['articleContentId']?.toString(),
      exerciseContentId: json['exerciseContentId']?.toString(),
      audioContentId: json['audioContentId']?.toString(),
      ritualContentId: json['ritualContentId']?.toString(),
      reflectionPrompt: json['reflectionPrompt']?.toString(),
      estimatedMinutes: _nullableIntFrom(json['estimatedMinutes']),
      isUnlocked: _boolFrom(json['isUnlocked']),
      isCompleted: _boolFrom(json['isCompleted']),
      items: _mapListFrom(
        json['items'],
      ).map(HealingPlanTimelineItem.fromJson).toList(),
    );
  }
}

class HealingPlanTimelineItem {
  final String type;
  final String contentId;
  // Server now resolves title + estimatedMinutes from seed content so the
  // plan-day bottom sheet can render meaningful labels (Bug 2 fix).
  final String? title;
  final int? estimatedMinutes;
  final bool isCompleted;

  const HealingPlanTimelineItem({
    required this.type,
    required this.contentId,
    required this.title,
    required this.estimatedMinutes,
    required this.isCompleted,
  });

  factory HealingPlanTimelineItem.fromJson(Map<String, dynamic> json) {
    return HealingPlanTimelineItem(
      type: _stringFrom(json['type']),
      contentId: _stringFrom(json['contentId']),
      title: json['title']?.toString(),
      estimatedMinutes: _nullableIntFrom(json['estimatedMinutes']),
      isCompleted: _boolFrom(json['isCompleted']),
    );
  }
}

class HealingPlanTimeline {
  final String assignmentId;
  final String templateId;
  final String title;
  final String description;
  final int durationDays;
  final int currentDay;
  final int lastCompletedDay;
  final int progressPercent;
  final List<HealingPlanDayTimeline> days;

  const HealingPlanTimeline({
    required this.assignmentId,
    required this.templateId,
    required this.title,
    required this.description,
    required this.durationDays,
    required this.currentDay,
    required this.lastCompletedDay,
    required this.progressPercent,
    required this.days,
  });

  factory HealingPlanTimeline.fromJson(Map<String, dynamic> json) {
    return HealingPlanTimeline(
      assignmentId: _stringFrom(json['assignmentId']),
      templateId: _stringFrom(json['templateId']),
      title: _stringFrom(json['title']),
      description: _stringFrom(json['description']),
      durationDays: _intFrom(json['durationDays']),
      currentDay: _intFrom(json['currentDay'], 1),
      lastCompletedDay: _intFrom(json['lastCompletedDay']),
      progressPercent: _intFrom(json['progressPercent']),
      days: _mapListFrom(json['days'])
          .map(HealingPlanDayTimeline.fromJson)
          .toList(),
    );
  }
}

class HealingPlanPreview {
  final String templateId;
  final String title;
  final String description;
  final int durationDays;
  final int? currentDay;
  final int lastCompletedDay;
  final int progressPercent;
  final List<HealingPlanDayTimeline> days;

  const HealingPlanPreview({
    required this.templateId,
    required this.title,
    required this.description,
    required this.durationDays,
    required this.currentDay,
    required this.lastCompletedDay,
    required this.progressPercent,
    required this.days,
  });

  factory HealingPlanPreview.fromJson(Map<String, dynamic> json) {
    return HealingPlanPreview(
      templateId: _stringFrom(json['templateId']),
      title: _stringFrom(json['title']),
      description: _stringFrom(json['description']),
      durationDays: _intFrom(json['durationDays']),
      currentDay: _nullableIntFrom(json['currentDay']),
      lastCompletedDay: _intFrom(json['lastCompletedDay']),
      progressPercent: _intFrom(json['progressPercent']),
      days: _mapListFrom(
        json['days'],
      ).map(HealingPlanDayTimeline.fromJson).toList(),
    );
  }
}

class HealingPlanStartResult {
  final bool started;
  final Object? assignment;

  const HealingPlanStartResult({
    required this.started,
    required this.assignment,
  });

  factory HealingPlanStartResult.fromJson(Map<String, dynamic> json) {
    return HealingPlanStartResult(
      started: _boolFrom(json['started']),
      assignment: json['assignment'],
    );
  }
}

int _intensityFromReadiness(String readiness) {
  return switch (readiness.toUpperCase()) {
    'NOT_READY' => 8,
    'EXPLORING' => 5,
    'READY' => 3,
    _ => 0,
  };
}
