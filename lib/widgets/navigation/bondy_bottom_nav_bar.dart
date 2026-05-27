import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Bottom navigation matching the home_bondy.html mockup:
///   - White surface with frosted feel + 32 px rounded top
///   - Active tab = primary coral; inactive = on-surface muted
///   - Center "MATCH" button = gradient circle floating above the bar
///
/// 5 tabs (Discover · Healing · MATCH · Matches · Profile). `index` is the
/// logical screen index in MainShellScreen (0..3 for the four side tabs);
/// the center button calls [onMatchTap] and doesn't change the index.
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

  // Palette mirrors home_bondy.html (Material 3 expressive)
  static const _primary = Color(0xFFFF6B6B);
  static const _onMuted = Color(0xFF5D4E46);
  static const _outline = Color(0xFFFFD9C0);
  static const _gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF6B6B), Color(0xFFFFB28E)],
  );
  static const _itemHeight = 60.0;
  static const _matchItemHeight = 84.0;
  static const reservedHeightWithoutSafeArea = _matchItemHeight + 20.0;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: BottomNavBarPainter(),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: SizedBox(
            height: _matchItemHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: _NavItem(
                    index: 0,
                    currentIndex: currentIndex,
                    icon: Icons.explore_outlined,
                    activeIcon: Icons.explore,
                    label: 'Discover',
                    onTap: () => onTabSelected?.call(0),
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    index: 1,
                    currentIndex: currentIndex,
                    icon: Icons.self_improvement_outlined,
                    activeIcon: Icons.self_improvement,
                    label: 'Healing',
                    onTap: () => onTabSelected?.call(1),
                  ),
                ),
                Expanded(
                  child: _MatchButton(
                    onTap:
                        onMatchTap ??
                        () => Navigator.of(context).pushNamed('/discover'),
                    hasBadge: hasMatchBadge,
                    gradient: _gradient,
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    index: 2,
                    currentIndex: currentIndex,
                    icon: Icons.forum_outlined,
                    activeIcon: Icons.forum,
                    label: 'Matches',
                    onTap: () => onTabSelected?.call(2),
                    showBadge: hasMatchBadge,
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    index: 3,
                    currentIndex: currentIndex,
                    icon: Icons.person_outline,
                    activeIcon: Icons.person,
                    label: 'Profile',
                    onTap: () => onTabSelected?.call(3),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
      child: SizedBox(
        height: BondyBottomNavBar._itemHeight,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Icon(isActive ? activeIcon : icon, color: color, size: 24),
                  if (showBadge)
                    Positioned(
                      top: 2,
                      right: 2,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: BondyBottomNavBar._primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 5),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.visible,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MatchButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool hasBadge;
  final Gradient gradient;

  const _MatchButton({
    required this.onTap,
    required this.hasBadge,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final buttonSize = (constraints.maxWidth - 2)
            .clamp(52.0, 62.0)
            .toDouble();

        return GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            height: BondyBottomNavBar._matchItemHeight,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Transform.translate(
                  offset: const Offset(0, -6),
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: buttonSize,
                        height: buttonSize,
                        decoration: BoxDecoration(
                          gradient: gradient,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFFFF7E5F,
                              ).withValues(alpha: 0.35),
                              blurRadius: 22,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.favorite_rounded,
                          color: Colors.white,
                          size: buttonSize * 0.46,
                        ),
                      ),
                      if (hasBadge)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: BondyBottomNavBar._primary,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 5),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Match',
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.visible,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: BondyBottomNavBar._primary,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class BottomNavBarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.95)
      ..style = PaintingStyle.fill;

    Paint shadowPaint = Paint()
      ..color = const Color(0xFF5D4E46).withValues(alpha: 0.08)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    Path path = Path();
    
    final w = size.width;
    final h = size.height;
    final r = 32.0; // corner radius
    
    final centerX = w / 2;
    final curveWidth = 84.0;
    final curveHeight = 5.0;
    
    path.moveTo(0, r);
    path.quadraticBezierTo(0, 0, r, 0);
    path.lineTo(centerX - curveWidth / 2 - 10, 0);
    
    // Smooth arch using cubic Beziers wrapping tightly
    path.cubicTo(
      centerX - curveWidth / 2 + 4, 0,
      centerX - curveWidth / 2 + 10, -curveHeight,
      centerX, -curveHeight,
    );
    path.cubicTo(
      centerX + curveWidth / 2 - 10, -curveHeight,
      centerX + curveWidth / 2 - 4, 0,
      centerX + curveWidth / 2 + 10, 0,
    );
    
    path.lineTo(w - r, 0);
    path.quadraticBezierTo(w, 0, w, r);
    path.lineTo(w, h);
    path.lineTo(0, h);
    path.close();

    // Draw drop shadow
    canvas.drawPath(path.shift(const Offset(0, -3)), shadowPaint);
    
    // Draw background fill
    canvas.drawPath(path, paint);

    // Draw subtle cam outline on the upper lip
    Paint strokePaint = Paint()
      ..color = BondyBottomNavBar._outline.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
      
    Path strokePath = Path();
    strokePath.moveTo(0, r);
    strokePath.quadraticBezierTo(0, 0, r, 0);
    strokePath.lineTo(centerX - curveWidth / 2 - 10, 0);
    strokePath.cubicTo(
      centerX - curveWidth / 2 + 4, 0,
      centerX - curveWidth / 2 + 10, -curveHeight,
      centerX, -curveHeight,
    );
    strokePath.cubicTo(
      centerX + curveWidth / 2 - 10, -curveHeight,
      centerX + curveWidth / 2 - 4, 0,
      centerX + curveWidth / 2 + 10, 0,
    );
    strokePath.lineTo(w - r, 0);
    strokePath.quadraticBezierTo(w, 0, w, r);
    
    canvas.drawPath(strokePath, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

