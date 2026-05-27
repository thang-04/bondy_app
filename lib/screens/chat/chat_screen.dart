import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../services/block_service.dart';
import '../../services/chat_service.dart';
import '../../services/chat_realtime_service.dart';
import '../../services/match_service.dart';
import '../../viewmodels/chat/chat_viewmodel.dart';
import '../../widgets/chat/voice_message_bubble.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/bondy_error_mapper.dart';
import '../../widgets/common/bondy_feedback.dart';
import '../../theme/app_theme.dart';
import '../healing/healing_stitch_style.dart';
import '../../core/ai_prompts_config.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  late final ApiClient _apiClient = ApiClient();
  late final ChatService _chatService = ChatService(_apiClient);
  late final MatchService _matchService = MatchService(_apiClient);
  late final BlockService _blockService = BlockService(_apiClient);
  late final AuthService _authService = AuthService();
  final ChatRealtimeService _realtime = ChatRealtimeService();
  final AudioRecorder _audioRecorder = AudioRecorder();

  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];

  bool _didReadArguments = false;
  bool _isLoading = true;
  bool _isSending = false;
  String? _errorMessage;
  String? _chatId;
  String? _matchId;
  String? _otherUserId;
  String? _currentUserId;
  String _displayName = 'Bondy user';
  String? _photo;
  Timer? _pollTimer;
  Timer? _typingTimer;
  bool _isTypingSent = false;
  bool _partnerTyping = false;
  bool _wsConnected = false;
  bool _isPartnerOnline = false;
  DateTime? _partnerLastSeenAt;
  bool _isRecording = false;
  bool _showEmojiKeyboard = false;
  final ImagePicker _imagePicker = ImagePicker();
  StreamSubscription<ChatRealtimeEvent>? _realtimeSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didReadArguments) return;
    _didReadArguments = true;
    _readRouteArguments();
    _bootstrap();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startPolling();
      _pollMessages();
    } else if (state == AppLifecycleState.paused) {
      _pollTimer?.cancel();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    _typingTimer?.cancel();
    _realtimeSub?.cancel();
    _realtime.dispose();
    final chatId = _chatId;
    if (chatId != null && _isTypingSent) {
      _chatService.sendTypingIndicator(chatId, isTyping: false);
      _realtime.sendTyping(isTyping: false);
    }
    _audioRecorder.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    // Fallback sync when WebSocket is down
    _pollTimer = Timer.periodic(
      const Duration(seconds: 12),
      (_) => _pollMessages(),
    );
  }

  Future<void> _connectRealtime(String chatId) async {
    try {
      final token = await _authService.requireAccessToken();
      await _realtime.connect(chatId: chatId, accessToken: token);
      await _realtimeSub?.cancel();
      _realtimeSub = _realtime.events.listen(_handleRealtimeEvent);
      if (mounted) setState(() => _wsConnected = _realtime.isConnected);
    } catch (_) {
      if (mounted) setState(() => _wsConnected = false);
    }
  }

  void _handleRealtimeEvent(ChatRealtimeEvent event) {
    if (!mounted) return;
    switch (event.kind) {
      case ChatRealtimeEventKind.message:
        final msg = ChatMessage.fromJson(event.data);
        if (_messages.any((m) => m.id == msg.id)) return;
        setState(() => _messages.add(msg));
        _scrollToBottom();
        final chatId = _chatId;
        if (msg.senderId != _currentUserId && !msg.isRead && chatId != null) {
          _chatService.markAllAsRead(chatId).then((_) {
            if (mounted) {
              context.read<ChatViewModel>().clearUnread(chatId);
            }
          }).catchError((_) {});
        }
        break;
      case ChatRealtimeEventKind.typing:
        final isTyping = event.data['isTyping'] == true;
        if (event.data['userId']?.toString() == _currentUserId) return;
        setState(() => _partnerTyping = isTyping);
        break;
      case ChatRealtimeEventKind.read:
        final readerId = event.data['readerId']?.toString();
        final allRead = event.data['allRead'] == true;
        if (allRead) {
          if (readerId == _currentUserId) return;
          setState(() {
            for (var i = 0; i < _messages.length; i++) {
              if (_messages[i].senderId == _currentUserId &&
                  !_messages[i].isRead) {
                _messages[i] = ChatMessage(
                  id: _messages[i].id,
                  content: _messages[i].content,
                  senderId: _messages[i].senderId,
                  isRead: true,
                  createdAt: _messages[i].createdAt,
                  messageType: _messages[i].messageType,
                  deliveryStatus: _messages[i].deliveryStatus,
                );
              }
            }
          });
          break;
        }
        final messageId = event.data['messageId']?.toString();
        if (messageId == null) return;
        setState(() {
          for (var i = 0; i < _messages.length; i++) {
            if (_messages[i].id == messageId) {
              _messages[i] = ChatMessage(
                id: _messages[i].id,
                content: _messages[i].content,
                senderId: _messages[i].senderId,
                isRead: true,
                createdAt: _messages[i].createdAt,
                messageType: _messages[i].messageType,
                deliveryStatus: _messages[i].deliveryStatus,
              );
            }
          }
        });
        break;
      case ChatRealtimeEventKind.delivery:
        final messageId = event.data['messageId']?.toString();
        final status = event.data['status']?.toString();
        if (messageId == null || status == null) return;
        setState(() {
          for (var i = 0; i < _messages.length; i++) {
            if (_messages[i].id == messageId) {
              _messages[i] = ChatMessage(
                id: _messages[i].id,
                content: _messages[i].content,
                senderId: _messages[i].senderId,
                isRead: _messages[i].isRead,
                createdAt: _messages[i].createdAt,
                messageType: _messages[i].messageType,
                deliveryStatus: status,
              );
            }
          }
        });
        break;
      case ChatRealtimeEventKind.presence:
        final eventUserId = event.data['userId']?.toString();
        if (eventUserId == _currentUserId) return;
        final isOnline = event.data['isOnline'] == true;
        final lastSeenRaw = event.data['lastSeenAt']?.toString();
        final lastSeen = lastSeenRaw != null ? DateTime.tryParse(lastSeenRaw) : null;
        setState(() {
          _isPartnerOnline = isOnline;
          _partnerLastSeenAt = lastSeen ?? _partnerLastSeenAt;
        });
        final chatId = _chatId;
        if (chatId != null) {
          context.read<ChatViewModel>().updatePartnerPresence(
                chatId: chatId,
                isOnline: isOnline,
                lastSeenAt: lastSeenRaw,
              );
        }
        break;
      case ChatRealtimeEventKind.connected:
        setState(() => _wsConnected = true);
        break;
    }
  }

  Future<void> _pollMessages() async {
    final chatId = _chatId;
    if (chatId == null || _isLoading || _isSending) return;
    try {
      final messages = await _chatService.listMessages(chatId);
      if (!mounted) return;
      final existingIds = _messages.map((m) => m.id).toSet();
      final added = messages.where((m) => !existingIds.contains(m.id)).toList();
      if (added.isEmpty) return;
      setState(() => _messages.addAll(added));
      _scrollToBottom();
      final hasIncoming =
          added.any((m) => m.senderId != _currentUserId && !m.isRead);
      if (hasIncoming) {
        await _chatService.markAllAsRead(chatId);
        if (mounted) {
          context.read<ChatViewModel>().clearUnread(chatId);
        }
      }
      if (!_wsConnected) {
        final typing = await _chatService.fetchPartnerTyping(chatId);
        if (mounted && typing != _partnerTyping) {
          setState(() => _partnerTyping = typing);
        }
      }
    } catch (error, stackTrace) {
      // F-02 fix: log poll errors instead of silently swallowing them so a
      // broken realtime + poll fallback is at least visible in debug builds.
      debugPrint('chat:poll-error: $error');
      if (kDebugMode) debugPrintStack(stackTrace: stackTrace, maxFrames: 4);
    }
  }

  Future<void> _pickAndSendImage() async {
    final chatId = _chatId;
    if (chatId == null || _isSending) return;

    // Máy thật Android 13+ cần READ_MEDIA_IMAGES, iOS cần Photos permission.
    // image_picker không tự xin nên phải request trước, không thì pickImage
    // trả null lặng lẽ → user tưởng app hỏng.
    final mediaPermission = await Permission.photos.request();
    if (!mediaPermission.isGranted && !mediaPermission.isLimited) {
      if (!mounted) return;
      BondyFeedback.showError(
        context,
        Exception('Cần quyền truy cập ảnh để gửi hình.'),
      );
      return;
    }

    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 85,
    );
    if (picked == null) return;
    setState(() => _isSending = true);
    try {
      final message = await _chatService.sendImageMessage(chatId, picked);
      if (!mounted) return;
      setState(() => _messages.add(message));
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      BondyFeedback.showError(context, e, fallback: 'Không gửi được ảnh.');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }



  void _readRouteArguments() {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      _chatId = args['chatId'] as String?;
      _matchId = args['matchId'] as String?;
      _otherUserId = args['otherUserId'] as String?;
      _displayName = (args['name'] as String?)?.trim().isNotEmpty == true
          ? args['name'] as String
          : _displayName;
      _photo = args['photo'] as String?;
      _isPartnerOnline = args['isOnline'] as bool? ?? false;
      final rawLastSeen = args['lastSeenAt'] as String?;
      if (rawLastSeen != null) {
        _partnerLastSeenAt = DateTime.tryParse(rawLastSeen);
      }
    } else if (args is String) {
      _chatId = args;
    }
  }

  Future<void> _bootstrap() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      _currentUserId = await _authService.getCurrentUserId();
      await _hydrateChatMetadata();
      await _loadMessages();
      final chatId = _chatId;
      if (chatId != null) {
        // Bulk mark-as-read on entering the room (single API call instead of
        // one PUT per message). Backend broadcasts a 'read allRead' event so
        // the other side flips ticks in one shot.
        try {
          await _chatService.markAllAsRead(chatId);
          if (mounted) {
            context.read<ChatViewModel>().clearUnread(chatId);
          }
        } catch (_) {}
        // Fetch presence snapshot once — WebSocket presence events keep it
        // fresh after this.
        try {
          final presence = await _chatService.fetchPartnerPresence(chatId);
          if (mounted) {
            setState(() {
              _isPartnerOnline = presence.isOnline;
              final raw = presence.lastSeenAt;
              if (raw != null) _partnerLastSeenAt = DateTime.tryParse(raw);
            });
          }
        } catch (_) {}
        await _connectRealtime(chatId);
      }
      _startPolling();
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = BondyErrorMapper.message(e));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _hydrateChatMetadata() async {
    if (_chatId == null || (_matchId != null && _otherUserId != null)) return;

    final chats = await _chatService.listChats();
    for (final chat in chats) {
      if (chat.id != _chatId) continue;
      _matchId ??= chat.matchId;
      _otherUserId ??= chat.otherUser.id;
      final name = chat.otherUser.displayName;
      if (name.isNotEmpty) _displayName = name;
      _photo ??= chat.otherUser.photo;
      break;
    }
  }

  Future<void> _loadMessages() async {
    final chatId = _chatId;
    if (chatId == null) {
      throw StateError('Missing chat ID');
    }

    final messages = await _chatService.listMessages(chatId);
    if (!mounted) return;
    setState(() {
      _messages
        ..clear()
        ..addAll(messages);
    });
    _scrollToBottom();
  }

  void _onTextChanged(String value) {
    final chatId = _chatId;
    if (chatId == null) return;
    _typingTimer?.cancel();
    if (value.trim().isEmpty) {
      if (_isTypingSent) {
        _isTypingSent = false;
        _chatService.sendTypingIndicator(chatId, isTyping: false);
      }
      return;
    }
    _typingTimer = Timer(const Duration(milliseconds: 400), () async {
      if (!_isTypingSent) {
        _isTypingSent = true;
        _realtime.sendTyping(isTyping: true);
        await _chatService.sendTypingIndicator(chatId, isTyping: true);
      }
    });
  }

  Future<void> _toggleVoiceRecording() async {
    if (_isRecording) {
      String? path;
      try {
        path = await _audioRecorder.stop();
      } catch (e) {
        if (!mounted) return;
        setState(() => _isRecording = false);
        BondyFeedback.showError(context, e, fallback: 'Không dừng được ghi âm.');
        return;
      }
      setState(() => _isRecording = false);
      final chatId = _chatId;
      if (path == null || chatId == null) {
        if (mounted) {
          BondyFeedback.showError(
            context,
            Exception('Không lưu được file ghi âm.'),
          );
        }
        return;
      }
      setState(() => _isSending = true);
      try {
        final message = await _chatService.sendVoiceMessage(chatId, path);
        if (!mounted) return;
        setState(() => _messages.add(message));
        _scrollToBottom();
      } catch (e) {
        if (!mounted) return;
        BondyFeedback.showError(
          context,
          e,
          fallback: 'Không gửi được tin nhắn thoại.',
        );
      } finally {
        if (mounted) setState(() => _isSending = false);
      }
      return;
    }

    // Dùng API hasPermission của record plugin (đồng bộ với native), tránh
    // tình huống permission_handler báo granted nhưng record vẫn từ chối trên
    // một số ROM. Nếu plugin báo chưa có thì mới rơi xuống permission_handler.
    final pluginPermission = await _audioRecorder.hasPermission();
    if (!pluginPermission) {
      final mic = await Permission.microphone.request();
      if (!mic.isGranted) {
        if (!mounted) return;
        BondyFeedback.showError(
          context,
          Exception('Cần quyền micro để ghi âm tin nhắn thoại.'),
        );
        return;
      }
    }

    try {
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: path,
      );
      // Xác nhận recorder thật sự đang chạy — máy thật có khi start() return
      // nhưng nhà sản xuất chặn ngầm (ví dụ Xiaomi MIUI auto-deny). Nếu không
      // chạy thì báo lỗi rõ thay vì để user bấm stop ra file rỗng.
      final actuallyRecording = await _audioRecorder.isRecording();
      if (!actuallyRecording) {
        if (!mounted) return;
        BondyFeedback.showError(
          context,
          Exception('Không khởi động được micro. Kiểm tra quyền hoặc thử lại.'),
        );
        return;
      }
      setState(() => _isRecording = true);
    } catch (e) {
      if (!mounted) return;
      BondyFeedback.showError(context, e, fallback: 'Không bắt đầu được ghi âm.');
    }
  }

  Future<void> _sendMessage([String? preset]) async {
    final chatId = _chatId;
    final content = (preset ?? _controller.text).trim();
    if (chatId == null || content.isEmpty || _isSending) return;

    setState(() => _isSending = true);

    try {
      final message = await _chatService.sendMessage(chatId, content);
      if (!mounted) return;
      setState(() {
        _messages.add(message);
        if (preset == null) _controller.clear();
      });
      _scrollToBottom();
      await _chatService.updateDeliveryStatus(message.id, 'DELIVERED');
      if (_isTypingSent) {
        _isTypingSent = false;
        await _chatService.sendTypingIndicator(chatId, isTyping: false);
      }
    } catch (e) {
      if (!mounted) return;
      BondyFeedback.showError(
        context,
        e,
        fallback: 'Không thể gửi tin nhắn. Vui lòng thử lại.',
      );
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HealingStitchColors.warmBackground,
      appBar: AppBar(
        backgroundColor: HealingStitchColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            _buildAvatar(_photo, _displayName, radius: 16),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: BondyColors.textPrimary,
                    ),
                  ),
                  _buildPresenceSubtitle(),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            key: const Key('more_options_button'),
            onPressed: _isLoading ? null : () => _showMoreOptions(context),
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessagesBody()),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildMessagesBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: BondyErrorBanner(message: _errorMessage!, onRetry: _bootstrap),
        ),
      );
    }

    if (_messages.isEmpty) {
      return Center(
        child: Text(
          'Hãy bắt đầu bằng một lời chào nhé.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: BondyColors.textSecondary,
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) => _buildBubble(_messages[index]),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: BondyColors.divider.withValues(alpha: 0.5)),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 42,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: AIPromptsConfig.deeperPrompts.length,
                itemBuilder: (context, index) {
                  final prompt = AIPromptsConfig.deeperPrompts[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      avatar: const Icon(Icons.psychology, size: 16, color: BondyColors.primary),
                      label: Text(
                        prompt,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: BondyColors.textPrimary,
                        ),
                      ),
                      backgroundColor: Colors.white,
                      side: BorderSide(color: BondyColors.primary.withValues(alpha: 0.2)),
                      onPressed: () {
                        setState(() {
                          _controller.text = prompt;
                        });
                        _controller.selection = TextSelection.fromPosition(
                          TextPosition(offset: _controller.text.length),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            if (_showEmojiKeyboard) ...[
              SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    '❤️', '😂', '👍', '😍', '🔥', '😭', '😮', '👏', '🎉', '✨', '🙌', '💯', '🤣', '🤔', '🙏', '🌸', '☕', '🍕', '🍰', '🎈'
                  ].map((emoji) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () {
                          final text = _controller.text;
                          final selection = _controller.selection;
                          int start = selection.start;
                          int end = selection.end;
                          if (start < 0 || end < 0) {
                            start = text.length;
                            end = text.length;
                          }
                          final newText = text.replaceRange(start, end, emoji);
                          _controller.text = newText;
                          _controller.selection = TextSelection.fromPosition(
                            TextPosition(offset: start + emoji.length),
                          );
                          setState(() {});
                        },
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            emoji,
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                IconButton(
                  onPressed: _isSending ? null : _pickAndSendImage,
                  icon: const Icon(Icons.image_outlined),
                ),
                IconButton(
                  onPressed: _isSending ? null : _toggleVoiceRecording,
                  icon: Icon(
                     _isRecording ? Icons.stop_circle : Icons.mic_none,
                     color: _isRecording ? Colors.red : null,
                  ),
                ),
                Expanded(
                  child: TextField(
                    key: const Key('message_input'),
                    controller: _controller,
                    onChanged: (value) {
                      setState(() {});
                      _onTextChanged(value);
                    },
                    onTap: () {
                      if (_showEmojiKeyboard) {
                        setState(() {
                          _showEmojiKeyboard = false;
                        });
                      }
                    },
                    onSubmitted: (_) {
                      _sendMessage();
                    },
                    enabled: !_isSending && _chatId != null,
                    decoration: InputDecoration(
                      hintText: 'Nhập tin nhắn...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      hintStyle: GoogleFonts.plusJakartaSans(
                        color: BondyColors.textHint,
                      ),
                      filled: true,
                      fillColor: BondyColors.background,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showEmojiKeyboard
                              ? Icons.keyboard_alt_outlined
                              : Icons.sentiment_satisfied_alt_outlined,
                          color: BondyColors.primary,
                        ),
                        onPressed: () {
                          setState(() {
                            _showEmojiKeyboard = !_showEmojiKeyboard;
                          });
                        },
                      ),
                    ),
                    style: GoogleFonts.plusJakartaSans(fontSize: 14),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  key: const Key('send_button'),
                  onPressed: _controller.text.trim().isEmpty || _isSending
                      ? null
                      : () {
                          _sendMessage();
                        },
                  icon: _isSending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBubble(ChatMessage msg) {
    final isMine = msg.senderId == _currentUserId;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        key: const Key('chat_bubble'),
        mainAxisAlignment: isMine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) ...[
            _buildAvatar(_photo, _displayName, radius: 14),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: isMine
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFF97316), Color(0xFFEA2A5A)],
                      )
                    : null,
                color: isMine ? null : const Color(0xFFFFF1EE),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMine ? 16 : 4),
                  bottomRight: Radius.circular(isMine ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (msg.messageType == 'IMAGE' &&
                      msg.content.startsWith('http'))
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        msg.content,
                        height: 180,
                        width: 220,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            const Icon(Icons.broken_image),
                      ),
                    )
                  else if (msg.messageType == 'VOICE' &&
                      msg.content.startsWith('http'))
                    VoiceMessageBubble(audioUrl: msg.content, isMine: isMine)
                  else
                    Text(
                      msg.content,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: msg.messageType == 'EMOJI' ? 28 : 14,
                        color: isMine ? Colors.white : BondyColors.textPrimary,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(msg.createdAt),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          color: isMine
                              ? Colors.white.withValues(alpha: 0.7)
                              : BondyColors.textHint,
                        ),
                      ),
                      if (isMine) ...[
                        const SizedBox(width: 4),
                        Icon(
                          msg.isRead
                              ? Icons.done_all
                              : (msg.deliveryStatus == 'DELIVERED'
                                    ? Icons.done_all
                                    : Icons.done),
                          size: 12,
                          color: msg.isRead
                              ? Colors.lightBlueAccent
                              : Colors.white.withValues(alpha: 0.7),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(
    String? photo,
    String displayName, {
    required double radius,
  }) {
    if (photo != null && photo.startsWith('http')) {
      return CircleAvatar(radius: radius, backgroundImage: NetworkImage(photo));
    }

    final initial = displayName.trim().isEmpty
        ? 'B'
        : displayName.trim()[0].toUpperCase();
    return CircleAvatar(
      radius: radius,
      backgroundColor: BondyColors.primaryLight,
      child: Text(
        initial,
        style: TextStyle(fontSize: radius, fontWeight: FontWeight.w700),
      ),
    );
  }

  Future<void> _showMoreOptions(BuildContext context) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.link_off),
              title: const Text('Bỏ kết nối'),
              onTap: () => Navigator.pop(context, 'unmatch'),
            ),
            ListTile(
              leading: const Icon(Icons.block),
              title: const Text('Chặn người dùng'),
              onTap: () => Navigator.pop(context, 'block'),
            ),
          ],
        ),
      ),
    );

    if (!context.mounted) return;
    if (result == 'unmatch') {
      await _confirmUnmatch(context);
    } else if (result == 'block') {
      await _confirmBlock(context);
    }
  }

  Future<void> _confirmUnmatch(BuildContext context) async {
    final confirmed = await _confirmDangerAction(
      context,
      title: 'Xác nhận bỏ kết nối?',
      content: 'Tin nhắn sẽ được ẩn với người này.',
      action: 'Bỏ kết nối',
    );
    if (confirmed != true) return;

    await _hydrateChatMetadata();
    final matchId = _matchId;
    if (matchId == null) {
      _showSnackBar('Không tìm thấy match để bỏ kết nối.');
      return;
    }

    await _runRelationshipAction(() => _matchService.unmatch(matchId));
  }

  Future<void> _confirmBlock(BuildContext context) async {
    final confirmed = await _confirmDangerAction(
      context,
      title: 'Xác nhận chặn người dùng?',
      content: 'Người này sẽ không thể thấy hoặc nhắn tin với bạn.',
      action: 'Chặn',
    );
    if (confirmed != true) return;

    await _hydrateChatMetadata();
    final blockedUserId = _otherUserId;
    if (blockedUserId == null) {
      _showSnackBar('Không tìm thấy người dùng để chặn.');
      return;
    }

    await _runRelationshipAction(
      () => _blockService.createBlock(blockedUserId: blockedUserId),
    );
  }

  Future<bool?> _confirmDangerAction(
    BuildContext context, {
    required String title,
    required String content,
    required String action,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(action),
          ),
        ],
      ),
    );
  }

  Future<void> _runRelationshipAction(Future<dynamic> Function() action) async {
    setState(() => _isLoading = true);
    try {
      await action();
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil('/matches', (route) => false);
    } catch (_) {
      if (!mounted) return;
      _showSnackBar('Khong the thuc hien thao tac. Vui long thu lai.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message) {
    BondyFeedback.showError(context, message);
  }

  String _formatTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Widget _buildPresenceSubtitle() {
    String text;
    Color color;
    if (_partnerTyping) {
      text = 'Đang nhập...';
      color = BondyColors.primary;
    } else if (!_wsConnected) {
      text = 'Đang kết nối...';
      color = BondyColors.textSecondary;
    } else if (_isPartnerOnline) {
      text = 'Đang hoạt động';
      color = const Color(0xFF22C55E);
    } else {
      text = _formatLastSeen(_partnerLastSeenAt);
      color = BondyColors.textSecondary;
    }
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: color),
    );
  }

  String _formatLastSeen(DateTime? lastSeenAt) {
    if (lastSeenAt == null) return 'Ngoại tuyến';
    final diff = DateTime.now().difference(lastSeenAt);
    if (diff.inSeconds < 60) return 'Hoạt động vừa xong';
    if (diff.inMinutes < 60) return 'Hoạt động ${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return 'Hoạt động ${diff.inHours} giờ trước';
    if (diff.inDays < 7) return 'Hoạt động ${diff.inDays} ngày trước';
    return 'Ngoại tuyến';
  }
}
