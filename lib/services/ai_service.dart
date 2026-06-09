import 'api_client.dart';

class AiSuggestRequest {
  final String conversationId;
  final String userId;
  final String intent;
  final String tone;
  final String language;

  AiSuggestRequest({
    required this.conversationId,
    required this.userId,
    required this.intent,
    this.tone = 'casual',
    this.language = 'vi',
  });

  Map<String, dynamic> toJson() => {
    'conversationId': conversationId,
    'userId': userId,
    'intent': intent,
    'tone': tone,
    'language': language,
  };
}

class AiSuggestData {
  final List<String> suggestions;
  final AiUsage usage;

  AiSuggestData({required this.suggestions, required this.usage});

  factory AiSuggestData.fromJson(Map<String, dynamic> json) => AiSuggestData(
    suggestions: List<String>.from(json['suggestions'] ?? const []),
    usage: AiUsage.fromJson(
      (json['usage'] as Map?)?.cast<String, dynamic>() ?? const {},
    ),
  );
}

class AiUsage {
  final int tokensUsed;
  final int latencyMs;
  final String provider;

  AiUsage({
    required this.tokensUsed,
    required this.latencyMs,
    required this.provider,
  });

  factory AiUsage.fromJson(Map<String, dynamic> json) => AiUsage(
    tokensUsed: json['tokensUsed'] ?? 0,
    latencyMs: json['latencyMs'] ?? 0,
    provider: json['provider'] ?? 'unknown',
  );
}

class AiSuggestResponse {
  final bool success;
  final AiSuggestData? data;
  final String? error;

  AiSuggestResponse({required this.success, this.data, this.error});

  factory AiSuggestResponse.fromJson(Map<String, dynamic> json) =>
      AiSuggestResponse(
        success: json['success'] ?? false,
        data: json['data'] != null
            ? AiSuggestData.fromJson(
                (json['data'] as Map).cast<String, dynamic>(),
              )
            : null,
        error: json['error']?.toString(),
      );

  bool get isLimitReached => error?.contains('LIMIT_REACHED') ?? false;
}

class AiChatRequest {
  final String chatId;
  final String message;
  final String matchId;
  final String intent;
  final String tone;
  final int count;
  final String language;

  AiChatRequest({
    required this.chatId,
    required this.message,
    required this.matchId,
    this.intent = 'continue',
    this.tone = 'casual',
    this.count = 3,
    this.language = 'vi',
  });

  Map<String, dynamic> toJson() => {
    'chatId': chatId,
    'matchId': matchId,
    'message': message,
    'intent': intent,
    'tone': tone,
    'count': count,
    'language': language,
  };
}

enum AiChatMode {
  defaultMode,
  healing,
  coach;

  static AiChatMode fromJson(Object? value) {
    switch (value?.toString().toLowerCase()) {
      case 'coach':
        return AiChatMode.coach;
      case 'healing':
        return AiChatMode.healing;
      case 'default':
      default:
        return AiChatMode.defaultMode;
    }
  }
}

class AiChatMeta {
  final int tokensUsed;
  final int latencyMs;
  final bool failed;
  final List<String> suggestions;
  final Map<String, dynamic> raw;

  AiChatMeta({
    required this.tokensUsed,
    required this.latencyMs,
    required this.failed,
    required this.suggestions,
    required this.raw,
  });

  factory AiChatMeta.fromJson(Map<String, dynamic> json) {
    final rawSuggestions = json['suggestions'];
    return AiChatMeta(
      tokensUsed: json['tokensUsed'] as int? ?? 0,
      latencyMs: json['latencyMs'] as int? ?? 0,
      failed: json['failed'] == true,
      suggestions: rawSuggestions is List
          ? rawSuggestions.map((item) => item.toString()).toList()
          : const [],
      raw: json,
    );
  }

  bool get isHighSafety {
    final rawValue =
        raw['safetyLevel'] ??
        raw['safety'] ??
        raw['riskLevel'] ??
        raw['severity'];
    final value = rawValue?.toString().toLowerCase();
    return value == 'high' || value == 'critical' || value == 'severe';
  }
}

class AiChatData {
  final String flowVersion;
  final String chatId;
  final String matchId;
  final String partnerId;
  final String partnerName;
  final String? coachSessionId;
  final String response;
  final AiChatMode mode;
  final AiChatMeta meta;

  AiChatData({
    required this.flowVersion,
    required this.chatId,
    required this.matchId,
    required this.partnerId,
    required this.partnerName,
    required this.response,
    required this.mode,
    required this.meta,
    this.coachSessionId,
  });

  factory AiChatData.fromJson(Map<String, dynamic> json) {
    final rawMeta = Map<String, dynamic>.from(
      (json['meta'] as Map?) ?? const <String, dynamic>{},
    );
    if (json['suggestions'] is List && rawMeta['suggestions'] == null) {
      rawMeta['suggestions'] = json['suggestions'];
    }

    return AiChatData(
      flowVersion: json['flowVersion']?.toString() ?? '',
      chatId: json['chatId']?.toString() ?? '',
      matchId: json['matchId']?.toString() ?? '',
      partnerId: json['partnerId']?.toString() ?? '',
      partnerName: json['partnerName']?.toString() ?? '',
      coachSessionId: json['coachSessionId']?.toString(),
      response: json['response']?.toString() ?? '',
      mode: AiChatMode.fromJson(json['mode']),
      meta: AiChatMeta.fromJson(rawMeta),
    );
  }
}

class AiChatResponse {
  final bool success;
  final AiChatData? data;
  final String? error;

  AiChatResponse({required this.success, this.data, this.error});

  factory AiChatResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is Map) {
      return AiChatResponse(
        success: json['success'] != false,
        data: AiChatData.fromJson(data.cast<String, dynamic>()),
        error: json['error']?.toString(),
      );
    }

    // Some backend handlers return the chat payload directly.
    if (json.containsKey('response')) {
      return AiChatResponse(
        success: true,
        data: AiChatData.fromJson(json),
        error: json['error']?.toString(),
      );
    }

    return AiChatResponse(
      success: json['success'] == true,
      error: json['error']?.toString(),
    );
  }
}

class AiService {
  final ApiClient _apiClient;
  final Duration coachTimeout;

  AiService(
    this._apiClient, {
    this.coachTimeout = const Duration(seconds: 120),
  });

  Future<AiSuggestResponse> suggest(AiSuggestRequest request) async {
    final response = await _apiClient
        .post(
          '/ai/conversation-suggest',
          body: request.toJson(),
          authenticated: true,
        )
        .timeout(const Duration(seconds: 30));
    return AiSuggestResponse.fromJson(response);
  }

  Future<AiChatResponse> chatCoach(AiChatRequest request) async {
    final response = await _apiClient
        .post(
          '/ai/coach/suggestions',
          body: request.toJson(),
          authenticated: true,
        )
        .timeout(coachTimeout);
    return AiChatResponse.fromJson(response);
  }
}
