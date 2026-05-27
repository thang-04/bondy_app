import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class PremiumPaywallScreen extends StatelessWidget {
  const PremiumPaywallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background Gradient / Illustration
          Container(
            height: 380,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFB3A7), Colors.white],
              ),
            ),
            child: const Center(
              child: Text('💎', style: TextStyle(fontSize: 100)),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: BondyColors.textPrimary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 200),
                        Text(
                          'Mở khóa Bondy Premium',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: BondyColors.textPrimary,
                            height: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Thấu hiểu tri kỷ, gắn kết bền lâu với trọn bộ tính năng nâng cao.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            color: BondyColors.textSecondary,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 40),

                        // Features List
                        _buildFeatureRow('Trò chuyện không giới hạn với Bondy Coach', Icons.check_circle),
                        _buildFeatureRow('Kho bài giảng chữa lành chuyên sâu', Icons.check_circle),
                        _buildFeatureRow('Báo cáo phân tích cảm xúc cặp đôi', Icons.check_circle),
                        _buildFeatureRow('Gợi ý hẹn hò dành riêng cho hai bạn', Icons.check_circle),

                        const SizedBox(height: 48),

                        // Subscription Options
                        _buildPlanOption('Hàng năm', '999.000đ / năm', 'Tiết kiệm 50%', true),
                        const SizedBox(height: 12),
                        _buildPlanOption('Hàng tháng', '159.000đ / tháng', null, false),

                        const SizedBox(height: 32),
                        ElevatedButton(
                          onPressed: () {},
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
                            'Bắt đầu dùng thử 7 ngày',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Dùng thử miễn phí, hủy bất cứ lúc nào.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: BondyColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: BondyColors.primary, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: BondyColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanOption(String title, String price, String? tag, bool isSelected) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFFFE5F2) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? BondyColors.primary : const Color(0xFFE5E7EB),
          width: 2,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
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
                price,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: BondyColors.textSecondary,
                ),
              ),
            ],
          ),
          if (tag != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: BondyColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                tag,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
