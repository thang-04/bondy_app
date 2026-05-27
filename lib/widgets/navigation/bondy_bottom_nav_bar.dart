import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Bottom navigation - kiểu BottomAppBar notched FAB:
///   - Viền trên PHẲNG, sát với icon (Discover, Healing, Matches, Profile)
///   - Nút Match (trái tim) LỒI HẲN lên trên khỏi nav bar
///   - Viền trên CONG VÒNG THEO hình tròn của nút Match (convex arch)
///
/// 5 tabs: Discover · Healing · [MATCH FAB] · Matches · Profile
class BondyBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTabSelected;
  final VoidCallback? onMatchTap;
  final bool hasMatchBadge;

  const BondyBottomNavBar({
    super.key,
    required this.currentIndex,
    this.onTabSelected,
    this.onMatchTap,
    this.hasMatchBadge = false,
  });

  // Bảng màu
  static const _primary  = Color(0xFFFF6B6B);
  static const _onMuted  = Color(0xFF5D4E46);
  static const _outline  = Color(0xFFFFD9C0);
  static const _gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF6B6B), Color(0xFFFFB28E)],
  );

  /// Kích thước nút Match (đường kính)
  static const double _fabSize = 56.0;

  /// Bán kính notch trên painter (lớn hơn fabSize/2 một chút để có margin)
  static const double _notchRadius = _fabSize / 2 + 6.0;

  /// Chiều cao khu vực icon + label bên dưới
  static const double _barHeight = 58.0;

  /// Nút Match nhô lên trên viền nav bar bao nhiêu pixel
  static const double _fabElevation = 30.0;

  /// reservedHeight để các màn hình tính padding bottom
  static const double reservedHeightWithoutSafeArea = _barHeight + _fabElevation;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // Tổng chiều cao widget = bar + phần FAB nhô lên
      height: _barHeight + _fabElevation,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ──────────────────────────────────────────────
          // 1. Nền nav bar với đường viền cong theo FAB
          // ──────────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: CustomPaint(
              painter: _NotchedNavPainter(
                notchRadius: _notchRadius,
                cornerRadius: 20.0,
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  height: _barHeight,
                  child: Row(
                    children: [
                      // Discover
                      Expanded(
                        child: _NavItem(
                          index: 0,
                          currentIndex: currentIndex,
                          icon: Icons.home_outlined,
                          activeIcon: Icons.home_rounded,
                          label: 'Home',
                          onTap: () => onTabSelected?.call(0),
                        ),
                      ),
                      // Healing
                      Expanded(
                        child: _NavItem(
                          index: 1,
                          currentIndex: currentIndex,
                          icon: Icons.monitor_heart_outlined,
                          activeIcon: Icons.monitor_heart,
                          label: 'Healing',
                          onTap: () => onTabSelected?.call(1),
                        ),
                      ),
                      // Khoảng trống giữa cho FAB
                      const Expanded(child: SizedBox()),
                      // Matches
                      Expanded(
                        child: _NavItem(
                          index: 2,
                          currentIndex: currentIndex,
                          icon: Icons.chat_bubble_outline_rounded,
                          activeIcon: Icons.chat_bubble_rounded,
                          label: 'Matches',
                          onTap: () => onTabSelected?.call(2),
                          showBadge: hasMatchBadge,
                        ),
                      ),
                      // Profile
                      Expanded(
                        child: _NavItem(
                          index: 3,
                          currentIndex: currentIndex,
                          icon: Icons.person_outline_rounded,
                          activeIcon: Icons.person_rounded,
                          label: 'Profile',
                          onTap: () => onTabSelected?.call(3),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ──────────────────────────────────────────────
          // 2. Nút Match (FAB) lồi lên trên
          // ──────────────────────────────────────────────
          Positioned(
            // Canh giữa màn hình
            left: 0,
            right: 0,
            // Nằm ở phía trên: bottom của FAB = _barHeight - (_fabSize/2 - _fabElevation/2)
            bottom: _barHeight - _fabSize / 2 + _fabElevation / 2 - 4,
            child: Center(
              child: GestureDetector(
                onTap: onMatchTap ?? () {},
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: _fabSize,
                  height: _fabSize,
                  decoration: BoxDecoration(
                    gradient: _gradient,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3.5),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF7E5F).withValues(alpha: 0.45),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.favorite_rounded,
                        color: Colors.white,
                        size: _fabSize * 0.46,
                      ),
                      if (hasMatchBadge)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: _primary, width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ──────────────────────────────────────────────
          // 3. Label "Match" bên dưới FAB, nằm trong bar
          // ──────────────────────────────────────────────
          Positioned(
            bottom: 25,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Match',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: _primary,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// NavItem
// ──────────────────────────────────────────────────────────────────────────────
class _NavItem extends StatelessWidget {
  final int index;
  final int currentIndex;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final VoidCallback onTap;
  final bool showBadge;

  const _NavItem({
    required this.index,
    required this.currentIndex,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.onTap,
    this.showBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = currentIndex == index;
    final color = isActive
        ? BondyBottomNavBar._primary
        : BondyBottomNavBar._onMuted.withValues(alpha: 0.5);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Icon(isActive ? activeIcon : icon, color: color, size: 22),
                if (showBadge)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: BondyBottomNavBar._primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Painter: viền trên phẳng 2 bên, cong VỒM LÊN theo hình tròn FAB ở giữa
// ──────────────────────────────────────────────────────────────────────────────
class _NotchedNavPainter extends CustomPainter {
  final double notchRadius;  // bán kính vùng cong quanh FAB
  final double cornerRadius; // bán kính góc 2 bên nav bar

  const _NotchedNavPainter({
    required this.notchRadius,
    required this.cornerRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2; // tâm X của FAB
    final r  = cornerRadius;
    final nr = notchRadius;

    // Shadow
    final shadowPaint = Paint()
      ..color = const Color(0xFF5D4E46).withValues(alpha: 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    // Fill
    final fillPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.97)
      ..style = PaintingStyle.fill;

    // Stroke (viền mỏng)
    final strokePaint = Paint()
      ..color = BondyBottomNavBar._outline.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // ── Vẽ path ──────────────────────────────────────────────────────────
    // Bắt đầu từ góc dưới trái → đi lên → sang phải → đi lên theo vòm FAB
    // → đi xuống → đi tiếp sang phải → góc dưới phải

    // Điểm bắt đầu vòm cong: cách tâm FAB một khoảng nr theo mỗi bên
    // Khoảng cách ngang từ tâm FAB tới điểm tiếp xúc của đường thẳng + vòm
    final archHalfWidth = nr + 8.0;
    final archTop = -(nr * 0.55); // đỉnh vòm nhô lên bao nhiêu pixel phía trên nav bar

    final path = Path();

    // Góc dưới trái
    path.moveTo(0, h);

    // Cạnh trái → góc trên trái (bo tròn)
    path.lineTo(0, r);
    path.quadraticBezierTo(0, 0, r, 0);

    // Đường thẳng trên → đến điểm bắt đầu vòm trái
    path.lineTo(cx - archHalfWidth, 0);

    // Vòm cong lên (cubic Bezier mượt mà)
    // Đi từ cx-archHalfWidth lên đỉnh vòm (cx, archTop) rồi xuống cx+archHalfWidth
    path.cubicTo(
      cx - archHalfWidth * 0.55, 0,     // control point 1
      cx - nr * 0.6,              archTop, // control point 2 (gần đỉnh trái)
      cx,                         archTop, // đỉnh vòm
    );
    path.cubicTo(
      cx + nr * 0.6,              archTop, // control point 1 (gần đỉnh phải)
      cx + archHalfWidth * 0.55,  0,     // control point 2
      cx + archHalfWidth,         0,     // điểm kết thúc vòm phải
    );

    // Đường thẳng trên → góc trên phải (bo tròn)
    path.lineTo(w - r, 0);
    path.quadraticBezierTo(w, 0, w, r);

    // Cạnh phải → góc dưới phải
    path.lineTo(w, h);
    path.close();

    // Vẽ shadow → fill → stroke
    canvas.drawPath(path.shift(const Offset(0, -2)), shadowPaint);
    canvas.drawPath(path, fillPaint);

    // Stroke chỉ vẽ viền trên (không vẽ đáy)
    final strokePath = Path();
    strokePath.moveTo(r, 0);
    strokePath.lineTo(cx - archHalfWidth, 0);
    strokePath.cubicTo(
      cx - archHalfWidth * 0.55, 0,
      cx - nr * 0.6,              archTop,
      cx,                         archTop,
    );
    strokePath.cubicTo(
      cx + nr * 0.6,              archTop,
      cx + archHalfWidth * 0.55,  0,
      cx + archHalfWidth,         0,
    );
    strokePath.lineTo(w - r, 0);

    canvas.drawPath(strokePath, strokePaint);
  }

  @override
  bool shouldRepaint(_NotchedNavPainter old) =>
      old.notchRadius != notchRadius || old.cornerRadius != cornerRadius;
}
