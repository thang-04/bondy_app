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

class AiService {
  final ApiClient _apiClient;

  AiService(this._apiClient);

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
}
