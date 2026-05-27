import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';

class RelationshipInvitationScreen extends StatelessWidget {
  const RelationshipInvitationScreen({super.key});

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(const ClipboardData(text: 'BONDY-365-LOVE'));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã sao chép mã mời!'),
        backgroundColor: Color(0xFF4CAF50),
      ),
    );
  }

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
          'Mời tri kỷ',
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
          children: [
            const SizedBox(height: 12),
            // Illustration
            Container(
              width: double.infinity,
              height: 220,
              decoration: BoxDecoration(
                color: const Color(0xFFF3E5FF),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Center(
                child: Text('💌', style: TextStyle(fontSize: 80)),
              ),
            ),
            const SizedBox(height: 40),
            Text(
              'Gắn kết hơn khi có nhau',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: BondyColors.textPrimary,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Mời người ấy cùng sử dụng Bondy để chia sẻ cảm xúc, giải quyết mâu thuẫn và lưu giữ kỷ niệm nhé.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                color: BondyColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),

            // Code Display
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                children: [
                  Text(
                    'MÃ MỜI CỦA BẠN',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: BondyColors.textSecondary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'BONDY-365-LOVE',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: BondyColors.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => _copyToClipboard(context),
                        icon: const Icon(Icons.copy, size: 20, color: BondyColors.primary),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: () {
                // Share functionality
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
                'Gửi lời mời ngay',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {},
              child: Text(
                'Tôi đã nhận được mã mời từ người ấy',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: BondyColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
