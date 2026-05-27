import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class RelationshipConfirmedScreen extends StatelessWidget {
  const RelationshipConfirmedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Celebration Animation Placeholder
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE5F2),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: BondyColors.primary.withValues(alpha: 0.2),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('🎉', style: TextStyle(fontSize: 80)),
                ),
              ),
              const SizedBox(height: 48),
              Text(
                'Thành công rực rỡ!',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: BondyColors.textPrimary,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Cảm xúc của bạn đã được gửi tới Hoan. Việc chia sẻ giúp hai bạn gắn kết hơn mỗi ngày.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  color: BondyColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false),
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
                  'Về trang chủ',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Xem chi tiết',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: BondyColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
