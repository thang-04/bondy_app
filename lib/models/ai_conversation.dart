/// Model classes cho AI Conversation History.
///
/// Dùng để parse response từ API `/ai/conversations`.

class AiConversation {
  final String id;
  final String mode;
  final String? title;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AiConversation({
    required this.id,
    required this.mode,
    this.title,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AiConversation.fromJson(Map<String, dynamic> json) {
    return AiConversation(
      id: json['id'] as String,
      mode: json['mode'] as String? ?? 'default',
      title: json['title'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Lấy title hiển thị, fallback nếu null.
  String get displayTitle => title ?? 'Cuộc trò chuyện mới';

  /// Thời gian relative (VD: "2 giờ trước", "Hôm qua").
  String get relativeTime {
    final now = DateTime.now();
    final diff = now.difference(updatedAt);

    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 2) return 'Hôm qua';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} tuần trước';
    return '${(diff.inDays / 30).floor()} tháng trước';
  }
}

class AiConversationMessage {
  final String id;
  final String role;
  final String content;
  final DateTime createdAt;

  const AiConversationMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  factory AiConversationMessage.fromJson(Map<String, dynamic> json) {
    return AiConversationMessage(
      id: json['id'] as String,
      role: json['role'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';
}

class AiConversationDetail {
  final AiConversation conversation;
  final List<AiConversationMessage> messages;

  const AiConversationDetail({
    required this.conversation,
    required this.messages,
  });

  factory AiConversationDetail.fromJson(Map<String, dynamic> json) {
    final messagesJson = json['messages'] as List<dynamic>? ?? [];
    return AiConversationDetail(
      conversation: AiConversation.fromJson(json),
      messages: messagesJson
          .map((m) =>
              AiConversationMessage.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }
}

class AiConversationListResponse {
  final List<AiConversation> conversations;
  final int total;

  const AiConversationListResponse({
    required this.conversations,
    required this.total,
  });

  factory AiConversationListResponse.fromJson(Map<String, dynamic> json) {
    final list = json['conversations'] as List<dynamic>? ?? [];
    return AiConversationListResponse(
      conversations: list
          .map((c) => AiConversation.fromJson(c as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int? ?? 0,
    );
  }
}
