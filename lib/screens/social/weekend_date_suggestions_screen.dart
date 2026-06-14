import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class WeekendDateSuggestionsScreen extends StatelessWidget {
  const WeekendDateSuggestionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Gợi ý hẹn hò'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🌤️', style: TextStyle(fontSize: 36)),
                  const SizedBox(height: 8),
                  Text(
                    'Cuối tuần này',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: BondyColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Gợi ý hoạt động nhẹ nhàng cho bạn và\nngười kết nối',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: BondyColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Hoạt động gợi ý',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _buildSuggestionCard(
              '☕',
              'Cà phê & Trò chuyện',
              'Một buổi cà phê nhẹ nhàng để tìm hiểu nhau',
              'Thứ 7 • 10:00',
              BondyColors.primaryLight,
            ),
            _buildSuggestionCard(
              '🚶',
              'Đi dạo công viên',
              'Tản bộ và chia sẻ câu chuyện cuộc sống',
              'Thứ 7 • 16:00',
              const Color(0xFFF3E8FF),
            ),
            _buildSuggestionCard(
              '🎨',
              'Workshop vẽ tranh',
              'Cùng nhau sáng tạo và kết nối',
              'Chủ nhật • 14:00',
              const Color(0xFFE0F2FE),
            ),
            _buildSuggestionCard(
              '🧘',
              'Yoga buổi sáng',
              'Thiền định và thư giãn cùng nhau',
              'Chủ nhật • 8:00',
              const Color(0xFFFEF3C7),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionCard(
    String emoji,
    String title,
    String description,
    String time,
    Color bgColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: BondyColors.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 26)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: BondyColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.schedule,
                      size: 14,
                      color: BondyColors.textHint,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      time,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: BondyColors.textHint,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
