import 'package:bondy/core/media_url.dart';
import 'package:bondy/services/api_client.dart';
import 'package:bondy/services/profile_service.dart';
import 'package:image_picker/image_picker.dart';

class ChatMatch {
  final String id;
  final String matchId;
  final ChatOtherUser otherUser;
  final ChatLastMessage? lastMessage;
  final DateTime updatedAt;

  ChatMatch({
    required this.id,
    required this.matchId,
    required this.otherUser,
    this.lastMessage,
    required this.updatedAt,
  });

  factory ChatMatch.fromJson(Map<String, dynamic> json) {
    return ChatMatch(
      id: json['id'] as String,
      matchId: json['matchId'] as String,
      otherUser: ChatOtherUser.fromJson(json['otherUser'] as Map<String, dynamic>),
      lastMessage: json['lastMessage'] != null
          ? ChatLastMessage.fromJson(json['lastMessage'] as Map<String, dynamic>)
          : null,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

class ChatOtherUser {
  final String id;
  final String firstName;
  final String lastName;
  final String? photo;

  ChatOtherUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.photo,
  });

  factory ChatOtherUser.fromJson(Map<String, dynamic> json) {
    return ChatOtherUser(
      id: json['id'] as String,
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      photo: rewriteMediaUrl(json['photo'] as String?),
    );
  }

  String get displayName => '$firstName $lastName'.trim();
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
    return data.cast<Map<String, dynamic>>().map((e) => ChatMatch.fromJson(e)).toList();
  }

  Future<List<ChatMessage>> listMessages(String chatId) async {
    final response = await _apiClient.get('/chats/$chatId/messages', authenticated: true);
    final data = response['data'] as List<dynamic>;
    return data.cast<Map<String, dynamic>>().map((e) => ChatMessage.fromJson(e)).toList();
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
      body: {
        'content': trimmedContent,
        'messageType': messageType,
      },
      authenticated: true,
    );
    return ChatMessage.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<void> markAsRead(String messageId) async {
    await _apiClient.put(
      '/messages/$messageId/read',
      authenticated: true,
    );
  }

  Future<bool> fetchPartnerTyping(String chatId) async {
    final response = await _apiClient.get(
      '/chats/$chatId/typing',
      authenticated: true,
    );
    final data = response['data'] as Map<String, dynamic>? ?? {};
    return data['isTyping'] == true;
  }

  Future<void> sendTypingIndicator(String chatId, {bool isTyping = true}) async {
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
    final file = XFile(filePath, name: filePath.split(RegExp(r'[/\\]')).last);
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
}
