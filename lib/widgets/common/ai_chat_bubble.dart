import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/navigation/bondy_bottom_nav_bar.dart';

/// Global navigator key để định hướng từ MaterialApp builder context
final GlobalKey<NavigatorState> aiNavigatorKey = GlobalKey<NavigatorState>();

/// Widget floating bubble để truy cập nhanh AI Chat.
/// Hiển thị ở góc dưới trái màn hình, có animation pulsing glow huyền bí.
/// Được inject toàn cục qua MaterialApp.builder.
class AiChatBubble extends StatefulWidget {
  final Widget child;

  const AiChatBubble({super.key, required this.child});

  @override
  State<AiChatBubble> createState() => _AiChatBubbleState();
}

/// State abstract public để RouteObserver và MainShellScreen có thể truy cập
abstract class AiChatBubbleState extends State<AiChatBubble> {
  void setVisible(bool visible);
  void setHasBottomNav(bool has);
}

class _AiChatBubbleState extends AiChatBubbleState
    with TickerProviderStateMixin {
  // Animation pulsing (glow mở rộng và thu nhỏ)
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  // Animation xoay nhẹ icon ngôi sao
  late final AnimationController _rotateController;
  late final Animation<double> _rotateAnimation;

  // Animation shimmer (nhấp nháy ánh sáng)
  late final AnimationController _shimmerController;
  late final Animation<double> _shimmerAnimation;

  // Trạng thái hiển thị bubble - bắt đầu ẩn, RouteObserver sẽ cập nhật
  bool _visible = false;
  bool _hasBottomNav = false;

  @override
  void initState() {
    super.initState();

    // Pulse animation: vòng sáng bên ngoài
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Rotate animation: xoay chậm icon
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _rotateAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rotateController, curve: Curves.linear),
    );

    // Shimmer animation: sáng/tối nhẹ
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _shimmerAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  /// Cập nhật trạng thái hiển thị từ RouteObserver bên ngoài
  @override
  void setVisible(bool visible) {
    if (mounted && _visible != visible) {
      setState(() => _visible = visible);
    }
  }

  /// Cập nhật trạng thái có bottom nav để chỉnh khoảng cách dưới
  @override
  void setHasBottomNav(bool has) {
    if (mounted && _hasBottomNav != has) {
      setState(() => _hasBottomNav = has);
    }
  }

  void _onBubbleTap() {
    // Dùng global navigatorKey để chuyển hướng an toàn từ MaterialApp.builder
    aiNavigatorKey.currentState?.pushNamed('/ai-hub');
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_visible) _buildFloatingBubble(context),
      ],
    );
  }

  Widget _buildFloatingBubble(BuildContext context) {
    // Tính offset bottom: tránh xa bottom nav và system insets
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.padding.bottom;

    final double bottomOffset = _hasBottomNav
        ? BondyBottomNavBar.getReservedHeight(context) + 12.0
        : bottomPadding + 24.0;

    return Positioned(
      right: 24, // Căn góc dưới PHẢI theo đúng vị trí khoanh đỏ ở ảnh 1
      bottom: bottomOffset,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _pulseAnimation,
          _rotateAnimation,
          _shimmerAnimation,
        ]),
        builder: (context, _) {
          return GestureDetector(
            onTap: _onBubbleTap,
            behavior: HitTestBehavior.opaque, // Đảm bảo toàn bộ vùng bubble đều nhận diện được chạm
            child: SizedBox(
              width: 72,
              height: 72,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Vòng pulse ngoài cùng (mờ nhất)
                  _buildPulseRing(
                    radius: 36.0 + _pulseAnimation.value * 10,
                    opacity: 0.15 * (1.0 - _pulseAnimation.value),
                  ),
                  // Vòng pulse giữa
                  _buildPulseRing(
                    radius: 32.0 + _pulseAnimation.value * 6,
                    opacity: 0.25 * (1.0 - _pulseAnimation.value * 0.7),
                  ),
                  // Nút chính
                  _buildMainButton(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Vòng tròn phát sáng bên ngoài (pulse ring)
  Widget _buildPulseRing({required double radius, required double opacity}) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            BondyColors.primary.withValues(alpha: opacity),
            BondyColors.pink.withValues(alpha: opacity * 0.3),
            Colors.transparent,
          ],
          stops: const [0.4, 0.7, 1.0],
        ),
      ),
    );
  }

  /// Nút chính hình tròn gradient
  Widget _buildMainButton() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFF6B9D), // hồng đậm
            Color(0xFFFF4D6D), // đỏ hồng
            Color(0xFFFF8C42), // cam
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: BondyColors.primary.withValues(alpha: 0.5),
            blurRadius: 16 + _pulseAnimation.value * 8,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: const Color(0xFFFF8C42).withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Opacity(
        opacity: _shimmerAnimation.value,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon ngôi sao xoay chậm
            Transform.rotate(
              angle: _rotateAnimation.value * 2 * 3.14159,
              child: const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'AI',
              style: GoogleFonts.manrope(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Key toàn cục để truy cập state của AiChatBubble từ bên ngoài
final GlobalKey<AiChatBubbleState> aiBubbleKey =
    GlobalKey<AiChatBubbleState>();
