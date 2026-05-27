import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final List<_ChatMessage> _messages = [
    _ChatMessage('Chào bạn! Mình thấy chúng ta có nhiều điểm chung 😊', false, '14:28'),
    _ChatMessage('Chào bạn! Vui được kết nối với bạn 💚', true, '14:30'),
    _ChatMessage('Bạn cũng thích thiền định à? Mình mới bắt đầu thôi', false, '14:31'),
    _ChatMessage('Mình thiền được 3 tháng rồi. Rất giúp ích cho việc chữa lành đó!', true, '14:33'),
  ];

  final List<String> _suggestions = [
    '💭 Điều gì khiến bạn bắt đầu thiền?',
    '🎵 Bạn nghe nhạc gì khi thiền?',
    '😊 Kể thêm về hành trình chữa lành của bạn',
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Minh Anh',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: BondyColors.textPrimary,
                  ),
                ),
                Text(
                  'Đang hoạt động',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: BondyColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).pushNamed('/chat/deeper'),
            icon: const Icon(Icons.auto_awesome),
            tooltip: 'Câu hỏi sâu hơn',
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pushNamed('/date-suggestions'),
            icon: const Icon(Icons.event),
            tooltip: 'Gợi ý hẹn hò',
          ),
          IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert)),
        ],
      ),
      body: Column(
        children: [
          // Messages
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
          // Suggestions
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: _suggestions.map((s) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _messages.add(_ChatMessage(s, true, '14:35'));
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: BondyColors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: BondyColors.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        s,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: BondyColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
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
                        hintText: 'Nhập tin nhắn...',
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
                      style: GoogleFonts.plusJakartaSans(fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      if (_controller.text.isNotEmpty) {
                        setState(() {
                          _messages.add(_ChatMessage(
                            _controller.text,
                            true,
                            '14:36',
                          ));
                          _controller.clear();
                        });
                      }
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFF97316), Color(0xFFEA2A5A)],
                        ),
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
    );
  }

  Widget _buildBubble(_ChatMessage msg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            msg.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!msg.isMe) ...[
            const CircleAvatar(
              radius: 14,
              backgroundColor: BondyColors.primaryLight,
              child: Text('🌸', style: TextStyle(fontSize: 12)),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    msg.text,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color:
                          msg.isMe ? Colors.white : BondyColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    msg.time,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      color: msg.isMe
                          ? Colors.white.withValues(alpha: 0.7)
                          : BondyColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isMe;
  final String time;

  _ChatMessage(this.text, this.isMe, this.time);
}
