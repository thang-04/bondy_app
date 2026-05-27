import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'auth_service.dart';

enum ChatRealtimeEventKind { message, typing, read, delivery, presence, connected }

class ChatRealtimeEvent {
  final ChatRealtimeEventKind kind;
  final Map<String, dynamic> data;

  ChatRealtimeEvent({required this.kind, required this.data});
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
    final wsUrl = AuthService.resolveWsUrl(chatId: chatId, accessToken: accessToken);
    _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
    _subscription = _channel!.stream.listen(
      _onMessage,
      onError: (_) => _controller.add(
        ChatRealtimeEvent(kind: ChatRealtimeEventKind.connected, data: {'error': true}),
      ),
      onDone: disconnect,
    );
  }

  void _onMessage(dynamic raw) {
    try {
      final map = jsonDecode(raw as String) as Map<String, dynamic>;
      final type = map['type']?.toString() ?? '';
      final data = (map['data'] as Map<String, dynamic>?) ?? map;
      switch (type) {
        case 'message':
          _controller.add(ChatRealtimeEvent(kind: ChatRealtimeEventKind.message, data: data));
          break;
        case 'typing':
          _controller.add(ChatRealtimeEvent(kind: ChatRealtimeEventKind.typing, data: data));
          break;
        case 'read':
          _controller.add(ChatRealtimeEvent(kind: ChatRealtimeEventKind.read, data: data));
          break;
        case 'delivery':
          _controller.add(ChatRealtimeEvent(kind: ChatRealtimeEventKind.delivery, data: data));
          break;
        case 'presence':
          _controller.add(ChatRealtimeEvent(kind: ChatRealtimeEventKind.presence, data: data));
          break;
        case 'connected':
          _controller.add(ChatRealtimeEvent(kind: ChatRealtimeEventKind.connected, data: data));
          break;
      }
    } catch (_) {}
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
