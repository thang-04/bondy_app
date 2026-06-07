import 'package:flutter/foundation.dart';

import '../../services/api_client.dart';
import '../../services/chat_service.dart';

class ChatViewModel extends ChangeNotifier {
  ChatViewModel({ChatService? service})
    : _service = service ?? ChatService(ApiClient());

  final ChatService _service;

  List<ChatMatch> _chats = [];
  bool _isLoading = false;
  String? _error;

  List<ChatMatch> get chats => List.unmodifiable(_chats);
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get totalUnreadCount =>
      _chats.fold<int>(0, (sum, c) => sum + c.unreadCount);

  Future<void> fetchChats() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _chats = await _service.listChats();
      _sortChats();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearUnread(String chatId) {
    final idx = _chats.indexWhere((c) => c.id == chatId);
    if (idx == -1) return;
    if (_chats[idx].unreadCount == 0) return;
    _chats[idx] = _chats[idx].copyWith(unreadCount: 0);
    notifyListeners();
  }

  void incrementUnread(String chatId) {
    final idx = _chats.indexWhere((c) => c.id == chatId);
    if (idx == -1) return;
    _chats[idx] = _chats[idx].copyWith(
      unreadCount: _chats[idx].unreadCount + 1,
    );
    notifyListeners();
  }

  void updatePartnerPresence({
    required String chatId,
    required bool isOnline,
    String? lastSeenAt,
  }) {
    final idx = _chats.indexWhere((c) => c.id == chatId);
    if (idx == -1) return;
    final updatedOther = _chats[idx].otherUser.copyWith(
      isOnline: isOnline,
      lastSeenAt: lastSeenAt,
      presenceStatus: isOnline ? 'ONLINE' : 'OFFLINE',
    );
    _chats[idx] = _chats[idx].copyWith(otherUser: updatedOther);
    notifyListeners();
  }

  void updateLatestMessage({
    required String chatId,
    required ChatMessage message,
    required String currentUserId,
  }) {
    final idx = _chats.indexWhere((chat) => chat.id == chatId);
    if (idx == -1) return;
    final isMine = message.senderId == currentUserId;
    final current = _chats[idx];
    _chats[idx] = current.copyWith(
      lastMessage: ChatLastMessage(
        content: message.content,
        createdAt: message.createdAt,
        isMine: isMine,
      ),
      unreadCount: isMine ? current.unreadCount : current.unreadCount + 1,
      updatedAt: message.createdAt,
    );
    _sortChats();
    notifyListeners();
  }

  void _sortChats() {
    _chats.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  void reset() {
    _chats = [];
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
