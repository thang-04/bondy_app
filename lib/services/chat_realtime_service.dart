import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'auth_service.dart';

enum ChatRealtimeEventKind {
  message,
  typing,
  read,
  delivery,
  presence,
  connected,
  relationshipInvited,
  relationshipAccepted,
  relationshipInviteCanceled,
  chatAccepted,
}

class ChatRealtimeEvent {
  final ChatRealtimeEventKind kind;
  final Map<String, dynamic> data;

  ChatRealtimeEvent({required this.kind, required this.data});

  static ChatRealtimeEvent? tryParse(dynamic raw) {
    try {
      final map = raw is String
          ? jsonDecode(raw) as Map<String, dynamic>
          : raw as Map<String, dynamic>;
      final type = map['type']?.toString() ?? '';
      final data = (map['data'] as Map<String, dynamic>?) ?? map;
      final kind = switch (type) {
        'message' => ChatRealtimeEventKind.message,
        'typing' => ChatRealtimeEventKind.typing,
        'read' => ChatRealtimeEventKind.read,
        'delivery' => ChatRealtimeEventKind.delivery,
        'presence' => ChatRealtimeEventKind.presence,
        'connected' => ChatRealtimeEventKind.connected,
        'relationship_invited' => ChatRealtimeEventKind.relationshipInvited,
        'relationship_accepted' => ChatRealtimeEventKind.relationshipAccepted,
        'relationship_invite_canceled' =>
          ChatRealtimeEventKind.relationshipInviteCanceled,
        'chat_accepted' => ChatRealtimeEventKind.chatAccepted,
        _ => null,
      };
      return kind == null ? null : ChatRealtimeEvent(kind: kind, data: data);
    } catch (_) {
      return null;
    }
  }
}

class ChatRealtimeService {
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  final _controller = StreamController<ChatRealtimeEvent>.broadcast();

  Stream<ChatRealtimeEvent> get events => _controller.stream;
  bool get isConnected => _channel != null;

  Future<void> connect({
    required String chatId,
    required String accessToken,
  }) async {
    await disconnect();
    final wsUrl = AuthService.resolveWsUrl(
      chatId: chatId,
      accessToken: accessToken,
    );
    _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
    _subscription = _channel!.stream.listen(
      _onMessage,
      onError: (_) => _controller.add(
        ChatRealtimeEvent(
          kind: ChatRealtimeEventKind.connected,
          data: {'error': true},
        ),
      ),
      onDone: disconnect,
    );
  }

  void _onMessage(dynamic raw) {
    final event = ChatRealtimeEvent.tryParse(raw);
    if (event != null) _controller.add(event);
  }

  void sendTyping({required bool isTyping}) {
    final channel = _channel;
    if (channel == null) return;
    channel.sink.add(jsonEncode({'type': 'typing', 'isTyping': isTyping}));
  }

  Future<void> disconnect() async {
    await _subscription?.cancel();
    _subscription = null;
    await _channel?.sink.close();
    _channel = null;
  }

  void dispose() {
    disconnect();
    _controller.close();
  }
}
