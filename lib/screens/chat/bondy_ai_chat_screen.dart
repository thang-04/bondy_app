import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/ai_mode_catalog.dart';
import '../../services/ai_service.dart';
import '../../services/api_client.dart';
import '../../services/safety_guardrails_service.dart';
import '../../theme/app_theme.dart';

class BondyAIChatScreen extends StatefulWidget {
  final AiService? aiService;

  const BondyAIChatScreen({super.key, this.aiService});

  @override
  State<BondyAIChatScreen> createState() => _BondyAIChatScreenState();
}

class _BondyAIChatScreenState extends State<BondyAIChatScreen> {
  late final AiService _aiService = widget.aiService ?? AiService(ApiClient());
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _safetyService = SafetyGuardrailsService();
  final _sessionId = 'bondy-${DateTime.now().millisecondsSinceEpoch}';

  final List<_BotMessage> _messages = [
    _BotMessage(
      'Chào bạn! Mình là Bondy AI. Bạn có thể hỏi mình về trò chuyện, hẹn hò, cảm xúc hoặc kế hoạch hôm nay.',
      false,
    ),
    _BotMessage('Hãy nhập câu hỏi hoặc chọn một gợi ý nhanh bên dưới.', false),
  ];

  AiChatMode _mode = AiChatMode.defaultMode;
  bool _isSending = false;
  bool _showSafetyWarning = false;
  bool _didReadArguments = false;
  String? _pendingMessage;

  AiModeDescriptor get _modeDescriptor => AiModeCatalog.byMode(_mode);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didReadArguments) return;
    _didReadArguments = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is! Map<String, dynamic>) return;

      final nextMode = args['topic'] == 'compatibility'
          ? AiChatMode.aiTuVi
          : AiChatMode.fromJson(args['mode']);
      if (mounted && nextMode != _mode) {
        setState(() => _mode = nextMode);
      }

      final initialMessage = args['initialMessage'];
      if (initialMessage is String && initialMessage.trim().isNotEmpty) {
        _proceedWithMessage(initialMessage.trim());
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F0),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: BondyColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                gradient: BondyColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _modeDescriptor.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: BondyColors.textPrimary,
                    ),
                  ),
                  Text(
                    _modeDescriptor.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: BondyColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) =>
                      _buildBubble(_messages[index]),
                ),
              ),
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: _quickPrompts
                      .map((prompt) => _buildPromptChip(prompt))
                      .toList(),
                ),
              ),
              const SizedBox(height: 8),
              _buildComposer(),
            ],
          ),
          if (_showSafetyWarning) _buildSafetyWarningOverlay(),
        ],
      ),
    );
  }

  List<String> get _quickPrompts {
    switch (_mode) {
      case AiChatMode.coach:
        return const ['Gợi ý mở lời', 'Chủ đề thấu hiểu', 'Giữ lửa'];
      case AiChatMode.plan:
        return const [
          'Lên kế hoạch cuối tuần',
          'Chia nhỏ mục tiêu',
          'Nhắc việc',
        ];
      case AiChatMode.aiTuVi:
        return const [
          'Xem độ hợp nhau',
          'Tình duyên hôm nay',
          'Ngày tốt hẹn hò',
        ];
      case AiChatMode.tarot:
        return const [
          'Giải nghĩa trải bài',
          'Thông điệp tình yêu',
          'Lời khuyên',
        ];
      case AiChatMode.healing:
        return const [
          'Mình đang lo lắng',
          'Giúp mình bình tĩnh',
          'Viết nhật ký',
        ];
      case AiChatMode.defaultMode:
        return const ['Gợi ý mở lời', 'Chỗ chơi cuối tuần', 'Bí quyết giữ lửa'];
    }
  }

  Widget _buildComposer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: BondyColors.divider.withValues(alpha: 0.5)),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                key: const Key('bondy_ai_chat_input'),
                controller: _controller,
                enabled: !_isSending,
                minLines: 1,
                maxLines: 5,
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(
                  hintText: 'Hỏi Bondy bất cứ điều gì...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  hintStyle: GoogleFonts.plusJakartaSans(
                    color: BondyColors.textHint,
                  ),
                  filled: true,
                  fillColor: BondyColors.background,
                ),
                style: GoogleFonts.plusJakartaSans(fontSize: 14),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              key: const Key('bondy_ai_chat_send'),
              onTap: _isSending ? null : _sendMessage,
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  gradient: BondyColors.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: _isSending
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send, color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromptChip(String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: _isSending ? null : () => _proceedWithMessage(label),
        child: Chip(
          backgroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFFFFD9C0)),
          label: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: BondyColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  void _sendMessage() {
    final message = _controller.text.trim();
    if (message.isEmpty) return;

    final safetyCheck = _safetyService.check(message);
    if (safetyCheck.shouldWarn) {
      setState(() {
        _pendingMessage = message;
        _showSafetyWarning = true;
      });
      return;
    }

    _proceedWithMessage(message);
  }

  Future<void> _proceedWithMessage(String message) async {
    if (_isSending || message.trim().isEmpty) return;
    final assistantMessage = _BotMessage('', false, streaming: true);
    setState(() {
      _isSending = true;
      _messages.add(_BotMessage(message, true));
      _messages.add(assistantMessage);
      _controller.clear();
    });
    _scrollToBottom();

    try {
      await for (final event in _aiService.streamChat(
        AiStreamChatRequest(
          messages: _buildRequestMessages(),
          mode: _mode,
          sessionId: _sessionId,
        ),
      )) {
        if (!mounted) return;
        if (event.type == AiStreamEventType.chunk && event.chunk != null) {
          final chunk = event.chunk!;
          setState(() {
            if (chunk.startsWith('__STRIPPED__')) {
              assistantMessage.text = chunk.substring('__STRIPPED__'.length);
            } else {
              assistantMessage.text += chunk;
            }
          });
          _scrollToBottom();
        } else if (event.type == AiStreamEventType.error) {
          setState(() {
            assistantMessage.text =
                event.error ?? 'Mình xin lỗi, có lỗi xảy ra. Bạn thử lại nhé.';
          });
        }
      }

      if (assistantMessage.text.trim().isEmpty && mounted) {
        setState(() {
          assistantMessage.text =
              'Mình đang lắng nghe. Bạn có thể nói rõ hơn một chút không?';
        });
      }
    } on ApiClientException catch (error) {
      if (!mounted) return;
      setState(() => assistantMessage.text = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        assistantMessage.text =
            'Mình xin lỗi, hiện chưa kết nối được AI. Bạn thử lại sau nhé.';
      });
    } finally {
      if (mounted) {
        setState(() {
          assistantMessage.streaming = false;
          _isSending = false;
        });
      }
    }
  }

  List<AiChatMessage> _buildRequestMessages() {
    return _messages
        .where((message) => message.text.trim().isNotEmpty)
        .map(
          (message) => AiChatMessage(
            role: message.isUser
                ? AiChatMessageRole.user
                : AiChatMessageRole.assistant,
            content: message.text,
          ),
        )
        .toList();
  }

  Widget _buildBubble(_BotMessage msg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: msg.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!msg.isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                gradient: BondyColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72,
              ),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: msg.isUser ? BondyColors.primaryGradient : null,
                color: msg.isUser ? null : const Color(0xFFFFF1EE),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(msg.isUser ? 16 : 4),
                  bottomRight: Radius.circular(msg.isUser ? 4 : 16),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      msg.text,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: msg.isUser
                            ? Colors.white
                            : BondyColors.textPrimary,
                        height: 1.35,
                      ),
                    ),
                  ),
                  if (msg.streaming && msg.text.isEmpty) ...[
                    const SizedBox(width: 8),
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyWarningOverlay() {
    return GestureDetector(
      onTap: () => setState(() => _showSafetyWarning = false),
      child: Container(
        color: BondyColors.overlay,
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(32),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.favorite,
                  color: BondyColors.primary,
                  size: 40,
                ),
                const SizedBox(height: 16),
                Text(
                  'Mình thấy bạn đang trải qua giai đoạn khó khăn',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Bondy không thay thế chuyên gia tâm lý. Nếu bạn thấy không an toàn, hãy liên hệ người thân hoặc dịch vụ hỗ trợ khẩn cấp.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: BondyColors.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () =>
                            setState(() => _showSafetyWarning = false),
                        child: const Text('Quay lại'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final message = _pendingMessage;
                          setState(() {
                            _showSafetyWarning = false;
                            _pendingMessage = null;
                          });
                          if (message != null) _proceedWithMessage(message);
                        },
                        child: const Text('Gửi tin nhắn'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
}

class _BotMessage {
  String text;
  final bool isUser;
  bool streaming;

  _BotMessage(this.text, this.isUser, {this.streaming = false});
}
