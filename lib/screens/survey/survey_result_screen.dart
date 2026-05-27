import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bondy_button.dart';

class SurveyResultScreen extends StatelessWidget {
  const SurveyResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: BondyColors.background,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 40),
                // Completion icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: BondyColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: BondyColors.primary.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.favorite,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'Cảm ơn bạn đã chia sẻ!',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: BondyColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Bondy đã hiểu thêm về bạn.\nĐây là lộ trình chữa lành dành riêng cho bạn.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: BondyColors.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 36),
                // Healing path card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text('🌿', style: TextStyle(fontSize: 40)),
                      const SizedBox(height: 12),
                      Text(
                        'Lộ trình: Chữa lành & Kết nối',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: BondyColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildPathItem(
                        Icons.self_improvement,
                        'Tuần 1-2',
                        'Chữa lành nội tâm',
                      ),
                      _buildPathItem(
                        Icons.people_outline,
                        'Tuần 3-4',
                        'Kết nối nhẹ nhàng',
                      ),
                      _buildPathItem(
                        Icons.favorite_outline,
                        'Tuần 5+',
                        'Sẵn sàng mở lòng',
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                BondyButton(
                  text: 'Bắt đầu hành trình',
                  onPressed: () {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/home',
                      (route) => false,
                    );
                  },
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _buildPathItem(IconData icon, String week, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: BondyColors.primaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: BondyColors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                week,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: BondyColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: BondyColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
