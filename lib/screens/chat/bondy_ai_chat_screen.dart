import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/ai_mode_catalog.dart';
import '../../services/ai_service.dart';
import '../../services/api_client.dart';
import '../../services/safety_guardrails_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/ai_markdown_text.dart';
import '../../widgets/common/ai_quota_paywall_dialog.dart';

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

  List<_BotMessage> _messages = [
    _BotMessage(
      'Chào bạn! Mình là Bondy AI. Bạn có thể hỏi mình về trò chuyện, hẹn hò, cảm xúc hoặc kế hoạch hôm nay.',
      false,
    ),
    _BotMessage('Hãy nhập câu hỏi hoặc chọn một gợi ý nhanh bên dưới.', false),
  ];

  String? _conversationId;
  bool _isLoadingHistory = false;

  AiChatMode _mode = AiChatMode.defaultMode;
  bool _isSending = false;
  bool _showSafetyWarning = false;
  bool _didReadArguments = false;
  String? _pendingMessage;
  List<String> _intakeSummary = const [];

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

      final summary = _summaryFromArgs(args['intakeSummary']);
      if (summary.isNotEmpty && mounted) {
        setState(() => _intakeSummary = summary);
      }

      final conversationId = args['conversationId']?.toString();
      if (conversationId != null && conversationId.isNotEmpty) {
        _loadConversationHistory(conversationId);
      } else {
        final initialMessage = args['initialMessage'];
        final displayMessage = args['displayMessage']?.toString().trim();
        if (initialMessage is String && initialMessage.trim().isNotEmpty) {
          _proceedWithMessage(
            initialMessage.trim(),
            displayMessage: displayMessage?.isNotEmpty == true
                ? displayMessage
                : null,
          );
        }
      }
    });
  }

  Future<void> _loadConversationHistory(String conversationId) async {
    setState(() {
      _isLoadingHistory = true;
      _conversationId = conversationId;
    });
    try {
      final detail = await _aiService.getConversation(conversationId);
      if (!mounted) return;
      setState(() {
        _messages = detail.messages
            .map((m) => _BotMessage(m.content, m.isUser))
            .toList();
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (e) {
      // Ignore error, keep default greeting
    } finally {
      if (mounted) {
        setState(() => _isLoadingHistory = false);
      }
    }
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
              clipBehavior: Clip.antiAlias,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: Image.asset(
                _modeDescriptor.avatarAsset,
                fit: BoxFit.cover,
              ),
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
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add_circle_outline,
              color: BondyColors.primary,
            ),
            onPressed: () {
              setState(() {
                _conversationId = null;
                _messages = [
                  _BotMessage(
                    'Chào bạn! Mình là Bondy AI. Bạn có thể hỏi mình về trò chuyện, hẹn hò, cảm xúc hoặc kế hoạch hôm nay.',
                    false,
                  ),
                  _BotMessage(
                    'Hãy nhập câu hỏi hoặc chọn một gợi ý nhanh bên dưới.',
                    false,
                  ),
                ];
              });
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: _isLoadingHistory
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation(
                            BondyColors.primary,
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount:
                            _messages.length + (_intakeSummary.isEmpty ? 0 : 1),
                        itemBuilder: (context, index) {
                          if (_intakeSummary.isNotEmpty && index == 0) {
                            return _buildIntakeSummaryCard();
                          }
                          final messageIndex =
                              index - (_intakeSummary.isEmpty ? 0 : 1);
                          return _buildBubble(_messages[messageIndex]);
                        },
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
        onTap: _isSending
            ? null
            : () {
                _controller.text = label;
              },
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

  Future<void> _proceedWithMessage(
    String message, {
    String? displayMessage,
  }) async {
    if (_isSending || message.trim().isEmpty) return;
    final assistantMessage = _BotMessage('', false, streaming: true);
    setState(() {
      _isSending = true;
      _messages.add(
        _BotMessage(displayMessage ?? message, true, requestText: message),
      );
      _messages.add(assistantMessage);
      _controller.clear();
    });
    _scrollToBottom();

    try {
      if (_conversationId == null) {
        final conv = await _aiService.createConversation(
          mode: _mode.apiValue,
          title: message,
        );
        _conversationId = conv.id;
      }

      await for (final event in _aiService.streamChat(
        AiStreamChatRequest(
          messages: _buildRequestMessages(),
          mode: _mode,
          sessionId: _sessionId,
          conversationId: _conversationId,
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
      if (error.code == 'AI_CHAT_QUOTA_EXCEEDED' && error.data != null) {
        final exceeded = AiQuotaExceededData.fromJson(error.data!);
        setState(() {
          assistantMessage.text = exceeded.paywall?.message ?? error.message;
        });
        await showAiQuotaPaywallDialog(context, data: exceeded);
      } else {
        setState(() => assistantMessage.text = error.message);
      }
    } catch (e, st) {
      debugPrint('[BondyAIChat] Unexpected error: $e');
      debugPrint('[BondyAIChat] Stack: $st');
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
            content: message.requestText ?? message.text,
          ),
        )
        .toList();
  }

  Widget _buildIntakeSummaryCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BondyColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thông tin đã cung cấp',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: BondyColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          ..._intakeSummary.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                line,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: BondyColors.textSecondary,
                  height: 1.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
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
              clipBehavior: Clip.antiAlias,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: Image.asset(
                _modeDescriptor.avatarAsset,
                fit: BoxFit.cover,
              ),
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
                    child: msg.isUser
                        ? Text(
                            msg.text,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: Colors.white,
                              height: 1.35,
                            ),
                          )
                        : AiMarkdownText(
                            data: msg.text,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: BondyColors.textPrimary,
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
  final String? requestText;
  bool streaming;

  _BotMessage(
    this.text,
    this.isUser, {
    this.requestText,
    this.streaming = false,
  });
}

List<String> _summaryFromArgs(Object? value) {
  if (value is! List) return const [];
  return value
      .map((item) => item.toString())
      .where((item) => item.isNotEmpty)
      .toList();
}
