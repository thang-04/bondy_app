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
    suggestions: List<String>.from(json['suggestions']),
    usage: AiUsage.fromJson(json['usage']),
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

  AiSuggestResponse({
    required this.success,
    this.data,
    this.error,
  });

  factory AiSuggestResponse.fromJson(Map<String, dynamic> json) => AiSuggestResponse(
    success: json['success'] ?? false,
    data: json['data'] != null ? AiSuggestData.fromJson(json['data']) : null,
    error: json['error'],
  );

  bool get isLimitReached => error?.contains('LIMIT_REACHED') ?? false;
}

class AiService {
  final ApiClient _apiClient;

  AiService(this._apiClient);

  // Environment-based: use mock when localhost
  bool get _isDev => _apiClient.baseUrl.contains('localhost');

  Future<AiSuggestResponse> suggest(AiSuggestRequest request) async {
    if (_isDev) {
      return _mockSuggest(request);
    }
    final response = await _apiClient.post(
      '/ai/conversation-suggest',
      body: request.toJson(),
      authenticated: true,
    ).timeout(const Duration(seconds: 30));
    return AiSuggestResponse.fromJson(response);
  }

  // Mock implementation for dev
  Future<AiSuggestResponse> _mockSuggest(AiSuggestRequest request) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final suggestions = _getMockSuggestions(request.intent);
    return AiSuggestResponse(
      success: true,
      data: AiSuggestData(
        suggestions: suggestions,
        usage: AiUsage(
          tokensUsed: 50,
          latencyMs: 500,
          provider: 'mock',
        ),
      ),
    );
  }

  List<String> _getMockSuggestions(String intent) {
    switch (intent) {
      case 'opener':
        return [
          'Hey, mình thấy bạn rất thú vị!',
          'Xin chào! Rất vui được làm quen.',
          'Bạn có gì thú vị đang làm không?',
        ];
      case 'continue':
        return [
          'Tiếp tục câu chuyện đi, mình rất thích lắng nghe.',
          'Thú vị lắm! Kể thêm đi.',
          'Bạn có thường làm gì vào cuối tuần?',
        ];
      case 'deepen':
        return [
          'Bạn có thể chia sẻ về ước mơ của bạn không?',
          'Điều gì quan trọng nhất với bạn trong một mối quan hệ?',
          'Bạn cảm thấy thế nào khi ở bên cạnh người mình yêu?',
        ];
      case 'humor':
        return [
          'Nếu bạn là một loại bánh, bạn sẽ là bánh gì? Mình là bánh donut 🍩',
          'Mình nghe nói người yêu cũ của bạn giỏi lắm nhỉ... nấu cơm! 🍚',
        ];
      case 'flirt':
        return [
          'Mình thích nụ cười của bạn!',
          'Bạn có rảnh không? Mình muốn nói chuyện thêm.',
          'Mình cảm thấy thoải mái khi nói chuyện với bạn.',
        ];
      default:
        return [
          'Bạn có thấy hôm nay mình thật may mắn không?',
          'Mình thích cách bạn nói chuyện, rất thoải mái.',
          'Điều gì làm bạn vui nhất trong tuần này?',
        ];
    }
  }
}