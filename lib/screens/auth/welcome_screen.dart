import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bondy_logo.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BondyColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            // Main logo
            const BondyLogo(size: 300, showText: true, showTagline: true),
            const Spacer(flex: 1),
            // Tagline
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: BondyColors.textPrimary,
                        height: 1.2,
                      ),
                      children: [
                        const TextSpan(text: 'Kết nối cảm xúc &\n'),
                        WidgetSpan(
                          child: ShaderMask(
                            shaderCallback: (bounds) => BondyColors
                                .primaryGradient
                                .createShader(bounds),
                            child: Text(
                              'Chữa lành',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Tìm kiếm sự đồng điệu trong tâm hồn và xây\ndựng những mối quan hệ ý nghĩa.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: BondyColors.textSecondary,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const Spacer(flex: 2),
            // Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  // Primary gradient button with Material ripple effect
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      key: const Key('welcome_otp_button'),
                      onTap: () => Navigator.of(context).pushNamed('/sign-up'),
                      borderRadius: BorderRadius.circular(30),
                      child: Ink(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: BondyColors.primaryGradient,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: BondyColors.primary.withValues(
                                alpha: 0.25,
                              ),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'Tạo tài khoản mới',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      key: const Key('welcome_login_button'),
                      onPressed: () =>
                          Navigator.of(context).pushNamed('/login'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: BondyColors.primary,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        'Đăng nhập',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: BondyColors.primary,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Security badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        size: 14,
                        color: BondyColors.textSecondary.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'BẢO MẬT & AN TOÀN',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: BondyColors.textSecondary.withValues(
                            alpha: 0.6,
                          ),
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
