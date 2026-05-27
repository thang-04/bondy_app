import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../../theme/app_theme.dart';

/// Màn hình Onboarding cho Bondy App.
/// Gồm 5 trang: Start Journey, Emotional Healing, Value Proposition, Trust & Safety, Welcome.
/// Thiết kế pixel-perfect dựa trên Stitch wireframes gốc (Project ID: 11881478113822195591).
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentPage = 0;
  static const int _totalPages = 5;

  // ─── Design System Colors (trích từ Stitch Tailwind Config) ───
  static const Color _primary = Color(0xFFB70047);
  static const Color _primaryContainer = Color(0xFFFF728F);
  static const Color _secondaryContainer = Color(0xFFFFBDF4);
  static const Color _tertiaryFixed = Color(0xFFFF955B);
  static const Color _tertiaryContainer = Color(0xFFFF955B);
  static const Color _background = Color(0xFFFBF5F7);
  static const Color _surfaceContainerLow = Color(0xFFF5EFF1);
  static const Color _surfaceContainerHighest = Color(0xFFE1DBDE);
  static const Color _surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color _onSurface = Color(0xFF302E30);
  static const Color _onSurfaceVariant = Color(0xFF5E5B5C);
  static const Color _onPrimary = Color(0xFFFFEFF0);
  static const Color _onSecondaryContainer = Color(0xFF7A1C78);
  static const Color _onTertiaryFixedVariant = Color(0xFF632700);
  static const Color _outlineVariant = Color(0xFFB0ACAE);

  // ─── Signature Gradient ───
  static const LinearGradient _signatureGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF0066), Color(0xFFFF007F)],
  );

  @override
  void dispose() {
    super.dispose();
  }

  void _onNext() {
    if (_currentPage < _totalPages - 1) {
      setState(() => _currentPage++);
    } else {
      _finishOnboarding();
    }
  }

  void _finishOnboarding() {
    Navigator.pushReplacementNamed(context, '/welcome');
  }

  /// Lấy widget trang hiện tại dựa trên index
  Widget _getCurrentPage() {
    switch (_currentPage) {
      case 0:
        return _buildStartJourneyPage();
      case 1:
        return _buildEmotionalHealingPage();
      case 2:
        return _buildValuePropositionPage();
      case 3:
        return _buildTrustSafetyPage();
      case 4:
        return _buildWelcomePage();
      default:
        return _buildStartJourneyPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: Stack(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            reverseDuration: const Duration(milliseconds: 500),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeOutCubic,
            transitionBuilder: (Widget child, Animation<double> animation) {
              // child.key == ValueKey(_currentPage) xác định đây là trang sắp vào
              final isIncoming = child.key == ValueKey(_currentPage);
              return SlideTransition(
                position: Tween<Offset>(
                  begin: isIncoming ? const Offset(0.1, 0.0) : const Offset(-0.1, 0.0),
                  end: Offset.zero,
                ).animate(animation),
                child: FadeTransition(
                  opacity: animation,
                  child: child,
                ),
              );
            },
            child: KeyedSubtree(
              key: ValueKey<int>(_currentPage),
              child: _getCurrentPage(),
            ),
          ),
          // Nút Skip (góc trên phải)
          if (_currentPage < _totalPages - 1)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 24,
              child: GestureDetector(
                onTap: _finishOnboarding,
                child: Text(
                  'Skip',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _primary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // TRANG 1: START YOUR JOURNEY
  // ═══════════════════════════════════════════════════════════════
  Widget _buildStartJourneyPage() {
    final screenHeight = MediaQuery.of(context).size.height;
    final topPadding = MediaQuery.of(context).padding.top;
    // Hero chiếm khoảng 60% màn hình (tương đương h-[530px] trên 884px)
    final heroHeight = screenHeight * 0.6;

    return Stack(
      children: [
        // ── Hero Image Section (top) ──
        // Ảnh hero với asymmetric clip, không dùng Expanded để tránh bị chia đôi layout
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: heroHeight,
          child: ClipPath(
            clipper: _AsymmetricClipper(),
            child: Container(
              color: _surfaceContainerLow,
              child: Image.network(
                'https://lh3.googleusercontent.com/aida-public/AB6AXuBzKl1iOCB_xu9X5wIbM5OwjiCoLELtCLJoCaUAjziliENeDaK_CxUKOhWI6zK6ojcVc1Xk_cvDPgr2SL8klE18itsEb-4pEklaFT8P_ojnXzxAi9mySuPLihgxxUllq5nwiLRd_SIxxXSMWKLc_wQKD0hQW9MtGLt8gXu-RESO_LhO-x6S5baHD4Tg-PvKhbQA0HJFncJkJY48kBS0Wj5Z3CCtZtOGIXmH6TkZhqFB5J6kBMPUmyMf-ad3KU-zbvhidXWD-Cy8T5AR',
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: _surfaceContainerLow,
                  child: const Center(
                    child: Icon(Icons.image, size: 64, color: _outlineVariant),
                  ),
                ),
              ),
            ),
          ),
        ),
        // ── Gradient Overlay (chỉ phủ lên hero, fade từ dưới lên) ──
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: heroHeight,
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  stops: const [0.0, 0.5],
                  colors: [
                    _background.withValues(alpha: 0.95),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
        // ── Decorative Glow (mờ nhẹ ở giữa hero, chỉ là hint ánh sáng) ──
        Positioned(
          top: heroHeight * 0.25,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              width: 256,
              height: 256,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _primary.withValues(alpha: 0.08),
              ),
            ),
          ),
        ),
        // ── Content Section (chồng lên hero giao diện liền mạch, -mt-20 kiểu CSS) ──
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          top: heroHeight - 80, // overlap lên hero ~80px (tương đương -mt-20 CSS)
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                Text(
                  'Start your journey',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: _onSurface,
                    height: 1.1,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Meet people who truly understand you',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    color: _onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                const Spacer(flex: 3),
                _buildPageIndicator(0),
                const SizedBox(height: 24),
                _buildPrimaryCTA('Get Started'),
                SizedBox(height: MediaQuery.of(context).padding.bottom + 32),
              ],
            ),
          ),
        ),
        // ── Shield Icon (góc trên phải, nổi trên hero) ──
        Positioned(
          top: topPadding + 96,
          right: 24,
          child: _buildGlassCircle(
            icon: Icons.shield_outlined,
            iconColor: const Color(0xFF994100),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // TRANG 2: EMOTIONAL HEALING ONBOARDING
  // ═══════════════════════════════════════════════════════════════
  Widget _buildEmotionalHealingPage() {
    return Stack(
      children: [
        // ── Decorative Blurs (nền, pointer-events-none) ──
        // Secondary blur (bottom-left): bg-secondary/30 blur-[120px]
        Positioned(
          bottom: -96,
          left: -96,
          child: IgnorePointer(
            child: Container(
              width: 256,
              height: 256,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF92348E).withValues(alpha: 0.15),
              ),
            ),
          ),
        ),
        // Primary blur (top-right): bg-primary/20 blur-[80px]
        Positioned(
          top: -48,
          right: -48,
          child: IgnorePointer(
            child: Container(
              width: 192,
              height: 192,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _primary.withValues(alpha: 0.1),
              ),
            ),
          ),
        ),
        // ── Main Content ──
        SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 56), // Skip button space
              // ── Heart Icon Visual (flex-1 centered) ──
              Expanded(
                flex: 3,
                child: Center(
                  child: SizedBox(
                    width: 256,
                    height: 256,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Subtle glow: bg-primary/40 blur-[100px] — rất nhẹ trên màn
                        Container(
                          width: 256,
                          height: 256,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _primary.withValues(alpha: 0.06),
                          ),
                        ),
                        // Heart circle: glass-like surface
                        Container(
                          width: 128,
                          height: 128,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _surfaceContainerLow,
                            border: Border.all(
                              color: _primary.withValues(alpha: 0.1),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF0066).withValues(alpha: 0.1),
                                blurRadius: 60,
                                spreadRadius: 10,
                              ),
                              BoxShadow(
                                color: const Color(0xFFFF0066).withValues(alpha: 0.1),
                                blurRadius: 40,
                                offset: const Offset(0, 20),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.favorite,
                            size: 60,
                            color: _primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // ── Typography (centered text) ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    Text(
                      "You're not alone in this journey",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: _onSurface,
                        height: 1.15,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Bondy understands your emotions and recommends connections that truly fit you.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: _onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // ── Floating Cards (Stacking: Card3 bottom → Card2 middle → Card1 top) ──
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Card 3 (bottom of pile): handshake, smallest
                      // HTML: left-12 right-12, floating-3 = translateY(-5px) rotate(-1deg)
                      Positioned(
                        left: 48,
                        right: 48,
                        top: 0,
                        child: Transform.translate(
                          offset: const Offset(0, -5),
                          child: Transform.rotate(
                            angle: -0.017,
                            child: _buildFloatingCard(
                              icon: Icons.handshake,
                              iconBgColor: _tertiaryContainer,
                              text: 'Ready for meaningful relationships',
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              iconSize: 16,
                            ),
                          ),
                        ),
                      ),
                      // Card 2 (middle): forum, medium
                      // HTML: left-4 right-4 top-10, floating-2 = translateY(15px) rotate(3deg), z-10
                      Positioned(
                        left: 16,
                        right: 16,
                        top: 32,
                        child: Transform.translate(
                          offset: const Offset(0, 15),
                          child: Transform.rotate(
                            angle: 0.052,
                            child: _buildFloatingCard(
                              icon: Icons.forum,
                              iconBgColor: _secondaryContainer,
                              iconColor: _onSecondaryContainer,
                              text: 'People who value deep conversations',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      // Card 1 (top): auto_awesome, largest/highlighted
                      // HTML: left-8 right-8 top-20, floating-1 = translateY(-10px) rotate(-2deg), z-20
                      Positioned(
                        left: 32,
                        right: 32,
                        top: 64,
                        child: Transform.translate(
                          offset: const Offset(0, -10),
                          child: Transform.rotate(
                            angle: -0.035,
                            child: _buildFloatingCard(
                              icon: Icons.auto_awesome,
                              iconBgColor: _primaryContainer,
                              text: 'Matches your emotional energy',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              isHighlighted: true,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // ── Bottom Controls (mt-auto equivalent) ──
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 0),
                child: Column(
                  children: [
                    _buildPageIndicator(1),
                    const SizedBox(height: 24),
                    _buildPrimaryCTA('Continue'),
                    SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // TRANG 3: VALUE PROPOSITION
  // ═══════════════════════════════════════════════════════════════
  Widget _buildValuePropositionPage() {
    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 56),
          // Illustration Section
          Expanded(
            flex: 45,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Stack(
                children: [
                  // Background glow
                  Center(
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _primary.withValues(alpha: 0.05),
                      ),
                    ),
                  ),
                  // Portrait image (asymmetric, rotated)
                  Positioned(
                    top: -16,
                    left: -8,
                    child: Transform.rotate(
                      angle: -0.105, // ~-6 degrees
                      child: Container(
                        width: 192,
                        height: 256,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: _primary.withValues(alpha: 0.12),
                              blurRadius: 64,
                              offset: const Offset(0, 32),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.network(
                          'https://lh3.googleusercontent.com/aida-public/AB6AXuD6F4XjvZV7hbWFY3nsj3CyEmep8DtfaIyv06NPDKzhr2_jMHnfJci91z7e8sFTDl_vS-85lrn7O1jytC8rCOWbSE-6PO8sdXb8zmEqLIrLl97ARVORAMRyBLjPL8EQ84j84S4dhtMl2gWy4w2aOlA3y-0PwtMC3eQuptW24Vleul3sOEwXrkLQVwZA_Cmyz1hDa8JJZLQmSTiGRPWZCYKZs2vjzgq8e7Ythdgsxqe8tHWP8VlnQ0QsIndBo0-xaNvRRw3SeCEPkODU',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: _surfaceContainerLow,
                            child: const Icon(Icons.person, size: 64, color: _outlineVariant),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Compatibility Card (top right, rotated)
                  Positioned(
                    top: 40,
                    right: 16,
                    child: Transform.rotate(
                      angle: 0.07, // ~4 degrees
                      child: _buildGlassInfoCard(
                        label: 'Compatibility',
                        labelIcon: Icons.psychology,
                        progressPercent: 0.88,
                        subtitle: 'Deep emotional sync',
                      ),
                    ),
                  ),
                  // AI Insight Card (bottom right, rotated)
                  Positioned(
                    bottom: 64,
                    right: -8,
                    child: Transform.rotate(
                      angle: -0.035,
                      child: _buildAIInsightCard(),
                    ),
                  ),
                  // Shared Values Chip (bottom left)
                  Positioned(
                    bottom: 32,
                    left: 48,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _secondaryContainer,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Shared Values',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _onSecondaryContainer,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Text Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Match beyond appearance',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: _onSurface,
                    height: 1.1,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 24),
                // Feature rows
                _buildFeatureRow(
                  icon: Icons.favorite,
                  text: 'Personality-based matching',
                ),
                const SizedBox(height: 16),
                _buildFeatureRow(
                  icon: Icons.insights,
                  text: 'Smart relationship insights',
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Bottom controls
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 48),
            child: Column(
              children: [
                _buildPageIndicator(2),
                const SizedBox(height: 32),
                _buildPrimaryCTA('Continue'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // TRANG 4: TRUST & SAFETY
  // ═══════════════════════════════════════════════════════════════
  Widget _buildTrustSafetyPage() {
    return Stack(
      children: [
        // Decorative blurs (fixed)
        Positioned(
          top: -48,
          left: -48,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _primaryContainer.withValues(alpha: 0.1),
            ),
          ),
        ),
        Positioned(
          bottom: -48,
          right: -48,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _secondaryContainer.withValues(alpha: 0.1),
            ),
          ),
        ),
        // Soft bg gradient
        Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, 0),
              radius: 1.2,
              colors: [Color(0xFFFFF0E9), _background],
            ),
          ),
        ),
        SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 56),
              // Hero illustration
              Expanded(
                flex: 45,
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Decorative glow
                      Container(
                        width: 280,
                        height: 280,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _secondaryContainer.withValues(alpha: 0.2),
                        ),
                      ),
                      // Shield icon container
                      Container(
                        width: 192,
                        height: 192,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _surfaceContainerLowest,
                          boxShadow: [
                            BoxShadow(
                              color: _primary.withValues(alpha: 0.06),
                              blurRadius: 64,
                              offset: const Offset(0, 32),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.verified_user,
                          size: 96,
                          color: _primary,
                        ),
                      ),
                      // Lock floating element (bottom right)
                      Positioned(
                        bottom: 40,
                        right: 40,
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: _tertiaryFixed,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.lock,
                            size: 30,
                            color: _onTertiaryFixedVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Safe & private',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 44,
                        fontWeight: FontWeight.w800,
                        color: _onSurface,
                        height: 1.1,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Feature rows
                    _buildTrustFeatureRow(
                      icon: Icons.check_circle,
                      iconBgColor: _secondaryContainer,
                      iconColor: _onSecondaryContainer,
                      text: 'Verified profiles',
                    ),
                    const SizedBox(height: 16),
                    _buildTrustFeatureRow(
                      icon: Icons.security,
                      iconBgColor: _primaryContainer.withValues(alpha: 0.3),
                      iconColor: _primary,
                      text: 'Secure conversations',
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Bottom Controls
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 48),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Column(
                      children: [
                        _buildPageIndicator(3),
                        const SizedBox(height: 32),
                        _buildPrimaryCTA('Continue'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // TRANG 5: WELCOME SCREEN
  // ═══════════════════════════════════════════════════════════════
  Widget _buildWelcomePage() {
    return Stack(
      children: [
        // Background decorative blurs
        Positioned(
          top: -80,
          left: -80,
          child: Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF92348E).withValues(alpha: 0.05),
            ),
          ),
        ),
        Positioned(
          bottom: -80,
          right: -80,
          child: Container(
            width: 384,
            height: 384,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _primary.withValues(alpha: 0.05),
            ),
          ),
        ),
        SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 56),
              // Abstract Heart/Connection Illustration
              Expanded(
                flex: 50,
                child: Center(
                  child: SizedBox(
                    width: 320,
                    height: 320,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Background glows
                        Container(
                          width: double.infinity,
                          height: double.infinity,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _primary.withValues(alpha: 0.1),
                          ),
                        ),
                        Positioned(
                          left: 40,
                          top: 40,
                          child: Container(
                            width: 240,
                            height: 240,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF92348E).withValues(alpha: 0.1),
                            ),
                          ),
                        ),
                        // Concentric circles
                        Container(
                          width: 256,
                          height: 256,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _primary.withValues(alpha: 0.1),
                            ),
                          ),
                        ),
                        Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF92348E).withValues(alpha: 0.2),
                            ),
                          ),
                        ),
                        // Center Heart
                        Container(
                          width: 128,
                          height: 128,
                          decoration: BoxDecoration(
                            gradient: _signatureGradient,
                            borderRadius: BorderRadius.circular(40),
                            boxShadow: [
                              BoxShadow(
                                color: _primary.withValues(alpha: 0.2),
                                blurRadius: 64,
                                offset: const Offset(0, 32),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.favorite,
                            size: 60,
                            color: _onPrimary,
                          ),
                        ),
                        // Floating node (top right)
                        Positioned(
                          top: 0,
                          right: 40,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _secondaryContainer,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 16,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.auto_awesome,
                              color: _onSecondaryContainer,
                            ),
                          ),
                        ),
                        // Floating node (bottom left)
                        Positioned(
                          bottom: 48,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _tertiaryFixed,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 16,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.bolt,
                              color: Color(0xFF2E0E00),
                            ),
                          ),
                        ),
                        // Small node (top left)
                        Positioned(
                          top: 80,
                          left: -16,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _surfaceContainerHighest,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.fiber_manual_record,
                              size: 14,
                              color: _primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Text Content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    Text(
                      'Find real\nconnections',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 44,
                        fontWeight: FontWeight.w800,
                        color: _onSurface,
                        height: 1.1,
                        letterSpacing: -1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          color: _onSurfaceVariant,
                          height: 1.5,
                        ),
                        children: [
                          const TextSpan(text: 'Not just swipes, but '),
                          TextSpan(
                            text: 'meaningful',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              color: _primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const TextSpan(text: ' matches'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Bottom Controls
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 40),
                child: Column(
                  children: [
                    _buildPageIndicator(4),
                    const SizedBox(height: 32),
                    _buildPrimaryCTA('Continue'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // SHARED COMPONENTS
  // ═══════════════════════════════════════════════════════════════

  /// Nút CTA chính (gradient signature)
  Widget _buildPrimaryCTA(String label) {
    return GestureDetector(
      onTap: _onNext,
      child: Container(
        width: double.infinity,
        height: 64,
        decoration: BoxDecoration(
          gradient: BondyColors.primaryGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: BondyColors.primary.withValues(alpha: 0.25),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _onPrimary,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }

  /// Pagination indicators (Expanding Dots effect)
  Widget _buildPageIndicator(int activePage) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_totalPages, (i) {
        final isActive = i == activePage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 28 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: isActive ? _signatureGradient : null,
            color: isActive ? null : _surfaceContainerHighest,
          ),
        );
      }),
    );
  }

  /// Glass Circle (cho icon shield trên S01)
  Widget _buildGlassCircle({
    required IconData icon,
    required Color iconColor,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _background.withValues(alpha: 0.7),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 16,
              ),
            ],
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
      ),
    );
  }

  /// Floating card component (S02)
  Widget _buildFloatingCard({
    required IconData icon,
    required Color iconBgColor,
    Color? iconColor,
    required String text,
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w500,
    double iconSize = 18,
    bool isHighlighted = false,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isHighlighted
                  ? Colors.white.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.05),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 24,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: iconSize,
                  color: iconColor ?? Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: GoogleFonts.inter(
                    fontSize: fontSize,
                    fontWeight: fontWeight,
                    color: _onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Glass info card cho Compatibility (S03)
  Widget _buildGlassInfoCard({
    required String label,
    required IconData labelIcon,
    required double progressPercent,
    required String subtitle,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: 160,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _primary.withValues(alpha: 0.06),
                blurRadius: 64,
                offset: const Offset(0, 32),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(labelIcon, size: 14, color: _primary),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      color: _primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  height: 8,
                  width: double.infinity,
                  color: _surfaceContainerLow,
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progressPercent,
                    child: Container(
                      decoration: const BoxDecoration(gradient: _signatureGradient),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: _onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// AI Insight card cho S03
  Widget _buildAIInsightCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: 180,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _primary.withValues(alpha: 0.06),
                blurRadius: 64,
                offset: const Offset(0, 32),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      gradient: _signatureGradient,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'AI Insight',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '"You both prioritize creative growth and quiet mornings."',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: _onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Feature row (S03 style)
  Widget _buildFeatureRow({
    required IconData icon,
    required String text,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _surfaceContainerLow,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: _primary, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: _onSurface,
            ),
          ),
        ),
      ],
    );
  }

  /// Trust feature row (S04 style)
  Widget _buildTrustFeatureRow({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 16),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: _onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// CUSTOM CLIPPER cho Hero Section (asymmetric)
// ═══════════════════════════════════════════════════════════════
class _AsymmetricClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height * 0.85);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
