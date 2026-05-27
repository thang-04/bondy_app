import 'api_client.dart';

class HealingService {
  final ApiClient _apiClient;

  HealingService(this._apiClient);

  Future<HealingHomeResponse> getHome() async {
    final response = await _apiClient.get('/healing/home', authenticated: true);
    return HealingHomeResponse.fromJson(response);
  }

  Future<HealingContentDetailResponse> getArticle(String id) async {
    final response = await _apiClient.get('/healing/articles/$id', authenticated: true);
    return HealingContentDetailResponse.fromJson(response);
  }

  Future<HealingContentDetailResponse> getExercise(String id) async {
    final response = await _apiClient.get('/healing/exercises/$id', authenticated: true);
    return HealingContentDetailResponse.fromJson(response);
  }

  Future<HealingCourseDetailResponse> getCourse(String id) async {
    final response = await _apiClient.get('/healing/courses/$id', authenticated: true);
    return HealingCourseDetailResponse.fromJson(response);
  }

  Future<HealingCheckinResponse> submitCheckin(HealingCheckinRequest request) async {
    final response = await _apiClient.post(
      '/healing/checkin',
      body: request.toJson(),
      authenticated: true,
    );
    return HealingCheckinResponse.fromJson(response);
  }

  Future<HealingTriggerResponse> getTriggers() async {
    final response = await _apiClient.get('/healing/triggers', authenticated: true);
    return HealingTriggerResponse.fromJson(response);
  }

  Future<HealingTriggerResponse> dismissTrigger(String triggerId, String triggerType, String? chatId) async {
    final response = await _apiClient.post(
      '/healing/triggers/dismiss',
      body: {
        'triggerId': triggerId,
        'triggerType': triggerType,
        if (chatId != null) 'chatId': chatId,
      },
      authenticated: true,
    );
    return HealingTriggerResponse.fromJson(response);
  }
}

class HealingHomeResponse {
  final bool success;
  final HealingHomeData? data;
  final String? error;

  HealingHomeResponse({
    required this.success,
    this.data,
    this.error,
  });

  factory HealingHomeResponse.fromJson(Map<String, dynamic> json) => HealingHomeResponse(
    success: json['success'] ?? false,
    data: json['data'] != null ? HealingHomeData.fromJson(json['data']) : null,
    error: json['error'],
  );
}

class HealingHomeData {
  final List<HealingContentItem> articles;
  final List<HealingContentItem> exercises;
  final List<HealingContentItem> courses;
  final DailyCheckinStatus? checkinStatus;

  HealingHomeData({
    required this.articles,
    required this.exercises,
    required this.courses,
    this.checkinStatus,
  });

  factory HealingHomeData.fromJson(Map<String, dynamic> json) => HealingHomeData(
    articles: (json['articles'] as List<dynamic>?)
        ?.map((e) => HealingContentItem.fromJson(e))
        .toList() ?? [],
    exercises: (json['exercises'] as List<dynamic>?)
        ?.map((e) => HealingContentItem.fromJson(e))
        .toList() ?? [],
    courses: (json['courses'] as List<dynamic>?)
        ?.map((e) => HealingContentItem.fromJson(e))
        .toList() ?? [],
    checkinStatus: json['checkinStatus'] != null
        ? DailyCheckinStatus.fromJson(json['checkinStatus'])
        : null,
  );
}

class HealingContentItem {
  final String id;
  final String type;
  final String title;
  final String summary;
  final String? thumbnailUrl;
  final String category;
  final String accessLevel;
  final bool isCompleted;

  HealingContentItem({
    required this.id,
    required this.type,
    required this.title,
    required this.summary,
    this.thumbnailUrl,
    required this.category,
    required this.accessLevel,
    required this.isCompleted,
  });

  factory HealingContentItem.fromJson(Map<String, dynamic> json) => HealingContentItem(
    id: json['id'] ?? '',
    type: json['type'] ?? '',
    title: json['title'] ?? '',
    summary: json['summary'] ?? '',
    thumbnailUrl: json['thumbnailUrl'],
    category: json['category'] ?? '',
    accessLevel: json['accessLevel'] ?? 'FREE',
    isCompleted: json['isCompleted'] ?? false,
  );
}

class DailyCheckinStatus {
  final bool completed;
  final DateTime? lastCheckinAt;

  DailyCheckinStatus({
    required this.completed,
    this.lastCheckinAt,
  });

  factory DailyCheckinStatus.fromJson(Map<String, dynamic> json) => DailyCheckinStatus(
    completed: json['completed'] ?? false,
    lastCheckinAt: json['lastCheckinAt'] != null
        ? DateTime.tryParse(json['lastCheckinAt'])
        : null,
  );
}

class HealingCheckinRequest {
  final String mood;
  final int intensity;
  final String? context;
  final String? note;

  HealingCheckinRequest({
    required this.mood,
    required this.intensity,
    this.context,
    this.note,
  });

  Map<String, dynamic> toJson() => {
    'mood': mood,
    'intensity': intensity,
    if (context != null) 'context': context,
    if (note != null) 'note': note,
  };
}

class HealingCheckinResponse {
  final bool success;
  final dynamic data;
  final String? error;

  HealingCheckinResponse({
    required this.success,
    this.data,
    this.error,
  });

  factory HealingCheckinResponse.fromJson(Map<String, dynamic> json) => HealingCheckinResponse(
    success: json['success'] ?? false,
    data: json['data'],
    error: json['error'],
  );
}

class HealingTriggerResponse {
  final bool success;
  final List<HealingTrigger>? data;
  final String? error;

  HealingTriggerResponse({
    required this.success,
    this.data,
    this.error,
  });

  factory HealingTriggerResponse.fromJson(Map<String, dynamic> json) => HealingTriggerResponse(
    success: json['success'] ?? false,
    data: (json['data'] as List<dynamic>?)
        ?.map((e) => HealingTrigger.fromJson(e))
        .toList(),
    error: json['error'],
  );
}

class HealingTrigger {
  final String id;
  final String type;
  final String title;
  final String description;
  final String? actionTarget;

  HealingTrigger({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    this.actionTarget,
  });

  factory HealingTrigger.fromJson(Map<String, dynamic> json) => HealingTrigger(
    id: json['id'] ?? '',
    type: json['type'] ?? '',
    title: json['title'] ?? '',
    description: json['description'] ?? '',
    actionTarget: json['actionTarget'],
  );
}

class HealingContentDetailResponse {
  final bool success;
  final HealingArticleDetail? data;
  final String? error;

  HealingContentDetailResponse({
    required this.success,
    this.data,
    this.error,
  });

  factory HealingContentDetailResponse.fromJson(Map<String, dynamic> json) => HealingContentDetailResponse(
    success: json['success'] ?? false,
    data: json['data'] != null ? HealingArticleDetail.fromJson(json['data']) : null,
    error: json['error'],
  );
}

class HealingArticleDetail {
  final String id;
  final String title;
  final String body;
  final String? authorName;
  final String? sourceName;
  final int estimatedReadMinutes;
  final String? thumbnailUrl;

  HealingArticleDetail({
    required this.id,
    required this.title,
    required this.body,
    this.authorName,
    this.sourceName,
    required this.estimatedReadMinutes,
    this.thumbnailUrl,
  });

  factory HealingArticleDetail.fromJson(Map<String, dynamic> json) => HealingArticleDetail(
    id: json['id'] ?? '',
    title: json['title'] ?? '',
    body: json['body'] ?? '',
    authorName: json['authorName'],
    sourceName: json['sourceName'],
    estimatedReadMinutes: json['estimatedReadMinutes'] ?? 5,
    thumbnailUrl: json['thumbnailUrl'],
  );
}

class HealingCourseDetailResponse {
  final bool success;
  final HealingCourseDetail? data;
  final String? error;

  HealingCourseDetailResponse({
    required this.success,
    this.data,
    this.error,
  });

  factory HealingCourseDetailResponse.fromJson(Map<String, dynamic> json) => HealingCourseDetailResponse(
    success: json['success'] ?? false,
    data: json['data'] != null ? HealingCourseDetail.fromJson(json['data']) : null,
    error: json['error'],
  );
}

class HealingCourseDetail {
  final String id;
  final String title;
  final String summary;
  final int durationDays;
  final String goal;
  final List<HealingLesson> lessons;
  final String? thumbnailUrl;

  HealingCourseDetail({
    required this.id,
    required this.title,
    required this.summary,
    required this.durationDays,
    required this.goal,
    required this.lessons,
    this.thumbnailUrl,
  });

  factory HealingCourseDetail.fromJson(Map<String, dynamic> json) => HealingCourseDetail(
    id: json['id'] ?? '',
    title: json['title'] ?? '',
    summary: json['summary'] ?? '',
    durationDays: json['durationDays'] ?? 0,
    goal: json['goal'] ?? '',
    lessons: (json['lessons'] as List<dynamic>?)
        ?.map((e) => HealingLesson.fromJson(e))
        .toList() ?? [],
    thumbnailUrl: json['thumbnailUrl'],
  );
}

class HealingLesson {
  final String id;
  final int dayNumber;
  final String title;
  final String? articleContentId;
  final String? exerciseContentId;
  final int estimatedMinutes;
  final bool isCompleted;

  HealingLesson({
    required this.id,
    required this.dayNumber,
    required this.title,
    this.articleContentId,
    this.exerciseContentId,
    required this.estimatedMinutes,
    required this.isCompleted,
  });

  factory HealingLesson.fromJson(Map<String, dynamic> json) => HealingLesson(
    id: json['id'] ?? '',
    dayNumber: json['dayNumber'] ?? 0,
    title: json['title'] ?? '',
    articleContentId: json['articleContentId'],
    exerciseContentId: json['exerciseContentId'],
    estimatedMinutes: json['estimatedMinutes'] ?? 5,
    isCompleted: json['isCompleted'] ?? false,
  );
}