import 'package:bondy/core/media_url.dart';
import 'package:bondy/services/api_client.dart';
import 'package:bondy/services/profile_service.dart';
import 'package:image_picker/image_picker.dart';

class ChatMatch {
  final String id;
  final String matchId;
  final ChatOtherUser otherUser;
  final ChatLastMessage? lastMessage;
  final int unreadCount;
  final DateTime updatedAt;
  final bool chatAccepted;
  final bool isMessageRequest;
  final bool isInitiator;
  final DateTime? chatRequestExpiresAt;

  ChatMatch({
    required this.id,
    required this.matchId,
    required this.otherUser,
    this.lastMessage,
    this.unreadCount = 0,
    required this.updatedAt,
    required this.chatAccepted,
    required this.isMessageRequest,
    required this.isInitiator,
    this.chatRequestExpiresAt,
  });

  ChatMatch copyWith({
    ChatOtherUser? otherUser,
    ChatLastMessage? lastMessage,
    int? unreadCount,
    DateTime? updatedAt,
    bool? chatAccepted,
    bool? isMessageRequest,
    bool? isInitiator,
    DateTime? chatRequestExpiresAt,
  }) {
    return ChatMatch(
      id: id,
      matchId: matchId,
      otherUser: otherUser ?? this.otherUser,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      updatedAt: updatedAt ?? this.updatedAt,
      chatAccepted: chatAccepted ?? this.chatAccepted,
      isMessageRequest: isMessageRequest ?? this.isMessageRequest,
      isInitiator: isInitiator ?? this.isInitiator,
      chatRequestExpiresAt: chatRequestExpiresAt ?? this.chatRequestExpiresAt,
    );
  }

  factory ChatMatch.fromJson(Map<String, dynamic> json) {
    return ChatMatch(
      id: json['id'] as String,
      matchId: json['matchId'] as String,
      otherUser: ChatOtherUser.fromJson(
        json['otherUser'] as Map<String, dynamic>,
      ),
      lastMessage: json['lastMessage'] != null
          ? ChatLastMessage.fromJson(
              json['lastMessage'] as Map<String, dynamic>,
            )
          : null,
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      chatAccepted: json['chatAccepted'] as bool? ?? true,
      isMessageRequest: json['isMessageRequest'] as bool? ?? false,
      isInitiator: json['isInitiator'] as bool? ?? false,
      chatRequestExpiresAt: json['chatRequestExpiresAt'] != null
          ? DateTime.parse(json['chatRequestExpiresAt'] as String)
          : null,
    );
  }
}

class ChatOtherUser {
  final String id;
  final String firstName;
  final String lastName;
  final String? photo;
  final bool isOnline;
  final String? lastSeenAt;
  final String? presenceStatus;

  ChatOtherUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.photo,
    this.isOnline = false,
    this.lastSeenAt,
    this.presenceStatus,
  });

  ChatOtherUser copyWith({
    bool? isOnline,
    String? lastSeenAt,
    String? presenceStatus,
  }) {
    return ChatOtherUser(
      id: id,
      firstName: firstName,
      lastName: lastName,
      photo: photo,
      isOnline: isOnline ?? this.isOnline,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      presenceStatus: presenceStatus ?? this.presenceStatus,
    );
  }

  factory ChatOtherUser.fromJson(Map<String, dynamic> json) {
    return ChatOtherUser(
      id: json['id'] as String,
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      photo: rewriteMediaUrl(json['photo'] as String?),
      isOnline: json['isOnline'] as bool? ?? false,
      lastSeenAt: json['lastSeenAt'] as String?,
      presenceStatus: json['presenceStatus'] as String?,
    );
  }

  String get displayName => '$firstName $lastName'.trim();
}

class PartnerPresence {
  final String userId;
  final bool isOnline;
  final String? lastSeenAt;
  final String? presenceStatus;

  PartnerPresence({
    required this.userId,
    required this.isOnline,
    this.lastSeenAt,
    this.presenceStatus,
  });

  factory PartnerPresence.fromJson(Map<String, dynamic> json) {
    return PartnerPresence(
      userId: json['userId'] as String? ?? '',
      isOnline: json['isOnline'] as bool? ?? false,
      lastSeenAt: json['lastSeenAt'] as String?,
      presenceStatus: json['presenceStatus'] as String?,
    );
  }
}

class ChatLastMessage {
  final String content;
  final DateTime createdAt;
  final bool isMine;

  ChatLastMessage({
    required this.content,
    required this.createdAt,
    required this.isMine,
  });

  factory ChatLastMessage.fromJson(Map<String, dynamic> json) {
    return ChatLastMessage(
      content: json['content'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      isMine: json['isMine'] as bool? ?? false,
    );
  }
}

class ChatMessage {
  final String id;
  final String content;
  final String senderId;
  final bool isRead;
  final DateTime createdAt;
  final String? messageType;
  final String? deliveryStatus;

  ChatMessage({
    required this.id,
    required this.content,
    required this.senderId,
    required this.isRead,
    required this.createdAt,
    this.messageType,
    this.deliveryStatus,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final type = json['messageType'] as String?;
    final rawContent = json['content'] as String? ?? '';
    // Với IMAGE/VOICE thì content là URL → rewrite host về API hiện tại để máy
    // thật mở được file đã upload từ emulator. Với TEXT/EMOJI để nguyên.
    final content = (type == 'IMAGE' || type == 'VOICE')
        ? (rewriteMediaUrl(rawContent) ?? rawContent)
        : rawContent;
    return ChatMessage(
      id: json['id'] as String,
      content: content,
      senderId: json['senderId'] as String,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      messageType: type,
      deliveryStatus: json['deliveryStatus'] as String?,
    );
  }
}

class ChatService {
  final ApiClient _apiClient;

  ChatService(this._apiClient);

  Future<List<ChatMatch>> listChats() async {
    final response = await _apiClient.get('/chats', authenticated: true);
    final data = response['data'] as List<dynamic>;
    return data
        .cast<Map<String, dynamic>>()
        .map((e) => ChatMatch.fromJson(e))
        .toList();
  }

  Future<List<ChatMessage>> listMessages(String chatId) async {
    final response = await _apiClient.get(
      '/chats/$chatId/messages',
      authenticated: true,
    );
    final data = response['data'] as List<dynamic>;
    return data
        .cast<Map<String, dynamic>>()
        .map((e) => ChatMessage.fromJson(e))
        .toList();
  }

  Future<ChatMessage> sendMessage(
    String chatId,
    String content, {
    String messageType = 'TEXT',
  }) async {
    final trimmedContent = content.trim();
    if (trimmedContent.isEmpty) {
      throw ArgumentError('Message content cannot be empty or whitespace');
    }
    final response = await _apiClient.post(
      '/chats/$chatId/messages',
      body: {'content': trimmedContent, 'messageType': messageType},
      authenticated: true,
    );
    return ChatMessage.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<void> markAsRead(String messageId) async {
    await _apiClient.put('/messages/$messageId/read', authenticated: true);
  }

  Future<bool> fetchPartnerTyping(String chatId) async {
    final response = await _apiClient.get(
      '/chats/$chatId/typing',
      authenticated: true,
    );
    final data = response['data'] as Map<String, dynamic>? ?? {};
    return data['isTyping'] == true;
  }

  Future<void> sendTypingIndicator(
    String chatId, {
    bool isTyping = true,
  }) async {
    await _apiClient.post(
      '/chats/$chatId/typing',
      body: {'isTyping': isTyping},
      authenticated: true,
    );
  }

  Future<ChatMessage> sendImageMessage(String chatId, XFile imageFile) async {
    final profileService = ProfileService(apiClient: _apiClient);
    final url = await profileService.uploadMediaFile(imageFile);
    if (url == null || url.isEmpty) {
      throw ArgumentError('Không tải được ảnh');
    }
    return sendMessage(chatId, url, messageType: 'IMAGE');
  }

  Future<ChatMessage> sendVoiceMessage(String chatId, String filePath) async {
    final profileService = ProfileService(apiClient: _apiClient);
    // Trên web, plugin record trả về blob: URL KHÔNG có đuôi file → uploadMediaFile
    // suy ra MIME 'application/octet-stream' và server từ chối. Nếu tên file thiếu
    // đuôi audio hợp lệ thì gán .webm (định dạng record_web xuất ra với opus) để
    // server nhận đúng content-type audio/*. Trên native tên đã là .m4a nên giữ nguyên.
    final rawName = filePath.split(RegExp(r'[/\\]')).last;
    final hasAudioExt = RegExp(
      r'\.(m4a|mp3|aac|webm|ogg|wav)$',
      caseSensitive: false,
    ).hasMatch(rawName);
    final name = hasAudioExt
        ? rawName
        : 'voice_${DateTime.now().millisecondsSinceEpoch}.webm';
    final file = XFile(filePath, name: name);
    final url = await profileService.uploadMediaFile(file);
    if (url == null || url.isEmpty) {
      throw ArgumentError('Không tải được tin nhắn thoại');
    }
    return sendMessage(chatId, url, messageType: 'VOICE');
  }

  Future<void> updateDeliveryStatus(String messageId, String status) async {
    await _apiClient.put(
      '/messages/$messageId/delivery',
      body: {'status': status},
      authenticated: true,
    );
  }

  Future<PartnerPresence> fetchPartnerPresence(String chatId) async {
    final response = await _apiClient.get(
      '/chats/$chatId/presence',
      authenticated: true,
    );
    return PartnerPresence.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<int> markAllAsRead(String chatId) async {
    final response = await _apiClient.put(
      '/chats/$chatId/read',
      authenticated: true,
    );
    final data = response['data'] as Map<String, dynamic>? ?? {};
    return (data['updatedCount'] as num?)?.toInt() ?? 0;
  }

  Future<void> acceptChat(String matchId) async {
    await _apiClient.post(
      '/matches/$matchId/accept-chat',
      authenticated: true,
    );
  }

  Future<void> declineChat(String matchId) async {
    await _apiClient.post(
      '/matches/$matchId/decline-chat',
      authenticated: true,
    );
  }
}
