import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../services/ai_service.dart';
import '../../services/api_client.dart';
import '../../services/safety_guardrails_service.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/ai/ai_quota_viewmodel.dart';
import '../../widgets/common/ai_markdown_text.dart';
import '../healing/healing_stitch_style.dart';

class HealingChatbotCoachScreen extends StatefulWidget {
  final AiService? aiService;

  const HealingChatbotCoachScreen({super.key, this.aiService});

  @override
  State<HealingChatbotCoachScreen> createState() =>
      _HealingChatbotCoachScreenState();
}

class _HealingChatbotCoachScreenState extends State<HealingChatbotCoachScreen> {
  late final AiService _aiService = widget.aiService ?? AiService(ApiClient());
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _safetyService = SafetyGuardrailsService();
  final String _sessionId = 'healing-${DateTime.now().millisecondsSinceEpoch}';

  final List<_BotMessage> _messages = [
    _BotMessage(
      'Chào bạn, mình là Bondy. Mình ở đây để lắng nghe và đồng hành cùng bạn trong hôm nay.',
      false,
    ),
    _BotMessage(
      'Bạn có thể kể ngắn gọn điều đang làm mình nặng lòng, hoặc chọn một gợi ý bên dưới.',
      false,
    ),
  ];

  bool _isSending = false;
  bool _showSafetyWarning = false;
  bool _didReadArguments = false;
  String? _pendingMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AiQuotaViewModel>().loadQuota();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didReadArguments) return;
    _didReadArguments = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic> && args['initialMessage'] is String) {
        final initialMessage = args['initialMessage'] as String;
        args.remove('initialMessage');
        _proceedWithMessage(initialMessage);
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
    final quotaViewModel = context.watch<AiQuotaViewModel>();
    final quota = quotaViewModel.quotaFor(AiChatMode.healing);

    return Scaffold(
      backgroundColor: HealingStitchColors.warmBackground,
      appBar: AppBar(
        backgroundColor: HealingStitchColors.surface,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: HealingStitchColors.warmGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.self_improvement,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bondy chữa lành',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: BondyColors.textPrimary,
                    ),
                  ),
                  Text(
                    'AI lắng nghe mỗi ngày',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: BondyColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: _QuotaBadge(
                quota: quota,
                loading: quotaViewModel.isLoading,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) =>
                      _buildBubble(_messages[index]),
                ),
              ),
              _buildPromptRail(quota),
              const SizedBox(height: 8),
              _buildComposer(quota),
            ],
          ),
          if (_showSafetyWarning) _buildSafetyWarningOverlay(),
        ],
      ),
    );
  }

  Widget _buildPromptRail(AiModeQuota? quota) {
    final disabled = _isSending || (quota != null && quota.remaining <= 0);
    final prompts = [
      'Mình đang thấy lo lắng',
      'Mình vừa trải qua chuyện buồn',
      'Giúp mình bình tĩnh lại',
      'Mình muốn viết nhật ký cảm xúc',
    ];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: prompts.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final prompt = prompts[index];
          return ActionChip(
            avatar: const Icon(
              Icons.spa_outlined,
              size: 16,
              color: BondyColors.primary,
            ),
            label: Text(
              prompt,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            backgroundColor: Colors.white,
            side: BorderSide(
              color: BondyColors.primary.withValues(alpha: 0.18),
            ),
            onPressed: disabled
                ? null
                : () {
                    _controller.text = prompt;
                    _controller.selection = TextSelection.collapsed(
                      offset: prompt.length,
                    );
                  },
          );
        },
      ),
    );
  }

  Widget _buildComposer(AiModeQuota? quota) {
    final exhausted = quota != null && quota.remaining <= 0;
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
                key: const Key('healing_chat_input'),
                controller: _controller,
                enabled: !_isSending,
                minLines: 1,
                maxLines: 5,
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(
                  hintText: exhausted
                      ? 'Bạn đã hết lượt AI chữa lành hôm nay'
                      : 'Chia sẻ với Bondy...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  filled: true,
                  fillColor: BondyColors.background,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              key: const Key('healing_chat_send'),
              onPressed: _isSending ? null : _sendMessage,
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
      ),
    );
  }

  void _sendMessage() {
    final message = _controller.text.trim();
    if (message.isEmpty) return;

    final quotaViewModel = context.read<AiQuotaViewModel>();
    final quota = quotaViewModel.quotaFor(AiChatMode.healing);
    if (quota != null && quota.remaining <= 0) {
      _showQuotaUpgradeDialog(quota: quota);
      return;
    }

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
    final quotaViewModel = context.read<AiQuotaViewModel>();
    final currentQuota = quotaViewModel.quotaFor(AiChatMode.healing);
    if (currentQuota != null && currentQuota.remaining <= 0) {
      _showQuotaUpgradeDialog(quota: currentQuota);
      return;
    }

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
          mode: AiChatMode.healing,
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
        } else if (event.type == AiStreamEventType.metadata) {
          final quota = event.metadata?.quota;
          if (quota != null) {
            quotaViewModel.applyQuota(quota);
          }
        } else if (event.type == AiStreamEventType.error) {
          setState(() {
            assistantMessage.text =
                event.error ?? 'Mình xin lỗi, có lỗi xảy ra. Bạn thử lại nhé.';
          });
        }
      }

      if (assistantMessage.text.trim().isEmpty) {
        setState(() {
          assistantMessage.text =
              'Mình đang ở đây với bạn. Bạn có thể nói thêm một chút nữa không?';
        });
      }
    } on ApiClientException catch (error) {
      if (!mounted) return;
      if (error.code == 'AI_DAILY_QUOTA_EXCEEDED' && error.data != null) {
        final exceeded = AiQuotaExceededData.fromJson(error.data!);
        final quota = exceeded.quota;
        if (quota != null) quotaViewModel.applyQuota(quota);
        setState(() {
          _messages.remove(assistantMessage);
        });
        _showQuotaUpgradeDialog(quota: quota, modal: exceeded.upgradeModal);
      } else {
        setState(() {
          assistantMessage.text = error.message;
        });
      }
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

  Widget _buildBubble(_BotMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: HealingStitchColors.warmGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.self_improvement,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.74,
              ),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: message.isUser ? BondyColors.primaryGradient : null,
                color: message.isUser ? null : const Color(0xFFFFF1EE),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(message.isUser ? 16 : 4),
                  bottomRight: Radius.circular(message.isUser ? 4 : 16),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: message.isUser
                        ? Text(
                            message.text,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: Colors.white,
                              height: 1.35,
                            ),
                          )
                        : AiMarkdownText(
                            data: message.text,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: BondyColors.textPrimary,
                              height: 1.35,
                            ),
                          ),
                  ),
                  if (message.streaming && message.text.isEmpty) ...[
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
            margin: const EdgeInsets.all(28),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.favorite_outline,
                  color: BondyColors.primary,
                  size: 40,
                ),
                const SizedBox(height: 14),
                Text(
                  'Mình thấy bạn đang trải qua giai đoạn khó khăn',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Bondy không thay thế chuyên gia tâm lý. Nếu bạn thấy không an toàn, hãy liên hệ người thân hoặc dịch vụ hỗ trợ khẩn cấp.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: BondyColors.textSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 20),
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
                        child: const Text('Gửi'),
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

  Future<void> _showQuotaUpgradeDialog({
    AiModeQuota? quota,
    AiQuotaUpgradeModal? modal,
  }) async {
    final title = modal?.title ?? 'Bạn đã hết lượt AI hôm nay';
    final message =
        modal?.message ??
        'AI chữa lành sẽ được làm mới vào ngày mai. Nâng cấp subscription để có thêm lượt mỗi ngày.';
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title),
        content: Text(
          quota == null
              ? message
              : '$message\n\nHiện tại: ${quota.remaining}/${quota.limit} lượt.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(modal?.secondaryCtaLabel ?? 'Để sau'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await Navigator.of(context).pushNamed('/settings/premium');
              if (mounted) {
                await context.read<AiQuotaViewModel>().loadQuota();
              }
            },
            child: Text(modal?.ctaLabel ?? 'Xem gói subscription'),
          ),
        ],
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

class _QuotaBadge extends StatelessWidget {
  final AiModeQuota? quota;
  final bool loading;

  const _QuotaBadge({required this.quota, required this.loading});

  @override
  Widget build(BuildContext context) {
    final text = quota == null
        ? (loading ? 'Đang tải lượt' : 'Còn --/-- lượt')
        : 'Còn ${quota!.remaining}/${quota!.limit} lượt';
    final exhausted = quota != null && quota!.remaining <= 0;

    return Container(
      key: const Key('healing_quota_badge'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: exhausted
            ? BondyColors.primary.withValues(alpha: 0.12)
            : Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: BondyColors.primary.withValues(alpha: 0.22)),
      ),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: exhausted ? BondyColors.primaryDark : BondyColors.textPrimary,
        ),
      ),
    );
  }
}

class _BotMessage {
  String text;
  final bool isUser;
  bool streaming;

  _BotMessage(this.text, this.isUser, {this.streaming = false});
}
