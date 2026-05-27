import 'package:bondy/services/api_client.dart';

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
      photo: json['photo'] as String?,
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

  ChatMessage({
    required this.id,
    required this.content,
    required this.senderId,
    required this.isRead,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      content: json['content'] as String? ?? '',
      senderId: json['senderId'] as String,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
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

  Future<ChatMessage> sendMessage(String chatId, String content) async {
    final response = await _apiClient.post(
      '/chats/$chatId/messages',
      body: {'content': content},
      authenticated: true,
    );
    return ChatMessage.fromJson(response['data'] as Map<String, dynamic>);
  }
}
