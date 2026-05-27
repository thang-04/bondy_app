import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class ConflictResolutionTool extends StatelessWidget {
  const ConflictResolutionTool({super.key});

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
          'Giải quyết mâu thuẫn',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: BondyColors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cùng nhau vượt qua khó khăn',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: BondyColors.textPrimary,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Mâu thuẫn là cơ hội để thấu hiểu nhau sâu sắc hơn. Cùng thực hiện các bước sau nhé.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                color: BondyColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),

            _buildStepItem(
              '1',
              'Dành 15 phút hạ hỏa',
              'Trước khi bắt đầu, cả hai hãy dành thời gian để tâm trí bình tĩnh lại.',
              Icons.timer_outlined,
              const Color(0xFFE5F6FF),
              const Color(0xFF2196F3),
            ),
            _buildStepItem(
              '2',
              'Chia sẻ cảm xúc của bạn',
              'Dùng cấu trúc "Anh/Em thấy... khi..." thay vì chỉ trích đối phương.',
              Icons.record_voice_over_outlined,
              const Color(0xFFFFE5F2),
              const Color(0xFFE91E63),
            ),
            _buildStepItem(
              '3',
              'Lắng nghe không ngắt lời',
              'Hãy để đối phương nói hết suy nghĩ của mình trước khi phản hồi.',
              Icons.hearing_outlined,
              const Color(0xFFF3E5FF),
              const Color(0xFF9C27B0),
            ),
            _buildStepItem(
              '4',
              'Tìm kiếm giải pháp chung',
              'Cùng nhau đưa ra các phương án mà cả hai đều thấy thoải mái.',
              Icons.lightbulb_outline,
              const Color(0xFFFFF7E5),
              const Color(0xFFFFB300),
            ),

            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                // Potential flow for active session
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: BondyColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                'Bắt đầu phiên kết nối',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepItem(
    String number,
    String title,
    String description,
    IconData icon,
    Color iconBg,
    Color iconColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
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
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: BondyColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
