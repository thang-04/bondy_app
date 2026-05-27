import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../services/safety_guardrails_service.dart';
import '../../widgets/chat/date_suggestions_widget.dart';
import '../../core/ai_prompts_config.dart';

class BondyAIChatScreen extends StatefulWidget {
  const BondyAIChatScreen({super.key});

  @override
  State<BondyAIChatScreen> createState() => _BondyAIChatScreenState();
}

class _BondyAIChatScreenState extends State<BondyAIChatScreen> {
  final _controller = TextEditingController();
  final _safetyService = SafetyGuardrailsService();
  final List<_BotMessage> _messages = [
    _BotMessage(
      'Chào bạn! Mình là Bondy AI 🌸\nMình ở đây để trợ giúp bạn mở lời, gợi ý hẹn hò và chia sẻ các mẹo thấu hiểu người ấy.',
      false,
    ),
    _BotMessage(
      'Hôm nay bạn cần mình gợi ý chủ đề trò chuyện hay tìm địa điểm đi chơi cuối tuần cùng người ấy? Hãy nói cho mình biết nhé.',
      false,
    ),
  ];

  bool _showOverlay = false;
  String? _pendingMessage;
  bool _showSafetyWarning = false;
  bool _didReadArguments = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didReadArguments) return;
    _didReadArguments = true;
    _readRouteArguments();
  }

  void _readRouteArguments() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic> && args.containsKey('initialMessage')) {
        final initMsg = args['initialMessage'] as String;
        args.remove('initialMessage');
        _proceedWithMessage(initMsg);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
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
          icon: const Icon(Icons.arrow_back_ios, color: BondyColors.textPrimary),
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
              child: const Center(
                child: Icon(
                  Icons.smart_toy,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hỏi Bondy',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: BondyColors.textPrimary,
                  ),
                ),
                Text(
                  'Trợ lý AI thấu cảm',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
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
              // Quick assistant topics
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    _buildTopic('🌸 Gợi ý mở lời'),
                    _buildTopic('🗺️ Chỗ chơi cuối tuần'),
                    _buildTopic('💡 Bí quyết giữ lửa'),
                    _buildTopic('💬 Chủ đề thấu hiểu'),
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
                            hintText: 'Hỏi Bondy bất cứ điều gì...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
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
                        onTap: _sendMessage,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            gradient: BondyColors.primaryGradient,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.send,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_showOverlay) _buildAskBondyOverlay(),
          if (_showSafetyWarning) _buildSafetyWarningOverlay(),
        ],
      ),
    );
  }

  void _sendMessage() {
    if (_controller.text.isNotEmpty) {
      final message = _controller.text;
      final safetyCheck = _safetyService.check(message);

      if (safetyCheck.shouldWarn) {
        setState(() {
          _pendingMessage = message;
          _showSafetyWarning = true;
        });
      } else {
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
          final lowercase = message.toLowerCase();
          if (lowercase.contains('mở lời') || lowercase.contains('phá băng')) {
            _messages.add(_BotMessage(
              'Để tạo một mở đầu thấu cảm và tự nhiên, bạn có thể gửi một trong các câu hỏi phá băng nhẹ nhàng này nhé: ✨\n\n'
              '1. "Khoảnh khắc bình yên nhất trong ngày của bạn là gì?"\n'
              '2. "Vibe hôm nay của bạn có màu gì?"\n'
              '3. "Bài hát yêu thích lúc này của bạn là gì?"',
              false,
            ));
          } else if (lowercase.contains('chỗ chơi') || lowercase.contains('địa điểm') || lowercase.contains('hẹn hò')) {
            _messages.add(_BotMessage(
              'Cuối tuần sắp đến rồi, hai bạn hãy thử dành thời gian chất lượng bên nhau nhé! Dưới đây là một vài địa điểm hẹn hò cực kỳ lãng mạn được đề xuất riêng cho hai bạn: 🗺️',
              false,
            ));
            _messages.add(_BotMessage(
              '',
              false,
              messageType: 'DATE_SUGGESTION',
            ));
          } else if (lowercase.contains('giữ lửa') || lowercase.contains('bí quyết')) {
            _messages.add(_BotMessage(
              'Bí quyết giữ lửa đơn giản nhất là dành cho nhau những khoảng thời gian chất lượng (Quality Time). Hãy cùng nhau làm một việc chưa từng thử, hoặc gửi cho đối phương những câu hỏi sâu để thấu hiểu thế giới nội tâm của nhau hơn nhé! 💕',
              false,
            ));
          } else {
            _messages.add(_BotMessage(
              'Mình đã nhận được câu hỏi của bạn. Để giúp bạn kết nối tốt nhất, mình khuyên hai bạn thử trải nghiệm một buổi hẹn hò cuối tuần ấm áp xem sao nhé! Dưới đây là gợi ý địa điểm riêng cho bạn: 🌸',
              false,
            ));
            _messages.add(_BotMessage(
              '',
              false,
              messageType: 'DATE_SUGGESTION',
            ));
          }
        });
      }
    });
  }

  Widget _buildBubble(_BotMessage msg) {
    if (msg.messageType == 'DATE_SUGGESTION') {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                gradient: BondyColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.smart_toy,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DateSuggestionsWidget(
                places: AIPromptsConfig.mockDateSuggestions,
                onShare: (name) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Đã chia sẻ địa điểm: $name')),
                  );
                },
                onSave: (name) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Đã lưu địa điểm: $name')),
                  );
                },
                onMap: (name) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Đang mở bản đồ cho: $name')),
                  );
                },
              ),
            ),
          ],
        ),
      );
    }

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
              decoration: const BoxDecoration(
                gradient: BondyColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.smart_toy,
                  color: Colors.white,
                  size: 16,
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
                    ? BondyColors.primaryGradient
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
          _proceedWithMessage(label);
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
                  decoration: const BoxDecoration(
                    gradient: BondyColors.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.smart_toy,
                      color: Colors.white,
                      size: 32,
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
  final String messageType;

  _BotMessage(this.text, this.isUser, {this.messageType = 'TEXT'});
}
