import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';

class LikeQuotaExceededDialog extends StatelessWidget {
  const LikeQuotaExceededDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        decoration: BoxDecoration(
          color: BondyColors.background, // Nền kem ấm Bondy
          borderRadius: BorderRadius.circular(BondyRadius.xl),
          boxShadow: [
            BoxShadow(
              color: BondyColors.textPrimary.withValues(alpha: 0.12),
              blurRadius: 40,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Biểu tượng trái tim khóa phát sáng
            _buildIllustration(),
            const SizedBox(height: 24),
            // Tiêu đề
            Text(
              'Hết lượt thích hôm nay',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: BondyColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            // Nội dung gợi ý reset lúc 00:00
            Text(
              'Số lượt thích của bạn đã chạm giới hạn hôm nay. Lượt thích mới sẽ được làm mới tự động vào lúc 00:00 nửa đêm.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: BondyColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            // Nút CTA Premium
            _buildPremiumButton(context),
            const SizedBox(height: 12),
            // Nút đóng
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Để sau',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: BondyColors.textHint,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIllustration() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: BondyColors.paleCoral,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: BondyColors.primary.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.favorite_rounded,
            color: BondyColors.primary,
            size: 40,
          ),
          Positioned(
            right: 18,
            bottom: 18,
            child: CircleAvatar(
              radius: 10,
              backgroundColor: Colors.white,
              child: Icon(
                Icons.lock_rounded,
                color: BondyColors.primaryDark,
                size: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: BondyColors.primaryGradient,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: BondyColors.primary.withValues(alpha: 0.3),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            Navigator.of(context).pushNamed('/settings/premium');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(26),
            ),
          ),
          child: Text(
            'Nâng cấp Premium',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
