import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class MatchesListScreen extends StatelessWidget {
  const MatchesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Tin nhắn'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bondy chatbot entry
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: BondyColors.primaryGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    'B',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              title: Text(
                'Hỏi Bondy',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              subtitle: Text(
                'Trò chuyện với AI chữa lành',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
                size: 16,
              ),
              onTap: () => Navigator.of(context).pushNamed('/chatbot'),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Kết nối mới',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: BondyColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // New matches horizontal list
          SizedBox(
            height: 90,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: List.generate(5, (index) {
                final names = ['Minh Anh', 'Long', 'Thu Hà', 'Đức', 'Ngọc'];
                final emojis = ['🌸', '🌿', '🌻', '🌳', '🌺'];
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: BondyColors.primaryLight,
                            child: Text(emojis[index],
                                style: const TextStyle(fontSize: 24)),
                          ),
                          if (index < 2)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: BondyColors.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        names[index],
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              'Tin nhắn',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: BondyColors.textSecondary,
              ),
            ),
          ),
          // Chat list
          Expanded(
            child: ListView.builder(
              itemCount: 4,
              itemBuilder: (context, index) {
                final chats = [
                  {'name': 'Minh Anh', 'emoji': '🌸', 'msg': 'Hôm nay bạn có khỏe không?', 'time': '14:30', 'unread': '2'},
                  {'name': 'Hoàng Long', 'emoji': '🌿', 'msg': 'Mình thấy bài thiền hôm qua hay lắm', 'time': '12:15', 'unread': '0'},
                  {'name': 'Thu Hà', 'emoji': '🌻', 'msg': 'Cảm ơn bạn đã chia sẻ 💚', 'time': 'Hôm qua', 'unread': '0'},
                  {'name': 'Đức Minh', 'emoji': '🌳', 'msg': 'Cuối tuần mình đi cà phê không?', 'time': 'Hôm qua', 'unread': '1'},
                ];
                final c = chats[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 4,
                  ),
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: BondyColors.primaryLight,
                    child: Text(c['emoji']!,
                        style: const TextStyle(fontSize: 22)),
                  ),
                  title: Text(
                    c['name']!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: c['unread'] != '0'
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    c['msg']!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: c['unread'] != '0'
                          ? BondyColors.textPrimary
                          : BondyColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        c['time']!,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: BondyColors.textHint,
                        ),
                      ),
                      if (c['unread'] != '0') ...[
                        const SizedBox(height: 4),
                        Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: BondyColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              c['unread']!,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  onTap: () => Navigator.of(context).pushNamed('/chat'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
