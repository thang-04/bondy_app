# Design System Migration Specification: The Digital Sanctuary

**Project:** Bondy_App (Flutter)
**Date:** 2026-05-14
**Scope:** Home screen widgets migration (Phase 1), with extensible patterns for other screens
**Design System Reference:** DESIGN.md "The Digital Sanctuary"

---

## 1. Overview

### 1.1 Creative North Star
The Digital Sanctuary transforms Bondy from a rigid "catalog" dating app into an editorial, immersive experience prioritizing empathy and healing. Key principles:
- **Intentional Asymmetry** - Profile images may bleed off-edge or overlap typography
- **Tonal Depth** - Soft, glowing transitions replace harsh dividers
- **Emotional Color** - Palette shifts from deep safe purples to vibrant romantic pinks

### 1.2 Migration Philosophy
1. **Phase 1:** Home screen widgets (this spec)
2. **Phase 2:** Shared components and theme infrastructure
3. **Phase 3:** Other screens following same patterns

---

## 2. Design Violations Summary

| Widget | Violations |
|--------|------------|
| `SuggestionCardWidget` | Uses multi-color gradient instead of Signature Gradient; 1px border on inner elements |
| `MilestoneReminderWidget` | Orange palette not in design system; has border (violates no-line rule) |
| `EmotionCheckinWidget` | Has 1px border (violates no-line rule); uses black-tinted shadow |
| `BannerWidget` | Uses orange-pink gradient not in design system; has implicit border via gradient |
| `DiscoveryCardWidget` | Has 1px border everywhere (violates no-line rule); border-radius 16px (too small) |
| `SurveyOptionCard` | Has 1px borders; border-radius 8px (too small) |
| `BondyButton` | Border-radius 8px (too small) |

---

## 3. Design System Token Mapping

### 3.1 Color Tokens

| DESIGN.md Token | Current Bondy Color | New Hex Value | Usage |
|-----------------|---------------------|---------------|-------|
| **Primary** | `#F87171` (Tailwind red-400) | `#b70047` | CTAs, active states |
| **Primary Container** | `#FFF1F2` | `#ff728f` | Light backgrounds, chips |
| **Secondary** | `#FDA4AF` | `#92348e` | Secondary actions, accents |
| **Tertiary** | (not defined) | `#994100` | Sparks, highlights |
| **Tertiary Fixed** | `#FF9800` (orange) | `#FD7000` | Healing pulse, warmth |
| **Surface** | `#FFF1F2` | `#fbf5f7` | Base background |
| **Surface Container Low** | `#F5EFF1` | `#f5eff1` | Card backgrounds |
| **Surface Container Lowest** | `#FFFFFF` | `#ffffff` | Elevated cards |
| **On Surface** | `#2D0A15` | `#302e30` | Primary text |
| **On Surface Variant** | `#8A6A75` | (derived) | Secondary text |
| **Outline Variant** | (not defined) | `rgba(48, 46, 48, 0.15)` | Ghost borders |

### 3.2 Signature Gradient (Main CTA)

```
From: LinearGradient(#F87171 → #FDA4AF) [WRONG]
To:   LinearGradient(#FF0066 → #FF007F) [CORRECT per DESIGN.md]
```

### 3.3 Shadow Tokens

| Current | Design System Target |
|---------|---------------------|
| `Colors.black.withOpacity(0.05)` | `rgba(183, 0, 71, 0.08)` (pink-tinted) |
| `Colors.black.withOpacity(0.04)` | `rgba(183, 0, 71, 0.06)` |
| Blur 8-12px | Blur 32px+ at 6% opacity for floating elements |

---

## 4. Border Radius Migration

| Current Value | Design System Target | Affected Widgets |
|---------------|----------------------|------------------|
| 8px | 24px (`round-md`) | Buttons, inputs |
| 16px | 24px | Cards, containers |
| 20px | 32px (`round-lg`) | Large cards, modals |
| `BorderRadius.circular(30)` | `BorderRadius.circular(9999)` (`round-full`) | Chips, pills |

---

## 5. The "No-Line" Rule

**Strict Mandate:** Prohibit 1px solid borders for sectioning.

### Before (VIOLATION):
```dart
Container(
  decoration: BoxDecoration(
    border: Border.all(color: Color(0xFFE5E7EB)), // 1px border - FORBIDDEN
  ),
)
```

### After (COMPLIANT):
```dart
// Option 1: Background shift only (preferred)
Container(
  decoration: BoxDecoration(
    color: Color(0xFFF5EFF1), // surface-container-low for section separation
  ),
)

// Option 2: Ghost border (only when accessibility requires)
Container(
  decoration: BoxDecoration(
    border: Border.all(
      color: Color(0xFF302e30).withOpacity(0.15), // outline-variant at 15%
    ),
  ),
)
```

---

## 6. Widget-Specific Migration

### 6.1 SuggestionCardWidget

**Current State:**
- Multi-color gradient: `#FFB3A7` → `#E8A0BF` → `#AE8FDB`
- Button gradient: `#FF8A50` → `#D946B8`
- Border-radius: 20px (ACCEPTABLE)
- Inner tag has white 30% opacity background (OK)

**Required Changes:**
1. Replace card gradient with Signature Gradient: `#FF0066` → `#FF007F`
2. Button gradient must match card gradient (same Signature Gradient)
3. Increase border-radius to 24px

**After:**
```dart
Container(
  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
  padding: const EdgeInsets.all(20),
  decoration: BoxDecoration(
    gradient: const LinearGradient(
      colors: [Color(0xFFFF0066), Color(0xFFFF007F)], // Signature Gradient
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(24), // round-md
  ),
  child: // ... content unchanged except button gradient
)

// Button gradient must match:
gradient: const LinearGradient(
  colors: [Color(0xFFFF0066), Color(0xFFFF007F)],
),
borderRadius: BorderRadius.circular(24), // round-full for pill shape
```

---

### 6.2 MilestoneReminderWidget

**Current State:**
- Gradient: `#FFF3E0` → `#FFE0B2` (warm orange tones)
- Border: `Color(0xFFFFCC80)` (1px - VIOLATION)
- Icon background: `Color(0xFFFF9800)` with 15% opacity
- Days badge: solid orange `#FF9800`

**Required Changes:**
1. Remove border (no-line rule)
2. Replace orange palette with tertiary palette (`#994100`, `#FD7000`)
3. Use surface-container-low for background shift
4. Icon background uses tertiary Fixed `#FD7000`

**After:**
```dart
Container(
  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
  padding: const EdgeInsets.all(20),
  decoration: BoxDecoration(
    color: Color(0xFFFFF3E0), // surface shift, NO border
    borderRadius: BorderRadius.circular(24),
  ),
  child: Row(
    children: [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Color(0xFFFD7000).withOpacity(0.12), // tertiary_fixed glow
          shape: BoxShape.circle,
        ),
        child: const Text('🎉', style: TextStyle(fontSize: 24)),
      ),
      // ... rest unchanged
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Color(0xFFFD7000), // tertiary_fixed
          borderRadius: BorderRadius.circular(9999), // round-full
        ),
        // ... text unchanged
      ),
    ],
  ),
)
```

---

### 6.3 EmotionCheckinWidget

**Current State:**
- White background with 1px border: `Color(0xFFFFE0E6)` (VIOLATION)
- Shadow: black at 5% opacity (should be pink-tinted)
- Container border-radius: 20px (ACCEPTABLE)

**Required Changes:**
1. Remove border entirely
2. Change shadow to pink-tinted: `rgba(183, 0, 71, 0.06)`
3. Increase border-radius to 24px

**After:**
```dart
Container(
  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
  padding: const EdgeInsets.all(20),
  decoration: BoxDecoration(
    color: Colors.white, // surface-container-lowest
    borderRadius: BorderRadius.circular(24),
    // NO border
    boxShadow: [
      BoxShadow(
        color: Color(0xFFb70047).withOpacity(0.06), // pink-tinted shadow
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  ),
)
```

---

### 6.4 BannerWidget

**Current State:**
- Gradient: `#FF8A65` → `#E91E63` (not in design system)
- Has shadow with E91E63 at 25% (close to correct, but gradient wrong)

**Required Changes:**
1. Replace gradient with Signature Gradient: `#FF0066` → `#FF007F`
2. Shadow remains acceptable (pink-tinted is correct)

**After:**
```dart
Container(
  decoration: BoxDecoration(
    gradient: const LinearGradient(
      colors: [Color(0xFFFF0066), Color(0xFFFF007F)], // Signature Gradient
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(24),
    boxShadow: [
      BoxShadow(
        color: Color(0xFFFF0066).withOpacity(0.25),
        blurRadius: 16,
        offset: const Offset(0, 6),
      ),
    ],
  ),
)
```

---

### 6.5 DiscoveryCardWidget

**Current State:**
- Profile chip: 1px border `Color(0xFFE5E7EB)` (VIOLATION)
- Profile chip border-radius: 16px (too small)
- Empty state: 1px border (VIOLATION)

**Required Changes:**
1. Remove all borders (no-line rule)
2. Increase border-radius to 24px
3. Use pink-tinted shadow

**After (_ProfileChip):**
```dart
Container(
  width: 130,
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Colors.white, // surface-container-lowest
    borderRadius: BorderRadius.circular(24), // round-md
    // NO border
    boxShadow: [
      BoxShadow(
        color: Color(0xFFb70047).withOpacity(0.06),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  ),
)
```

**After (_EmptyDiscovery):**
```dart
Container(
  width: double.infinity,
  padding: const EdgeInsets.all(20),
  decoration: BoxDecoration(
    color: Color(0xFFF5EFF1), // surface-container-low - background shift
    borderRadius: BorderRadius.circular(24),
    // NO border
  ),
)
```

---

### 6.6 SurveyOptionCard

**Current State:**
- 1px border on container (VIOLATION)
- Selected state: 2px border in primary color
- Border-radius: 8px (too small)

**Required Changes:**
1. Remove borders, use background color shift for selection
2. Increase border-radius to 24px
3. Use surface-container colors for different states

**After:**
```dart
AnimatedContainer(
  duration: const Duration(milliseconds: 200),
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: isSelected
        ? Color(0xFFFF728F).withOpacity(0.12) // primary-container tint
        : Colors.white, // surface-container-lowest
    borderRadius: BorderRadius.circular(24),
    // NO border - selection indicated by background color
    boxShadow: isSelected
        ? [
            BoxShadow(
              color: Color(0xFFb70047).withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ]
        : null,
  ),
  child: Row(
    children: [
      // ... content unchanged
      if (isSelected)
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFF0066), Color(0xFFFF007F)],
            ),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, color: Colors.white, size: 16),
        )
      else
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Color(0xFF302e30).withOpacity(0.15), // outline-variant
              width: 2,
            ),
          ),
        ),
    ],
  ),
)
```

---

### 6.7 BondyButton

**Current State:**
- Border-radius: 8px (too small)
- ElevatedButton uses primary color

**Required Changes:**
1. Increase border-radius to 24px (`round-md`)
2. Primary buttons should use Signature Gradient
3. Consider glassmorphism for floating action buttons

**After (ElevatedButton):**
```dart
elevatedButtonTheme: ElevatedButtonThemeData(
  style: ElevatedButton.styleFrom(
    backgroundColor: BondyColors.primary, // stays for now, gradient in button widget
    foregroundColor: Colors.white,
    minimumSize: const Size(double.infinity, 56),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24), // round-md
    ),
    elevation: 0,
  ),
),
```

**For buttons requiring gradient:**
```dart
Container(
  decoration: BoxDecoration(
    gradient: const LinearGradient(
      colors: [Color(0xFFFF0066), Color(0xFFFF007F)],
    ),
    borderRadius: BorderRadius.circular(24),
    boxShadow: [
      BoxShadow(
        color: Color(0xFFb70047).withOpacity(0.25),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  ),
  child: ElevatedButton(
    onPressed: onPressed,
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.transparent,
      shadowColor: Colors.transparent,
      // ... other properties
    ),
    child: // content
  ),
)
```

---

## 7. Theme Infrastructure Changes (app_theme.dart)

### 7.1 New BondyColors

```dart
class BondyColors {
  // PRIMARY (The Heartbeat)
  static const Color primary = Color(0xFFb70047);           // Primary
  static const Color primaryContainer = Color(0xFFff728f);   // Primary Container
  static const Color onPrimary = Colors.white;

  // SECONDARY (The Soul)
  static const Color secondary = Color(0xFF92348e);
  static const Color secondaryContainer = Color(0xFFffbdf4);
  static const Color onSecondaryContainer = Color(0xFF7a1c78);

  // TERTIARY (The Spark)
  static const Color tertiary = Color(0xFF994100);
  static const Color tertiaryFixed = Color(0xFFFD7000);

  // SURFACE (The Canvas)
  static const Color surface = Color(0xFFfbf5f7);
  static const Color surfaceContainerLow = Color(0xFFf5eff1);
  static const Color surfaceContainerLowest = Color(0xFFffffff);
  static const Color surfaceDim = Color(0xFFe9d6d9);
  static const Color surfaceContainerHigh = Color(0xFFece2e5);
  static const Color surfaceContainerHighest = Color(0xFFe3d8dc);
  static const Color surfaceBright = Color(0xFFfffdf);

  // ON SURFACE
  static const Color onSurface = Color(0xFF302e30);
  static const Color onSurfaceVariant = Color(0xFF7a7073);

  // OUTLINE VARIANT (Ghost Border)
  static const Color outlineVariant = Color(0xFF302e30).withOpacity(0.15);

  // SIGNATURE GRADIENT
  static const LinearGradient signatureGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF0066), Color(0xFFFF007F)],
  );

  // SHADOWS
  static const Color shadowPink = Color(0xFFb70047);
  static const double shadowOpacity = 0.08;
  static const double shadowBlur = 32.0;

  // TEXT
  static const Color textPrimary = Color(0xFF302e30);
  static const Color textSecondary = Color(0xFF7a7073);
  static const Color textHint = Color(0xFFa8a3a6);

  // DEPRECATED - for migration reference
  static const Color divider = Color(0xFFE5E7EB);
  static const Color cardBorder = Color(0xFFE5E7EB);
}
```

### 7.2 New BorderRadius Constants

```dart
class BondyRadius {
  static const BorderRadius roundXs = BorderRadius.all(Radius.circular(8));
  static const BorderRadius roundSm = BorderRadius.all(Radius.circular(12));
  static const BorderRadius roundMd = BorderRadius.all(Radius.circular(24));
  static const BorderRadius roundLg = BorderRadius.all(Radius.circular(32));
  static const BorderRadius roundFull = BorderRadius.all(Radius.circular(9999));

  // For specific use cases
  static const double cardRadius = 24.0;
  static const double buttonRadius = 24.0;
  static const double chipRadius = 9999.0;
}
```

### 7.3 New BoxShadow Helper

```dart
class BondyShadows {
  static List<BoxShadow> card({double opacity = 0.06, double blur = 12}) => [
    BoxShadow(
      color: BondyColors.shadowPink.withOpacity(opacity),
      blurRadius: blur,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> floating({double opacity = 0.08, double blur = 32}) => [
    BoxShadow(
      color: BondyColors.shadowPink.withOpacity(opacity),
      blurRadius: blur,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> pressed({double opacity = 0.04}) => [
    BoxShadow(
      color: BondyColors.shadowPink.withOpacity(opacity),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];
}
```

---

## 8. Migration Sequence

### Phase 1: Theme Infrastructure (Priority 1)
1. Update `BondyColors` class with new tokens
2. Add `BondyRadius` constants
3. Add `BondyShadows` helper class
4. Update `ColorScheme.fromSeed` in theme
5. Update `textTheme` configuration

### Phase 2: Shared Components (Priority 2)
1. Update `BondyButton` with new border-radius and gradient support
2. Update `SurveyOptionCard` to remove borders
3. Create `GlassmorphicContainer` reusable component for overlays

### Phase 3: Home Screen Widgets (Priority 3)
1. `BannerWidget` - Simpler, clear violations
2. `SuggestionCardWidget` - High visibility, multiple gradient fixes
3. `EmotionCheckinWidget` - Shadow fix + no border
4. `MilestoneReminderWidget` - Palette fix + no border
5. `DiscoveryCardWidget` - No border + increased radius

### Phase 4: Verification
1. Run app and visually verify all widgets
2. Check contrast ratios for accessibility
3. Verify animations use `ease-in-out` curve
4. Document any edge cases found

---

## 9. Reusable Component Patterns

### 9.1 SanctuaryCard (base card component)

```dart
class SanctuaryCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? backgroundColor;
  final List<BoxShadow>? shadows;

  const SanctuaryCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.shadows,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor ?? BondyColors.surfaceContainerLowest,
        borderRadius: BondyRadius.roundMd,
        boxShadow: shadows ?? BondyShadows.card(),
        // NO border by default - use background shift for structure
      ),
      child: child,
    );
  }
}
```

### 9.2 SignatureButton (gradient CTA button)

```dart
class SignatureButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData? icon;

  const SignatureButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: BondyColors.signatureGradient,
        borderRadius: BondyRadius.roundFull,
        boxShadow: BondyShadows.floating(opacity: 0.25),
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BondyRadius.roundFull,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[Icon(icon, color: Colors.white), const SizedBox(width: 8)],
            Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
```

### 9.3 ConnectionChip (round-full chip)

```dart
class ConnectionChip extends StatelessWidget {
  final String label;
  final Color? backgroundColor;
  final Color? textColor;

  const ConnectionChip({
    super.key,
    required this.label,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor ?? BondyColors.secondaryContainer,
        borderRadius: BondyRadius.roundFull,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor ?? BondyColors.onSecondaryContainer,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
```

---

## 10. Animation Requirements

Per DESIGN.md, all transitions must use "Liquid" easing:

```dart
// Apply to all AnimatedContainer, AnimatedOpacity, PageRoute
curvedAnimation: CurvedAnimation(
  parent: animation,
  curve: Curves.easeInOut, // 0.4, 0.0, 0.2, 1.0 equivalent
)

// For explicit cubic-bezier:
curve: Cubic(0.4, 0.0, 0.2, 1.0)
```

### Healing Pulse Animation (for safety/support icons)

```dart
class HealingPulse extends StatefulWidget {
  final Widget child;

  const HealingPulse({super.key, required this.child});

  @override
  State<HealingPulse> createState() => _HealingPulseState();
}

class _HealingPulseState extends State<HealingPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
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
```

---

## 11. Accessibility Checklist

- [ ] All primary text uses `on_surface` (`#302e30`), NOT pure black
- [ ] Primary button text uses white (on gradient)
- [ ] Ghost borders use `outline-variant` at 15% opacity maximum
- [ ] Shadows never exceed 8% opacity
- [ ] Connection Chips use `secondary_container` with `on_secondary_container`
- [ ] Healing Pulse animation on Safety/Support icons uses `tertiary_fixed`
- [ ] Minimum touch target: 48x48dp
- [ ] Color contrast ratio: 4.5:1 minimum for body text

---

## 12. File Changes Summary

| File | Changes |
|------|---------|
| `lib/theme/app_theme.dart` | Complete rewrite of BondyColors, add BondyRadius, BondyShadows |
| `lib/widgets/bondy_button.dart` | Border-radius 8px → 24px, gradient support |
| `lib/widgets/survey_option_card.dart` | Remove borders, bg color shift, increase radius |
| `lib/widgets/home/banner_widget.dart` | Signature Gradient, remove implicit border |
| `lib/widgets/home/suggestion_card_widget.dart` | Signature Gradient, button gradient match |
| `lib/widgets/home/emotion_checkin_widget.dart` | No border, pink shadow |
| `lib/widgets/home/milestone_reminder_widget.dart` | No border, tertiary palette |
| `lib/widgets/home/discovery_card_widget.dart` | No borders, increased radius |
| `lib/widgets/sanctuary_card.dart` | NEW - reusable base card |
| `lib/widgets/signature_button.dart` | NEW - gradient CTA |
| `lib/widgets/connection_chip.dart` | NEW - round-full chip |
| `lib/widgets/healing_pulse.dart` | NEW - breathing animation wrapper |

---

## 13. Verification Commands

After migration, run these checks:

```bash
# Verify no 1px borders remain (should return empty)
grep -r "Border.all" lib/widgets/

# Verify Signature Gradient usage (should find #FF0066)
grep -r "FF0066" lib/widgets/

# Verify border-radius 24px usage
grep -r "circular(24)" lib/widgets/
```

---

*End of Specification*