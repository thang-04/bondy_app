import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../services/safety_guardrails_service.dart';

class HealingChatbotCoachScreen extends StatefulWidget {
  const HealingChatbotCoachScreen({super.key});

  @override
  State<HealingChatbotCoachScreen> createState() =>
      _HealingChatbotCoachScreenState();
}

class _HealingChatbotCoachScreenState extends State<HealingChatbotCoachScreen> {
  final _controller = TextEditingController();
  final _safetyService = SafetyGuardrailsService();
  final List<_BotMessage> _messages = [
    _BotMessage(
      'Chào bạn! Mình là Bondy 🌿\nMình ở đây để lắng nghe và đồng hành cùng bạn trên hành trình chữa lành.',
      false,
    ),
    _BotMessage(
      'Hôm nay bạn cảm thấy thế nào? Hãy chia sẻ với mình nhé.',
      false,
    ),
  ];

  bool _showOverlay = false;
  String? _pendingMessage;
  bool _showSafetyWarning = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF97316), Color(0xFFEA2A5A)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  'B',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bondy Coach',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: BondyColors.textPrimary,
                  ),
                ),
                Text(
                  'AI Chữa lành',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: BondyColors.primary,
                  ),
                ),
              ],
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
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    return _buildBubble(msg);
                  },
                ),
              ),
              // Quick topics
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    _buildTopic('💔 Chia tay'),
                    _buildTopic('😰 Lo lắng'),
                    _buildTopic('😔 Cô đơn'),
                    _buildTopic('🌱 Phát triển'),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Input
              Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(
                      color: BondyColors.divider.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          decoration: InputDecoration(
                            hintText: 'Chia sẻ với Bondy...',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            hintStyle: GoogleFonts.plusJakartaSans(
                              color: BondyColors.textHint,
                            ),
                            filled: true,
                            fillColor: BondyColors.background,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _sendMessage,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: BondyColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.send,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Ask Bondy overlay
          if (_showOverlay) _buildAskBondyOverlay(),
          // Safety warning overlay
          if (_showSafetyWarning) _buildSafetyWarningOverlay(),
        ],
      ),
    );
  }

  void _sendMessage() {
    if (_controller.text.isNotEmpty) {
      final message = _controller.text;

      // Check for safety risk
      final safetyCheck = _safetyService.check(message);

      if (safetyCheck.shouldWarn) {
        // Show warning but allow override
        setState(() {
          _pendingMessage = message;
          _showSafetyWarning = true;
        });
      } else {
        // Proceed normally
        _proceedWithMessage(message);
      }
    }
  }

  void _proceedWithMessage(String message) {
    setState(() {
      _messages.add(_BotMessage(message, true));
      _controller.clear();
    });

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _messages.add(_BotMessage(
            'Cảm ơn bạn đã chia sẻ với mình. Mình ở đây lắng nghe bạn.',
            false,
          ));
        });
      }
    });
  }

  Widget _buildBubble(_BotMessage msg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!msg.isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF97316), Color(0xFFEA2A5A)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  'B',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: msg.isUser
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFF97316), Color(0xFFEA2A5A)],
                      )
                    : null,
                color: msg.isUser ? null : const Color(0xFFFFF1EE),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(msg.isUser ? 16 : 4),
                  bottomRight: Radius.circular(msg.isUser ? 4 : 16),
                ),
              ),
              child: Text(
                msg.text,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color:
                      msg.isUser ? Colors.white : BondyColors.textPrimary,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopic(String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _messages.add(_BotMessage(label, true));
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: BondyColors.divider),
          ),
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(fontSize: 13),
          ),
        ),
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
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: BondyColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite,
                    color: BondyColors.primary,
                    size: 32,
                  ),
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
                  'Mình không phải chuyên gia tâm lý, nhưng mình ở đây để lắng nghe bạn. Nếu bạn cần hỗ trợ chuyên môn, hãy cân nhắc tìm kiếm người giúp đỡ phù hợp.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: BondyColors.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _showSafetyWarning = false),
                        child: const Text('Quay lại'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() => _showSafetyWarning = false);
                          if (_pendingMessage != null) {
                            _proceedWithMessage(_pendingMessage!);
                            _pendingMessage = null;
                          }
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

  Widget _buildAskBondyOverlay() {
    return GestureDetector(
      onTap: () => setState(() => _showOverlay = false),
      child: Container(
        color: BondyColors.overlay,
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(32),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: BondyColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      'B',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Hỏi Bondy bất cứ điều gì',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Bondy luôn sẵn sàng lắng nghe\nvà đồng hành cùng bạn.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: BondyColors.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => setState(() => _showOverlay = false),
                  child: const Text('Bắt đầu trò chuyện'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BotMessage {
  final String text;
  final bool isUser;

  _BotMessage(this.text, this.isUser);
}