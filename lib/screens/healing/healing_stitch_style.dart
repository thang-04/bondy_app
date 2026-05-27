import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HealingStitchColors {
  static const warmBackground = Color(0xFFFAF9F6);
  static const creamBackground = Color(0xFFFDFBF7);
  static const contentBackground = Color(0xFFFAFAFA);
  static const surface = Color(0xFFFFFFFF);
  static const textMain = Color(0xFF2D2A26);
  static const textMuted = Color(0xFF88837E);
  static const textSoft = Color(0xFF6B7280);
  static const coral = Color(0xFFFF6B6B);
  static const coralLight = Color(0xFFFF8E8E);
  static const orange = Color(0xFFFF8E53);
  static const pink = Color(0xFFEA2A5A);
  static const purple = Color(0xFF9F2AEA);
  static const border = Color(0xFFF1EEE9);
  static const paleCoral = Color(0xFFFFF2F2);

  static const warmGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [coral, orange],
  );

  static const brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [coral, pink, purple],
  );
}

class HealingStitchAssets {
  static const dailyHero = 'assets/images/healing_stitch/stitch_healing_13.jpg';
  static const dailyAudioWater =
      'assets/images/healing_stitch/stitch_healing_04.jpg';
  static const dailyAudioBeach =
      'assets/images/healing_stitch/stitch_healing_08.jpg';
  static const dailyAudioForest =
      'assets/images/healing_stitch/stitch_healing_09.jpg';

  static const compactHero =
      'assets/images/healing_stitch/stitch_healing_19.jpg';
  static const compactAudioWater =
      'assets/images/healing_stitch/stitch_healing_02.jpg';
  static const compactAudioStones =
      'assets/images/healing_stitch/stitch_healing_07.jpg';

  static const contentHero =
      'assets/images/healing_stitch/stitch_healing_01.jpg';
  static const apology = 'assets/images/healing_stitch/stitch_healing_17.jpg';
  static const selfReflection =
      'assets/images/healing_stitch/stitch_healing_05.jpg';
  static const activeListening =
      'assets/images/healing_stitch/stitch_healing_16.jpg';
  static const fightingFair =
      'assets/images/healing_stitch/stitch_healing_12.jpg';
  static const nonViolentTalk =
      'assets/images/healing_stitch/stitch_healing_18.jpg';
  static const rekindling =
      'assets/images/healing_stitch/stitch_healing_03.jpg';
  static const loveLanguages =
      'assets/images/healing_stitch/stitch_healing_11.jpg';

  static const openBook = 'assets/images/healing_stitch/stitch_healing_06.jpg';
  static const meditation =
      'assets/images/healing_stitch/stitch_healing_15.jpg';
  static const avatarOne = 'assets/images/healing_stitch/stitch_healing_14.jpg';
  static const avatarTwo = 'assets/images/healing_stitch/stitch_healing_10.jpg';
}

TextStyle healingText({
  double size = 14,
  FontWeight weight = FontWeight.w500,
  Color color = HealingStitchColors.textMain,
  double? height,
}) {
  return GoogleFonts.manrope(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
  );
}

BoxShadow healingSoftShadow([double opacity = 0.05]) {
  return BoxShadow(
    color: Colors.black.withValues(alpha: opacity),
    blurRadius: 20,
    offset: const Offset(0, 4),
  );
}

BoxShadow healingGlowShadow([Color color = HealingStitchColors.coral]) {
  return BoxShadow(
    color: color.withValues(alpha: 0.28),
    blurRadius: 18,
    offset: const Offset(0, 8),
  );
}

class HealingIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const HealingIconButton({super.key, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: HealingStitchColors.surface,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: HealingStitchColors.border),
            boxShadow: [healingSoftShadow(0.035)],
          ),
          child: Icon(icon, size: 20, color: HealingStitchColors.textMain),
        ),
      ),
    );
  }
}

class HealingTopBar extends StatelessWidget {
  final String title;
  final bool showBack;
  final IconData trailingIcon;
  final VoidCallback? onBack;
  final VoidCallback? onTrailing;

  const HealingTopBar({
    super.key,
    required this.title,
    this.showBack = true,
    this.trailingIcon = Icons.settings_outlined,
    this.onBack,
    this.onTrailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          if (showBack)
            HealingIconButton(
              icon: Icons.arrow_back,
              onTap: onBack ?? () => Navigator.of(context).maybePop(),
            )
          else
            const SizedBox(width: 40, height: 40),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: healingText(size: 16, weight: FontWeight.w800),
            ),
          ),
          HealingIconButton(icon: trailingIcon, onTap: onTrailing),
        ],
      ),
    );
  }
}

class HealingWeekTabs extends StatelessWidget {
  const HealingWeekTabs({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final selected = index == 0;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              gradient: selected ? HealingStitchColors.warmGradient : null,
              color: selected ? null : HealingStitchColors.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: selected
                    ? Colors.transparent
                    : HealingStitchColors.border,
              ),
              boxShadow: selected
                  ? [healingGlowShadow()]
                  : [healingSoftShadow(0.03)],
            ),
            child: Center(
              child: Text(
                'Tuần ${index + 1}',
                style: healingText(
                  size: 13,
                  weight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected
                      ? Colors.white
                      : HealingStitchColors.textMuted,
                ),
              ),
            ),
          );
        },
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemCount: 4,
      ),
    );
  }
}

class HealingGradientButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  const HealingGradientButton({
    super.key,
    required this.label,
    this.icon = Icons.arrow_forward,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          height: 54,
          decoration: BoxDecoration(
            gradient: HealingStitchColors.warmGradient,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [healingGlowShadow(HealingStitchColors.orange)],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: healingText(
                  size: 15,
                  weight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Icon(icon, size: 20, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

class HealingRouteBottomNav extends StatelessWidget {
  final int selectedIndex;

  const HealingRouteBottomNav({super.key, this.selectedIndex = 1});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.home_outlined, 'Trang chủ', 0),
      (Icons.self_improvement, 'Chữa lành', 1),
      (Icons.forum_outlined, 'Cộng đồng', 2),
      (Icons.person_outline, 'Cá nhân', 3),
    ];

    return Container(
      height: 88,
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        border: const Border(
          top: BorderSide(color: HealingStitchColors.border),
        ),
        boxShadow: [healingSoftShadow(0.06)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (final item in items)
            _BottomNavItem(
              icon: item.$1,
              label: item.$2,
              selected: item.$3 == selectedIndex,
              onTap: () {
                if (item.$3 == selectedIndex) return;
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/home', (_) => false);
              },
            ),
        ],
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? HealingStitchColors.coral
        : HealingStitchColors.textMuted;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 68,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: selected ? const EdgeInsets.all(6) : EdgeInsets.zero,
              decoration: BoxDecoration(
                color: selected
                    ? HealingStitchColors.paleCoral
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 25, color: color),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: healingText(
                size: 10,
                weight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
