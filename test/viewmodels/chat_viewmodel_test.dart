import 'package:bondy/services/api_client.dart';
import 'package:bondy/services/chat_service.dart';
import 'package:bondy/viewmodels/chat/chat_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeChatService extends ChatService {
  _FakeChatService(this.result)
    : super(ApiClient(baseUrlOverride: 'http://localhost'));

  final List<ChatMatch> result;

  @override
  Future<List<ChatMatch>> listChats() async => result;
}

ChatMatch _chat(String id, DateTime updatedAt) {
  return ChatMatch(
    id: id,
    matchId: 'match-$id',
    otherUser: ChatOtherUser(id: 'other-$id', firstName: id, lastName: ''),
    updatedAt: updatedAt,
    chatAccepted: true,
    isMessageRequest: false,
    isInitiator: false,
  );
}

void main() {
  test('sorts fetched chats by latest activity', () async {
    final viewModel = ChatViewModel(
      service: _FakeChatService([
        _chat('older', DateTime.parse('2026-06-07T09:00:00Z')),
        _chat('newer', DateTime.parse('2026-06-07T10:00:00Z')),
      ]),
    );

    await viewModel.fetchChats();

    expect(viewModel.chats.map((chat) => chat.id), ['newer', 'older']);
  });

  test('moves a chat to the top when a new message arrives', () async {
    final viewModel = ChatViewModel(
      service: _FakeChatService([
        _chat('first', DateTime.parse('2026-06-07T10:00:00Z')),
        _chat('second', DateTime.parse('2026-06-07T09:00:00Z')),
      ]),
    );
    await viewModel.fetchChats();

    viewModel.updateLatestMessage(
      chatId: 'second',
      message: ChatMessage(
        id: 'message-1',
        content: 'Tin nhắn mới',
        senderId: 'other-second',
        isRead: false,
        createdAt: DateTime.parse('2026-06-07T11:00:00Z'),
      ),
      currentUserId: 'current-user',
    );

    expect(viewModel.chats.first.id, 'second');
    expect(viewModel.chats.first.lastMessage?.content, 'Tin nhắn mới');
    expect(viewModel.chats.first.unreadCount, 1);
  });
}
