import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class MilestoneRemindersScreen extends StatelessWidget {
  const MilestoneRemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: BondyColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Dấu mốc kỷ niệm',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: BondyColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: BondyColors.primary),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Đừng bỏ lỡ những khoảnh khắc quan trọng',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: BondyColors.textPrimary,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 32),

            Text(
              'Sắp tới',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: BondyColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _buildMilestoneCard(
              'Kỷ niệm 1 năm',
              'Trong 14 ngày nữa (10/03)',
              '🎂',
              const Color(0xFFFFE5E5),
              const Color(0xFFFF5252),
            ),
            _buildMilestoneCard(
              'Ngày đầu gặp gỡ',
              'Trong 45 ngày nữa (10/04)',
              '✨',
              const Color(0xFFFFF7E5),
              const Color(0xFFFFB300),
            ),

            const SizedBox(height: 32),
            Text(
              'Đã qua',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: BondyColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _buildMilestoneItem('Lần đầu đi xem phim', '24/12/2025', '🎬'),
            _buildMilestoneItem('Buổi hẹn hò đầu tiên', '15/11/2025', '☕'),
            _buildMilestoneItem('Lần đầu cùng đi du lịch', '10/10/2025', '🏕️'),
          ],
        ),
      ),
    );
  }

  Widget _buildMilestoneCard(
    String title,
    String date,
    String emoji,
    Color bgColor,
    Color accentColor,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: BondyColors.textPrimary,
                  ),
                ),
                Text(
                  date,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: accentColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneItem(String title, String date, String emoji) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: BondyColors.textPrimary,
                  ),
                ),
                Text(
                  date,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: BondyColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle_outline, color: Color(0xFF9CA3AF), size: 18),
        ],
      ),
    );
  }
}
