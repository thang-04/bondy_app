import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bondy_button.dart';
import '../../services/analytics_service.dart';

class ThankYouScreen extends StatelessWidget {
  const ThankYouScreen({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      analytics.profileComplete();
    });
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(color: Colors.white),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Celebration Icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: BondyColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text('✨', style: TextStyle(fontSize: 48)),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Tuyệt vời!',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: BondyColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Cảm ơn bạn đã chia sẻ và hoàn thiện hồ sơ. Bây giờ hãy cùng bắt đầu hành trình kết nối và chữa lành cùng Bondy nhé!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    color: BondyColors.textSecondary,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 48),
                BondyButton(
                  text: 'Bắt đầu ngay',
                  onPressed: () {
                    Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil('/home', (route) => false);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
