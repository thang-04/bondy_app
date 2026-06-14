import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class ActiveChatDeeperPromptsScreen extends StatefulWidget {
  const ActiveChatDeeperPromptsScreen({super.key});

  @override
  State<ActiveChatDeeperPromptsScreen> createState() =>
      _ActiveChatDeeperPromptsScreenState();
}

class _ActiveChatDeeperPromptsScreenState
    extends State<ActiveChatDeeperPromptsScreen> {
  final _controller = TextEditingController();
  final List<_DeeperMessage> _messages = [
    _DeeperMessage(
      'Mình muốn hiểu bạn hơn. Bạn sẵn sàng cho một vài câu hỏi sâu hơn không? 💚',
      false,
    ),
    _DeeperMessage('Sẵn sàng!', true),
  ];

  final List<String> _deeperPrompts = [
    '🌙 Khoảnh khắc nào khiến bạn thay đổi cách nhìn về tình yêu?',
    '💭 Bạn học được gì từ mối quan hệ trước?',
    '🌱 Điều gì giúp bạn vượt qua giai đoạn khó khăn?',
    '✨ Mô tả mối quan hệ lý tưởng của bạn',
  ];

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
            const CircleAvatar(
              radius: 16,
              backgroundColor: BondyColors.primaryLight,
              child: Text('🌸', style: TextStyle(fontSize: 14)),
            ),
            const SizedBox(width: 10),
            Text(
              'Câu hỏi sâu hơn',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: BondyColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Info banner
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: BondyColors.primaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.auto_awesome,
                  color: BondyColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Câu hỏi sâu giúp bạn và Minh Anh hiểu nhau hơn',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: BondyColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Messages
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildBubble(msg);
              },
            ),
          ),
          // Deeper prompts
          Container(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    'Chọn câu hỏi:',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: BondyColors.textHint,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                ..._deeperPrompts.map((prompt) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _messages.add(_DeeperMessage(prompt, true));
                        });
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: BondyColors.divider),
                        ),
                        child: Text(
                          prompt,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            color: BondyColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(_DeeperMessage msg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: msg.isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: msg.isMe
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFF97316), Color(0xFFEA2A5A)],
                      )
                    : null,
                color: msg.isMe ? null : const Color(0xFFFFF1EE),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(msg.isMe ? 16 : 4),
                  bottomRight: Radius.circular(msg.isMe ? 4 : 16),
                ),
              ),
              child: Text(
                msg.text,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: msg.isMe ? Colors.white : BondyColors.textPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeeperMessage {
  final String text;
  final bool isMe;

  _DeeperMessage(this.text, this.isMe);
}
