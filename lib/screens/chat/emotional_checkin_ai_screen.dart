import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/ai_service.dart';
import '../../services/api_client.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/ai_markdown_text.dart';
import '../../widgets/common/ai_quota_paywall_dialog.dart';
import '../../widgets/common/ai_thinking_dialog.dart';

class EmotionalCheckinAiScreen extends StatefulWidget {
  final AiService? aiService;

  const EmotionalCheckinAiScreen({super.key, this.aiService});

  @override
  State<EmotionalCheckinAiScreen> createState() =>
      _EmotionalCheckinAiScreenState();
}

class _EmotionalCheckinAiScreenState extends State<EmotionalCheckinAiScreen>
    with SingleTickerProviderStateMixin {
  static const _emojis = ['😡', '😔', '😐', '😊', '😄'];
  static const _emojiLabels = [
    'Tức giận',
    'Buồn',
    'Bình thường',
    'Vui',
    'Rất vui',
  ];

  late final AiService _aiService = widget.aiService ?? AiService(ApiClient());
  final _textController = TextEditingController();
  final _thinking = AiThinkingController();
  static const _thinkingMessages = <String>[
    'Mình đang lắng nghe bạn…',
    'Mình đang cảm nhận điều bạn chia sẻ…',
    'Sắp có lời hồi đáp cho bạn…',
    'Chờ mình thêm chút nhé…',
  ];
  final _sessionId = 'emotion-${DateTime.now().millisecondsSinceEpoch}';
  late final AnimationController _responseAnimController;
  late final Animation<double> _responseSlideAnim;
  late final Animation<double> _responseFadeAnim;

  int? _selectedIndex;
  bool _submitted = false;
  bool _isSending = false;
  String _aiResponse = '';

  @override
  void initState() {
    super.initState();
    _responseAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _responseSlideAnim = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(
        parent: _responseAnimController,
        curve: Curves.easeOutCubic,
      ),
    );
    _responseFadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _responseAnimController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _responseAnimController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final selected = _selectedIndex;
    if (selected == null || _isSending) return;

    final prompt = _buildPrompt(selected);
    setState(() {
      _submitted = true;
      _isSending = true;
      _aiResponse = '';
    });
    _responseAnimController.forward(from: 0);
    _thinking.show(context, messages: _thinkingMessages);

    var firstChunk = true;
    try {
      await for (final event in _aiService.streamChat(
        AiStreamChatRequest(
          messages: [AiChatMessage.user(prompt)],
          mode: AiChatMode.healing,
          sessionId: _sessionId,
        ),
      )) {
        if (!mounted) return;
        if (event.type == AiStreamEventType.chunk && event.chunk != null) {
          if (firstChunk) {
            firstChunk = false;
            _thinking.hide(context);
          }
          final chunk = event.chunk!;
          setState(() {
            if (chunk.startsWith('__STRIPPED__')) {
              _aiResponse = chunk.substring('__STRIPPED__'.length);
            } else {
              _aiResponse += chunk;
            }
          });
        } else if (event.type == AiStreamEventType.error) {
          setState(() {
            _aiResponse =
                event.error ?? 'Mình xin lỗi, có lỗi xảy ra. Bạn thử lại nhé.';
          });
        }
      }

      if (_aiResponse.trim().isEmpty && mounted) {
        setState(() {
          _aiResponse =
              'Cảm ơn bạn đã chia sẻ. Mình đang ở đây để lắng nghe bạn thêm một chút nữa.';
        });
      }
    } on ApiClientException catch (error) {
      if (!mounted) return;
      if (error.code == 'AI_CHAT_QUOTA_EXCEEDED' && error.data != null) {
        final exceeded = AiQuotaExceededData.fromJson(error.data!);
        setState(
          () => _aiResponse = exceeded.paywall?.message ?? error.message,
        );
        _thinking.hide(context);
        await showAiQuotaPaywallDialog(context, data: exceeded);
      } else {
        setState(() => _aiResponse = error.message);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _aiResponse =
            'Mình xin lỗi, hiện chưa kết nối được AI. Bạn thử lại sau nhé.';
      });
    } finally {
      if (mounted) {
        _thinking.hide(context);
        setState(() => _isSending = false);
      }
    }
  }

  String _buildPrompt(int selected) {
    final mood = _emojiLabels[selected];
    final note = _textController.text.trim();
    if (note.isEmpty) {
      return 'Hôm nay mình cảm thấy: $mood. Hãy phản hồi như một AI chữa lành của Bondy.';
    }
    return 'Hôm nay mình cảm thấy: $mood. Mình muốn chia sẻ thêm: $note';
  }

  void _handleReset() {
    setState(() {
      _submitted = false;
      _selectedIndex = null;
      _aiResponse = '';
      _textController.clear();
    });
    _responseAnimController.reset();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F3),
      appBar: _buildAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              _buildAvatar(),
              const SizedBox(height: 24),
              _buildQuestion(),
              const SizedBox(height: 28),
              _buildEmojiSelector(),
              const SizedBox(height: 28),
              _buildTextField(),
              const SizedBox(height: 24),
              _buildSubmitButton(),
              if (_submitted) ...[
                const SizedBox(height: 28),
                _buildAiResponseCard(),
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() => AppBar(
    backgroundColor: Colors.white,
    elevation: 0,
    centerTitle: true,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back_ios, size: 20),
      color: BondyColors.textPrimary,
      onPressed: () => Navigator.pop(context),
    ),
    title: Text(
      'Tâm trạng hôm nay',
      style: GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: BondyColors.textPrimary,
      ),
    ),
  );

  Widget _buildAvatar() => Center(
    child: Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: BondyColors.signatureGradient,
        boxShadow: [
          BoxShadow(
            color: BondyColors.primary.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Center(child: Text('🤖', style: TextStyle(fontSize: 36))),
    ),
  );

  Widget _buildQuestion() => Column(
    children: [
      Text(
        'Bạn đang cảm thấy thế nào?',
        textAlign: TextAlign.center,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: BondyColors.textPrimary,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        'Chỉ cần trả lời thật lòng',
        textAlign: TextAlign.center,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: BondyColors.textSecondary,
        ),
      ),
    ],
  );

  Widget _buildEmojiSelector() => Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: List.generate(_emojis.length, (index) {
      final isSelected = _selectedIndex == index;
      return GestureDetector(
        key: Key('emotion_checkin_$index'),
        onTap: (_submitted || _isSending)
            ? null
            : () => setState(() => _selectedIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected ? BondyColors.paleCoral : Colors.white,
            borderRadius: BorderRadius.circular(BondyRadius.sm),
            border: Border.all(
              color: isSelected ? BondyColors.primary : BondyColors.divider,
              width: isSelected ? 2.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: isSelected ? 1.25 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Text(
                  _emojis[index],
                  style: const TextStyle(fontSize: 32),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _emojiLabels[index],
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? BondyColors.primary
                      : BondyColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }),
  );

  Widget _buildTextField() => TextField(
    key: const Key('emotion_checkin_text'),
    controller: _textController,
    enabled: !_submitted && !_isSending,
    maxLines: 3,
    minLines: 2,
    keyboardType: TextInputType.multiline,
    style: GoogleFonts.plusJakartaSans(
      fontSize: 14,
      color: BondyColors.textPrimary,
    ),
    decoration: InputDecoration(
      hintText: 'Muốn chia sẻ thêm không?',
      hintStyle: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        color: BondyColors.textHint,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.all(16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(BondyRadius.sm),
        borderSide: const BorderSide(color: BondyColors.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(BondyRadius.sm),
        borderSide: const BorderSide(color: BondyColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(BondyRadius.sm),
        borderSide: const BorderSide(color: BondyColors.primary, width: 1.5),
      ),
    ),
  );

  Widget _buildSubmitButton() => SizedBox(
    width: double.infinity,
    height: 54,
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: _selectedIndex != null && !_isSending
            ? BondyColors.signatureGradient
            : LinearGradient(
                colors: [Colors.grey.shade300, Colors.grey.shade400],
              ),
        borderRadius: BorderRadius.circular(BondyRadius.sm),
      ),
      child: MaterialButton(
        key: const Key('emotion_checkin_submit'),
        onPressed: _isSending
            ? null
            : (_submitted
                  ? _handleReset
                  : (_selectedIndex != null ? _handleSubmit : null)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BondyRadius.sm),
        ),
        child: _isSending
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                _submitted ? 'Gửi lại ↻' : 'Gửi cảm xúc ▶',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
      ),
    ),
  );

  Widget _buildAiResponseCard() {
    return AnimatedBuilder(
      animation: _responseAnimController,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, _responseSlideAnim.value),
        child: Opacity(opacity: _responseFadeAnim.value, child: child),
      ),
      child: Container(
        key: const Key('emotion_ai_response'),
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(BondyRadius.md),
          border: Border.all(
            color: BondyColors.primary.withValues(alpha: 0.15),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: BondyColors.signatureGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text('🤖', style: TextStyle(fontSize: 18)),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bondy AI',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: BondyColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Phản hồi cảm xúc',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: BondyColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            AiMarkdownText(
              data: _aiResponse,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                height: 1.55,
                color: BondyColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/home/healing'),
              child: Text(
                'Khám phá nội dung healing →',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: BondyColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
