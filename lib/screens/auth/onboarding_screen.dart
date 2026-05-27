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

  // ─── Design System Colors ──────────────────────────────────────────
  // Aligned with the Bondy/Healing palette (coral → pink → purple) so the
  // onboarding flow no longer ships its own deep-magenta + lavender palette
  // that clashed with the rest of the app.
  static const Color _primary = BondyColors.coral;
  static const Color _primaryContainer = BondyColors.coralLight;
  static const Color _secondaryContainer = BondyColors.paleCoral;
  static const Color _tertiaryFixed = BondyColors.orange;
  static const Color _tertiaryContainer = BondyColors.orange;
  static const Color _background = BondyColors.background;
  static const Color _surfaceContainerLow = BondyColors.backgroundCream;
  static const Color _surfaceContainerHighest = BondyColors.divider;
  static const Color _surfaceContainerLowest = BondyColors.surface;
  static const Color _onSurface = BondyColors.textPrimary;
  static const Color _onSurfaceVariant = BondyColors.textSecondary;
  static const Color _onPrimary = Colors.white;
  static const Color _onSecondaryContainer = BondyColors.pink;
  static const Color _onTertiaryFixedVariant = Color(0xFF632700);
  static const Color _outlineVariant = BondyColors.textHint;

  // ─── Signature Gradient (Bondy brand) ───
  static const LinearGradient _signatureGradient = BondyColors.signatureGradient;

  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _finishOnboarding() {
    Navigator.pushReplacementNamed(context, '/welcome');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (page) {
              setState(() => _currentPage = page);
            },
            physics: const BouncingScrollPhysics(),
            itemCount: _totalPages,
            itemBuilder: (context, index) {
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double value = 1.0;
                  if (_pageController.position.hasContentDimensions) {
                    value = (_pageController.page ?? 0) - index;
                  } else {
                    value = (_currentPage) - index.toDouble();
                  }

                  // Hiệu ứng mờ dần (opacity)
                  final double opacity = (1.0 - value.abs()).clamp(0.0, 1.0);
                  
                  // Hiệu ứng trượt chậm (parallax offset): giảm tốc độ dịch chuyển 
                  // của trang xuống còn 45% chiều rộng màn hình để hòa quyện với hiệu ứng fade.
                  final double screenWidth = MediaQuery.of(context).size.width;
                  final double translation = value * screenWidth * 0.45;

                  return Opacity(
                    opacity: opacity,
                    child: Transform.translate(
                      offset: Offset(translation, 0),
                      child: child,
                    ),
                  );
                },
                child: _buildPageByIndex(index),
              );
            },
          ),
          // Nút Skip (góc trên phải)
          if (_currentPage < _totalPages - 1)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 24,
              child: GestureDetector(
                onTap: _finishOnboarding,
                child: Text(
                  'Bỏ qua',
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
              // Use a bundled asset so the onboarding hero doesn't break the
              // first time Google rotates the CDN URL. Falls back to the
              // surface tint if the asset is somehow missing.
              child: Image.asset(
                'assets/images/healing_stitch/stitch_journey_hero.jpg',
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
                  'Khởi Đầu Hành Trình',
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
                  'Khám phá các tính năng tuyệt vời của Bondy để quản lý sức khỏe tinh thần của bạn.',
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
                _buildPrimaryCTA('Bắt đầu ngay'),
                SizedBox(height: MediaQuery.of(context).padding.bottom + 32),
              ],
            ),
          ),
        ),
        // ── Shield Icon (góc trên phải, nổi trên hero) ──
        Positioned(
          top: topPadding + 96,
          right: 24,
          child: _HealingPulse(
            child: _buildGlassCircle(
              icon: Icons.shield_outlined,
              iconColor: const Color(0xFF994100),
            ),
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
                      'Theo Dõi Cảm Xúc',
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
                      'Ghi lại cảm xúc hàng ngày và nhận gợi ý cải thiện sức khỏe.',
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
                              text: 'Sẵn sàng cho mối quan hệ ý nghĩa',
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
                              text: 'Trân trọng trò chuyện sâu sắc',
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
                              text: 'Đồng điệu với năng lượng cảm xúc',
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
                    _buildPrimaryCTA('Tiếp tục'),
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
                        child: Image.asset(
                          'assets/images/healing_stitch/stitch_healing_14.jpg',
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
                        label: 'Độ tương thích',
                        labelIcon: Icons.psychology,
                        progressPercent: 0.88,
                        subtitle: 'Đồng điệu cảm xúc sâu sắc',
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
                        'Giá trị chung',
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
                  'Kết Nối Cộng Đồng',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: _onSurface,
                    height: 1.1,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Tham gia cộng đồng, chia sẻ và nhận hỗ trợ từ những người cùng quan tâm.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: _onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                // Feature rows
                _buildFeatureRow(
                  icon: Icons.favorite,
                  text: 'Ghép đôi dựa trên tính cách',
                ),
                const SizedBox(height: 16),
                _buildFeatureRow(
                  icon: Icons.insights,
                  text: 'Thấu hiểu mối quan hệ thông minh',
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
                _buildPrimaryCTA('Tiếp tục'),
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
                      'An toàn & Riêng tư',
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
                      text: 'Hồ sơ đã xác minh',
                    ),
                    const SizedBox(height: 16),
                    _buildTrustFeatureRow(
                      icon: Icons.security,
                      iconBgColor: _primaryContainer.withValues(alpha: 0.3),
                      iconColor: _primary,
                      text: 'Trò chuyện bảo mật',
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
                        _buildPrimaryCTA('Tiếp tục'),
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
                      'Kết nối\nchân thực',
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
                          const TextSpan(text: 'Không chỉ là vuốt, mà là sự '),
                          TextSpan(
                            text: 'đồng điệu',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              color: _primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const TextSpan(text: ' ý nghĩa'),
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
                    _buildPrimaryCTA('Tiếp tục'),
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
                    'Thấu hiểu AI',
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
                '"Cả hai bạn đều trân trọng sự phát triển sáng tạo và những buổi sáng bình yên."',
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

  Widget _buildPageByIndex(int index) {
    switch (index) {
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
        return const SizedBox.shrink();
    }
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

class _HealingPulse extends StatefulWidget {
  final Widget child;

  const _HealingPulse({required this.child});

  @override
  State<_HealingPulse> createState() => _HealingPulseState();
}

class _HealingPulseState extends State<_HealingPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: widget.child,
    );
  }
}
