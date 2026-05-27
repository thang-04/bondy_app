# Bondy Home Screen Flutter Implementation Specification

**Date:** 2026-05-14
**Project:** Bondy_App (Flutter)
**Scope:** Tab Home Only
**Design System:** "The Digital Sanctuary" (DESIGN.md)
**Status:** Implementation Guide

---

## 1. Overview

This document specifies a full rebuild of the Bondy Home Screen Tab, aligning the existing Flutter implementation with the "Digital Sanctuary" design system defined in DESIGN.md.

**Creative North Star:** Move away from rigid, grid-locked "catalog" aesthetics toward an editorial, immersive experience prioritizing empathy and healing through **Intentional Asymmetry** and **Tonal Depth**.

**Key Design Mandates:**
- **NO 1px solid borders** for sectioning — use background color shifts instead
- **No pure black (#000000)** for text — use `on_surface` (#302e30)
- **No 100% opaque shadows** — max 6% opacity with pink tint
- **No hard corners** — minimum `round-md` (24px) everywhere
- **Glassmorphism** for all overlays (12-20px backdrop blur)
- **Signature Gradient** (#FF0066 to #FF007F) for all main CTAs

---

## 2. File-by-File Implementation Checklist

| File | Action | Priority |
|------|--------|----------|
| `lib/theme/app_theme.dart` | Complete rewrite | P0 |
| `lib/screens/home/main_shell_screen.dart` | Full rebuild | P0 |
| `lib/widgets/home/banner_widget.dart` | Refactor | P0 |
| `lib/widgets/home/emotion_checkin_widget.dart` | Refactor | P0 |
| `lib/widgets/home/milestone_reminder_widget.dart` | Refactor | P0 |
| `lib/widgets/home/discovery_card_widget.dart` | Refactor | P0 |
| `lib/widgets/home/suggestion_card_widget.dart` | Refactor | P0 |
| `lib/widgets/home/relationship_strength_card.dart` | **NEW FILE** | P0 |

---

## 3. Theme Changes: `lib/theme/app_theme.dart`

### 3.1 Before vs After Color Mapping

| Current (Broken) | DESIGN.md Token | New Value | Usage |
|-----------------|-----------------|-----------|-------|
| `primary = Color(0xFFF87171)` | `primary` | `#b70047` | `Color(0xFFB70047)` |
| `primaryDark = Color(0xFFE11D48)` | — | `#8b0033` | `Color(0xFF8B0033)` |
| `primaryLight = Color(0xFFFFF1F2)` | `surface-container-low` | `#f5eff1` | `Color(0xFFF5EFF1)` |
| `secondary = Color(0xFFFDA4AF)` | `primary-container` | `#ffbdf4` | `Color(0xFFFFBDF4)` |
| `background = Color(0xFFFFF1F2)` | `surface` | `#fbf5f7` | `Color(0xFFFBF5F7)` |
| `surface = Colors.white` | `surface-container-lowest` | `#ffffff` | `Color(0xFFFFFFFF)` |
| `textPrimary = Color(0xFF2D0A15)` | `on-surface` | `#302e30` | `Color(0xFF302E30)` |
| `textSecondary = Color(0xFF8A6A75)` | `on-surface-variant` | `#6b6267` | `Color(0xFF6B6267)` |
| `textHint = Color(0xFFB89AA5)` | — | `#9c9099` | `Color(0xFF9C9099)` |
| `divider = Color(0xFFE5E7EB)` | `outline-variant` | `#e9e2e6` | `Color(0xFFE9E2E6)` |
| `error = Color(0xFFEF4444)` | `error` | `#ba1a1a` | `Color(0xFFBA1A1A)` |
| `cardBorder = Color(0xFFE5E7EB)` | `outline-variant` | REMOVE | **NO LINE RULE** |
| `selectedCard = Color(0xFFFFF1F2)` | `surface-container-low` | `#f5eff1` | `Color(0xFFF5EFF1)` |
| `selectedCardBorder = Color(0xFFF87171)` | `primary` | `#b70047` | `Color(0xFFB70047)` |
| `chatBubbleUser = Color(0xFFF87171)` | `primary` | `#b70047` | `Color(0xFFB70047)` |
| `chatBubbleOther = Color(0xFFF3F4F6)` | `surface-container-high` | `#ede7ea` | `Color(0xFFEDE7EA)` |

### 3.2 New Color Additions Required

```dart
// From DESIGN.md - Tonal Depth Palette
static const Color secondary = Color(0xFF92348E);        // Soul
static const Color tertiary = Color(0xFF994100);         // Spark
static const Color tertiaryContainer = Color(0xFFFD7000); // Spark glow

// Surface Hierarchy (NEW)
static const Color surfaceDim = Color(0xFFFBF5F7);        // Base surface
static const Color surfaceContainerLow = Color(0xFFF5EFF1);
static const Color surfaceContainerHigh = Color(0xFFEDE7EA);
static const Color surfaceContainerHighest = Color(0xFFFFFFFF);
static const Color surfaceBright = Color(0xFFFFFFFF);

// Glassmorphism Support
static const Color glassSurface = Color(0xB3FFFFFF);      // 70% white

// Ghost Border (accessibility alternative to lines)
static const Color ghostBorder = Color(0x26B70047);        // 15% opacity primary

// Ambient Shadow (pink-tinted, max 6% opacity)
static const Color ambientShadow = Color(0x0FB70047);      // 6% of #b70047

// Text hierarchy
static const Color onPrimary = Color(0xFFFFFFFF);
static const Color onSecondary = Color(0xFFFFFFFF);
static const Color onTertiary = Color(0xFFFFFFFF);
static const Color onSurfaceVariant = Color(0xFF6B6267);
static const Color onSurfaceDim = Color(0xFF4A4548);

// Connection Chips (from DESIGN.md)
static const Color secondaryContainer = Color(0xFFFFBDF4);
static const Color onSecondaryContainer = Color(0xFF7A1C78);
```

### 3.3 Signature Gradient (REQUIRED for all primary CTAs)

```dart
// MUST be used for ALL primary button backgrounds
static const LinearGradient signatureGradient = LinearGradient(
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
  colors: [Color(0xFFFF0066), Color(0xFFFF007F)],
  // This is the "high-gloss, no border" primary button look
);

// Alternative: diagonal variant for hero sections
static const LinearGradient signatureGradientDiagonal = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFFFF0066), Color(0xFFFF007F)],
);
```

### 3.4 Typography Scale (From DESIGN.md)

```dart
// Display - Plus Jakarta Sans, 2.75rem, used for onboarding "hooks"
static const TextStyle displayMd = TextStyle(
  fontFamily: 'Plus Jakarta Sans',
  fontSize: 44,
  fontWeight: FontWeight.w700,
  letterSpacing: -0.02,  // asymmetric tracking for editorial feel
  height: 1.2,
);

// Headline - Plus Jakarta Sans, 1.5rem, for names and section titles
static const TextStyle headlineSm = TextStyle(
  fontFamily: 'Plus Jakarta Sans',
  fontSize: 24,
  fontWeight: FontWeight.w600,
  letterSpacing: -0.02,
  height: 1.3,
);

// Body - Inter, 1rem, for bios and messaging
static const TextStyle bodyLg = TextStyle(
  fontFamily: 'Inter',
  fontSize: 16,
  fontWeight: FontWeight.w400,
  height: 1.5,
);

// Label - Inter, 0.75rem, for timestamps and metadata
static const TextStyle labelMd = TextStyle(
  fontFamily: 'Inter',
  fontSize: 12,
  fontWeight: FontWeight.w400,
  letterSpacing: 0.4,
  height: 1.4,
);
```

### 3.5 Spacing Scale (From DESIGN.md)

```dart
// Use these instead of arbitrary numbers
static const double spacing1 = 4;
static const double spacing2 = 8;
static const double spacing3 = 12;
static const double spacing4 = 16;
static const double spacing5 = 20;
static const double spacing6 = 24;  // 2rem - standard between sections
static const double spacing7 = 32;
static const double spacing8 = 40;
static const double spacing9 = 48;
```

### 3.6 Border Radius Scale (From DESIGN.md)

```dart
// NO hard corners anywhere - minimum md (24px)
static const double roundSm = 12;     // 12px - for small chips
static const double roundMd = 16;     // 16px - for inputs, cards
static const double roundLg = 24;     // 24px - for large cards
static const double roundXl = 32;    // 32px - for modals, sheets
static const double roundFull = 9999; // for chips and pills only
```

### 3.7 Elevation System (NO traditional shadows)

```dart
// Instead of shadows, use surface stacking for "Natural Lift"
// Component on surface: use ghostBorder (15% opacity)
// Floating elements: use ambientShadow (6% opacity, pink-tinted)

// For floating buttons (like Match FAB):
// Use large blur (32px+) at 6% opacity with pink tint
BoxDecoration(
  color: BondyColors.glassSurface,
  borderRadius: BorderRadius.circular(32),
  boxShadow: [
    BoxShadow(
      color: BondyColors.ambientShadow,  // 6% pink-tinted
      blurRadius: 32,
      offset: Offset(0, 8),
    ),
  ],
)

// Glassmorphism for overlays:
BackdropFilter(
  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
  child: Container(
    color: BondyColors.glassSurface.withValues(alpha: 0.7),
    // content here
  ),
)
```

### 3.8 Full Updated `app_theme.dart`

```dart
import 'dart:ui';  // for ImageFilter (BackdropFilter)
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Bondy Color Palette - "The Digital Sanctuary"
/// Color is not decorative; it is emotional.
class BondyColors {
  // ── Primary (The Heartbeat) ──
  static const Color primary = Color(0xFFB70047);
  static const Color primaryDark = Color(0xFF8B0033);
  static const Color primaryLight = Color(0xFFF5EFF1);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFFFBDF4);
  static const Color onPrimaryContainer = Color(0xFF7A1C78);

  // ── Secondary (The Soul) ──
  static const Color secondary = Color(0xFF92348E);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFFFBDF4);

  // ── Tertiary (The Spark) ──
  static const Color tertiary = Color(0xFF994100);
  static const Color tertiaryContainer = Color(0xFFFD7000);
  static const Color onTertiary = Color(0xFFFFFFFF);

  // ── Surfaces (The Canvas) ──
  static const Color surface = Color(0xFFFBF5F7);
  static const Color surfaceDim = Color(0xFFFBF5F7);
  static const Color surfaceContainerLow = Color(0xFFF5EFF1);
  static const Color surfaceContainerHigh = Color(0xFFEDE7EA);
  static const Color surfaceContainerHighest = Color(0xFFFFFFFF);
  static const Color surfaceBright = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF302E30);
  static const Color onSurfaceDim = Color(0xFF4A4548);
  static const Color onSurfaceVariant = Color(0xFF6B6267);

  // ── Glassmorphism ──
  static const Color glassSurface = Color(0xB3FFFFFF);  // 70% white

  // ── Ghost Border (accessibility) ──
  static const Color ghostBorder = Color(0x26B70047);  // 15% primary

  // ── Ambient Shadow (pink-tinted, 6% max) ──
  static const Color ambientShadow = Color(0x0FB70047);

  // ── Text ──
  static const Color textPrimary = Color(0xFF302E30);
  static const Color textSecondary = Color(0xFF6B6267);
  static const Color textHint = Color(0xFF9C9099);

  // ── Utility ──
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color outlineVariant = Color(0xFFE9E2E6);
  static const Color divider = Color(0xFFE9E2E6);

  // ── Chat ──
  static const Color chatBubbleUser = Color(0xFFB70047);
  static const Color chatBubbleOther = Color(0xFFEDE7EA);

  // ── Overlay ──
  static const Color overlay = Color(0x80000000);

  // ═══════════════════════════════════════════
  // SIGNATURE GRADIENT - Required for all main CTAs
  // ═══════════════════════════════════════════
  static const LinearGradient signatureGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFFFF0066), Color(0xFFFF007F)],
  );

  static const LinearGradient signatureGradientDiagonal = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF0066), Color(0xFFFF007F)],
  );

  // ── Primary Button Style (high-gloss, no border) ──
  static BoxDecoration primaryButtonDecoration = BoxDecoration(
    gradient: signatureGradient,
    borderRadius: BorderRadius.circular(24),  // round-md = 1.5rem
  );
}

/// Spacing Scale (Design.md)
class BondySpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;  // spacing-6 = 2rem
  static const double xxxl = 32;
  static const double huge = 40;
  static const double massive = 48;
}

/// Border Radius Scale (Design.md - NO hard corners)
class BondyRadius {
  static const double sm = 12;
  static const double md = 16;   // 24px - minimum everywhere
  static const double lg = 24;
  static const double xl = 32;
  static const double full = 9999;  // chips/pills only
}

/// Typography Styles
class BondyTextStyles {
  static TextStyle displayMd(BuildContext context) => GoogleFonts.plusJakartaSans(
    fontSize: 44,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.02,
    height: 1.2,
    color: BondyColors.onSurface,
  );

  static TextStyle headlineSm(BuildContext context) => GoogleFonts.plusJakartaSans(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.02,
    height: 1.3,
    color: BondyColors.onSurface,
  );

  static TextStyle titleMd(BuildContext context) => GoogleFonts.plusJakartaSans(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.01,
    height: 1.3,
    color: BondyColors.onSurface,
  );

  static TextStyle titleSm(BuildContext context) => GoogleFonts.plusJakartaSans(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: BondyColors.onSurface,
  );

  static TextStyle bodyLg(BuildContext context) => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: BondyColors.onSurface,
  );

  static TextStyle bodyMd(BuildContext context) => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: BondyColors.onSurfaceVariant,
  );

  static TextStyle labelMd(BuildContext context) => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.4,
    color: BondyColors.onSurfaceVariant,
  );

  static TextStyle labelSm(BuildContext context) => GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.4,
    color: BondyColors.onSurfaceVariant,
  );
}

/// Bondy Theme Data
class BondyTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: BondyColors.primary,
        primary: BondyColors.primary,
        onPrimary: BondyColors.onPrimary,
        secondary: BondyColors.secondary,
        onSecondary: BondyColors.onSecondary,
        tertiary: BondyColors.tertiary,
        onTertiary: BondyColors.onTertiary,
        error: BondyColors.error,
        onError: BondyColors.onError,
        surface: BondyColors.surface,
        onSurface: BondyColors.onSurface,
        surfaceContainerHighest: BondyColors.surfaceContainerHighest,
        outlineVariant: BondyColors.outlineVariant,
      ),
      scaffoldBackgroundColor: BondyColors.surface,

      // Typography - Plus Jakarta Sans for display/headlines, Inter for body
      textTheme: GoogleFonts.plusJakartaSansTextTheme().copyWith(
        displayMedium: BondyTextStyles.displayMd(null),
        headlineSmall: BondyTextStyles.headlineSm(null),
        titleMedium: BondyTextStyles.titleMd(null),
        titleSmall: BondyTextStyles.titleSm(null),
        bodyLarge: BondyTextStyles.bodyLg(null),
        bodyMedium: BondyTextStyles.bodyMd(null),
        labelMedium: BondyTextStyles.labelMd(null),
        labelSmall: BondyTextStyles.labelSm(null),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: BondyColors.onSurface),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: BondyColors.onSurface,
        ),
      ),

      // ── PRIMARY BUTTON (Signature Gradient, no border) ──
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: BondyColors.onPrimary,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(BondyRadius.lg),  // round-md
          ),
          // NO elevation - use ambient shadow instead if needed
          elevation: 0,
          // Background handled by the widget itself using signatureGradient
        ),
      ),

      // ── SECONDARY BUTTON (Ghost style) ──
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: BondyColors.primary,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(BondyRadius.lg),
          ),
          side: BorderSide.none,  // NO border per design rules
          backgroundColor: BondyColors.surfaceContainerHighest,
        ),
      ),

      // ── TERTIARY BUTTON (Pure ghost) ──
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: BondyColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(BondyRadius.lg),
          ),
        ),
      ),

      // ── INPUT FIELDS ──
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: BondyColors.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: BondySpacing.xl,
          vertical: BondySpacing.lg,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(BondyRadius.md),
          borderSide: BorderSide.none,  // NO line per design
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(BondyRadius.md),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(BondyRadius.md),
          borderSide: BorderSide(
            color: BondyColors.primary.withValues(alpha: 0.2),  // ghost border
            width: 1,
          ),
        ),
        hintStyle: GoogleFonts.inter(
          color: BondyColors.textHint,
          fontSize: 14,
        ),
      ),

      // ── CARDS (NO border, use surface difference) ──
      cardTheme: CardThemeData(
        color: BondyColors.surfaceContainerHighest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BondyRadius.lg),
          // NO side border - boundary defined by color shift
        ),
      ),

      // ── NAVIGATION BAR (Glassmorphic) ──
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: BondyColors.glassSurface,
        selectedItemColor: BondyColors.primary,
        unselectedItemColor: BondyColors.textHint,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),

      // ── SNACKBAR ──
      snackBarTheme: SnackBarThemeData(
        backgroundColor: BondyColors.onSurface,
        contentTextStyle: GoogleFonts.inter(
          color: BondyColors.surface,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BondyRadius.md),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // ── DIALOG (Glassmorphic) ──
      dialogTheme: DialogTheme(
        backgroundColor: BondyColors.surfaceContainerHighest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BondyRadius.xl),
        ),
      ),

      // ── BOTTOM SHEET (Glassmorphic) ──
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: BondyColors.surfaceContainerHighest,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(BondyRadius.xl)),
        ),
      ),
    );
  }
}
```

---

## 4. Main Shell Screen: `lib/screens/home/main_shell_screen.dart`

### 4.1 Overview

The main_shell_screen.dart contains 4 tabs: Home, Healing, Community, Profile. Only the **Home tab** is in scope for this rebuild. However, the bottom navigation bar must be updated to match the new design system (glassmorphic, no hard shadows).

### 4.2 Required Changes

#### Bottom Navigation Bar (All Tabs)

**BEFORE:**
```dart
Container(
  height: 90,
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.08),
        blurRadius: 20,
        offset: const Offset(0, -4),
      ),
    ],
  ),
```

**AFTER (Glassmorphic):**
```dart
Container(
  height: 88,
  decoration: BoxDecoration(
    color: BondyColors.glassSurface,  // 70% white
    borderRadius: const BorderRadius.vertical(top: Radius.circular(BondyRadius.xl)),
    // NO boxShadow - use backdrop blur instead
  ),
  child: ClipRRect(
    borderRadius: const BorderRadius.vertical(top: Radius.circular(BondyRadius.xl)),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16, top: 2),
        child: Row(
          // nav items...
        ),
      ),
    ),
  ),
),
```

#### Floating Match Button

**BEFORE:**
```dart
Transform.translate(
  offset: const Offset(0, -14),
  child: Container(
    width: 56,
    height: 56,
    decoration: BoxDecoration(
      color: const Color(0xFFFF5864),
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 4),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFFFF5864).withValues(alpha: 0.3),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: const Icon(Icons.favorite, color: Colors.white, size: 26),
  ),
),
```

**AFTER (Signature Gradient + Glassmorphic):**
```dart
Transform.translate(
  offset: const Offset(0, -16),
  child: Container(
    width: 60,
    height: 60,
    decoration: BoxDecoration(
      gradient: BondyColors.signatureGradient,
      shape: BoxShape.circle,
      border: Border.all(
        color: BondyColors.glassSurface,  // white at 70%
        width: 4,
      ),
      // Ambient shadow - large blur, 6% opacity, pink tint
      boxShadow: [
        BoxShadow(
          color: BondyColors.ambientShadow,
          blurRadius: 32,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: const Icon(Icons.favorite, color: Colors.white, size: 28),
  ),
),
```

#### Home Tab Header

**BEFORE:**
```dart
Container(
  width: double.infinity,
  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
  decoration: const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFF8A65), Color(0xFFE91E63)],
    ),
  ),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bondy',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          // ...
        ],
      ),
    ],
  ),
),
```

**AFTER (Remove gradient header, use surface-based design):**
```dart
// Design.md says: "The Canvas" is surface (#fbf5f7)
// Header should blend into the surface, not use a gradient
Container(
  width: double.infinity,
  padding: const EdgeInsets.fromLTRB(
    BondySpacing.xl,
    BondySpacing.lg,
    BondySpacing.xl,
    BondySpacing.md,
  ),
  decoration: BoxDecoration(
    color: BondyColors.surface,  // blends with scaffold
  ),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bondy',
            style: BondyTextStyles.headlineSm(context).copyWith(
              color: BondyColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: BondySpacing.xs),
          Text(
            _getGreeting(),  // "Chào buổi sáng" based on time
            style: BondyTextStyles.bodyMd(context),
          ),
        ],
      ),
      // Profile avatar with glassmorphic ring
      Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: BondyColors.surfaceContainerHighest,
          shape: BoxShape.circle,
          border: Border.all(
            color: BondyColors.primary.withValues(alpha: 0.2),
            width: 2,
          ),
        ),
        child: _buildAvatarPlaceholder(),
      ),
    ],
  ),
),
```

### 4.3 Home Tab Body

**BEFORE:**
```dart
body: SafeArea(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Fixed header with gradient (REMOVE)
      // Dynamic widget list
      Expanded(
        child: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) {
            // state handling...
            return ListView.builder(
              padding: const EdgeInsets.only(top: 16, bottom: 100),
              itemCount: widgets.length,
              itemBuilder: (context, index) {
                // widget rendering...
              },
            );
          },
        ),
      ),
    ],
  ),
),
```

**AFTER (Clean surface-based design):**
```dart
body: SafeArea(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Header (now surface-based, not gradient)
      // ── Dynamic widget list ──
      Expanded(
        child: RefreshIndicator(
          color: BondyColors.primary,
          onRefresh: () => _viewModel.refreshAuthenticated(),
          child: ListView.builder(
            padding: const EdgeInsets.only(
              top: BondySpacing.lg,
              bottom: 120,  // space for FAB + nav bar
            ),
            itemCount: widgets.length,
            itemBuilder: (context, index) {
              final w = widgets[index];
              // Return widget by type...
            },
          ),
        ),
      ),
    ],
  ),
),
```

### 4.4 Floating Action Button (Bondy Coach)

**BEFORE:**
```dart
floatingActionButton: FloatingActionButton.extended(
  onPressed: () => Navigator.of(context).pushNamed('/chatbot'),
  backgroundColor: const Color(0xFFFF4D6D),
  icon: const Icon(Icons.chat_bubble, color: Colors.white, size: 20),
  label: Text(
    'Hỏi Bondy',
    style: GoogleFonts.plusJakartaSans(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    ),
  ),
),
```

**AFTER (Signature Gradient + Glassmorphic):**
```dart
floatingActionButton: Container(
  decoration: BoxDecoration(
    gradient: BondyColors.signatureGradient,
    borderRadius: BorderRadius.circular(BondyRadius.lg),
    boxShadow: [
      BoxShadow(
        color: BondyColors.ambientShadow,
        blurRadius: 32,
        offset: const Offset(0, 8),
      ),
    ],
  ),
  child: FloatingActionButton.extended(
    onPressed: () => Navigator.of(context).pushNamed('/chatbot'),
    backgroundColor: Colors.transparent,  // gradient on parent
    elevation: 0,
    icon: const Icon(Icons.chat_bubble, color: Colors.white, size: 20),
    label: Text(
      'Hỏi Bondy',
      style: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
  ),
),
```

---

## 5. Widget Refactor Specifications

### 5.1 BannerWidget

**Current State:**
- Uses hardcoded gradient colors (#FF8A65 to #E91E63)
- Has box-shadow with 25% opacity (violates "no 100% opaque shadows")
- Uses emoji icon (📋) instead of proper icon
- Has Border.all (violates "no lines rule")
- Border radius is 20px (should be 24px minimum)

**AFTER:**

```dart
// lib/widgets/home/banner_widget.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class BannerWidget extends StatelessWidget {
  final Map<String, dynamic> data;

  const BannerWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final title = data['title'] as String? ?? 'Hoàn thành khảo sát';
    final cta = data['cta'] as String? ?? 'Bắt đầu ngay';
    final action = data['action'] as String? ?? '';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(
        horizontal: BondySpacing.xl,
        vertical: BondySpacing.md,
      ),
      decoration: BoxDecoration(
        // ── Signature Gradient (REQUIRED) ──
        gradient: BondyColors.signatureGradientDiagonal,
        // ── Border radius: round-lg (24px) minimum ──
        borderRadius: BorderRadius.circular(BondyRadius.lg),
        // ── Ambient shadow: 6% opacity, pink tint, large blur ──
        boxShadow: [
          BoxShadow(
            color: BondyColors.ambientShadow,
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(BondyRadius.lg),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              if (action == 'COMPLETE_SURVEY') {
                Navigator.of(context).pushNamed('/survey/intro');
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(BondySpacing.xxl),
              child: Row(
                children: [
                  // Icon container with glass effect
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(BondyRadius.md),
                    ),
                    child: Icon(
                      Icons.assignment_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: BondySpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: BondySpacing.lg),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: BondySpacing.lg,
                            vertical: BondySpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(BondyRadius.full),
                          ),
                          child: Text(
                            cta,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: BondyColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

**Key Changes:**
| Aspect | Before | After |
|--------|--------|-------|
| Gradient | `#FF8A65` to `#E91E63` | `signatureGradientDiagonal` (#FF0066 to #FF007F) |
| Shadow | 25% opacity black | 6% opacity pink-tinted |
| Border radius | 20px | 24px (round-lg) |
| Icon | Emoji 📋 | Proper icon (Icons.assignment_rounded) |
| Border | `Border.all` (NO!) | NONE |

---

### 5.2 EmotionCheckinWidget

**Current State:**
- Uses white background with `border: Border.all(color: #FFE0E6)`
- Uses emoji for mood chips instead of proper icons
- Border radius is 20px (should be 24px)
- Has explicit shadow (violates "no shadow" rule)

**AFTER:**

```dart
// lib/widgets/home/emotion_checkin_widget.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class EmotionCheckinWidget extends StatelessWidget {
  final Map<String, dynamic> data;

  const EmotionCheckinWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final partnerName = data['partner_name'] as String? ?? 'Người ấy';
    final relationshipId = data['relationship_id'] as String? ?? '';

    // Surface-based card (no border, no shadow)
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: BondySpacing.xl,
        vertical: BondySpacing.md,
      ),
      padding: const EdgeInsets.all(BondySpacing.xxl),
      decoration: BoxDecoration(
        // ── Card uses surface-container-highest (white) on surface ──
        color: BondyColors.surfaceContainerHighest,
        // ── Border radius: round-lg (24px) minimum ──
        borderRadius: BorderRadius.circular(BondyRadius.lg),
        // NO border - color shift defines boundary
        // NO shadow - use surface stacking instead
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Icon container with tertiary glow (The Spark)
              Container(
                padding: const EdgeInsets.all(BondySpacing.md),
                decoration: BoxDecoration(
                  color: BondyColors.tertiaryContainer.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(BondyRadius.md),
                ),
                child: Icon(
                  Icons.favorite_rounded,
                  color: BondyColors.tertiary,
                  size: 24,
                ),
              ),
              const SizedBox(width: BondySpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Check-in cảm xúc hôm nay',
                      style: BondyTextStyles.titleSm(context),
                    ),
                    const SizedBox(height: BondySpacing.xs),
                    Text(
                      'Bạn đang cảm thấy thế nào với $partnerName?',
                      style: BondyTextStyles.bodyMd(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: BondySpacing.xl),
          // Mood chips row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _MoodChip(
                icon: Icons.sentiment_satisfied_rounded,
                label: 'Vui',
                mood: 'happy',
                relationshipId: relationshipId,
                color: const Color(0xFF4CAF50),
              ),
              _MoodChip(
                icon: Icons.spa_rounded,
                label: 'Bình yên',
                mood: 'peaceful',
                relationshipId: relationshipId,
                color: const Color(0xFF2196F3),
              ),
              _MoodChip(
                icon: Icons.sentiment_dissatisfied_rounded,
                label: 'Buồn',
                mood: 'sad',
                relationshipId: relationshipId,
                color: const Color(0xFF9C27B0),
              ),
              _MoodChip(
                icon: Icons.psychology_rounded,
                label: 'Lo lắng',
                mood: 'anxious',
                relationshipId: relationshipId,
                color: const Color(0xFFFF9800),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MoodChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String mood;
  final String relationshipId;
  final Color color;

  const _MoodChip({
    required this.icon,
    required this.label,
    required this.mood,
    required this.relationshipId,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // TODO: call emotion checkin API with mood + relationshipId
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã ghi nhận cảm xúc: $label'),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Column(
        children: [
          // Icon in colored container (no emoji)
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(BondyRadius.md),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: BondySpacing.sm),
          Text(
            label,
            style: BondyTextStyles.labelSm(context),
          ),
        ],
      ),
    );
  }
}
```

**Key Changes:**
| Aspect | Before | After |
|--------|--------|-------|
| Background | White with `border: Border.all` | `surfaceContainerHighest` (no border) |
| Icon | Emoji (😊, 😌, etc.) | Material icons with color |
| Border radius | 20px | 24px (round-lg) |
| Shadow | `withValues(alpha: 0.05)` | NONE - surface stacking |
| Mood container | Text emoji | Colored icon container |

---

### 5.3 MilestoneReminderWidget

**Current State:**
- Uses gradient background (#FFF3E0 to #FFE0B2)
- Has `border: Border.all(color: #FFCC80)` (violates "no lines")
- Uses emoji (🎉) instead of proper icon
- Border radius is 20px (should be 24px)

**AFTER:**

```dart
// lib/widgets/home/milestone_reminder_widget.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class MilestoneReminderWidget extends StatelessWidget {
  final Map<String, dynamic> data;

  const MilestoneReminderWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final title = data['title'] as String? ?? 'Kỷ niệm sắp tới';
    final date = data['date'] as String? ?? '';
    final daysLeft = data['days_left'] as int? ?? 0;

    final daysText = daysLeft == 0
        ? 'Hôm nay!'
        : daysLeft == 1
            ? 'Còn 1 ngày'
            : 'Còn $daysLeft ngày';

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: BondySpacing.xl,
        vertical: BondySpacing.md,
      ),
      padding: const EdgeInsets.all(BondySpacing.xxl),
      decoration: BoxDecoration(
        // Tertiary gradient (The Spark)
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            BondyColors.tertiaryContainer.withValues(alpha: 0.3),
            BondyColors.tertiary.withValues(alpha: 0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(BondyRadius.lg),
        // NO border - use color shift
      ),
      child: Row(
        children: [
          // Icon container with tertiary glow
          Container(
            padding: const EdgeInsets.all(BondySpacing.md),
            decoration: BoxDecoration(
              color: BondyColors.tertiaryContainer.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.celebration_rounded,
              color: BondyColors.tertiary,
              size: 28,
            ),
          ),
          const SizedBox(width: BondySpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: BondyTextStyles.titleSm(context),
                ),
                if (date.isNotEmpty) ...[
                  const SizedBox(height: BondySpacing.xs),
                  Text(
                    date,
                    style: BondyTextStyles.labelMd(context),
                  ),
                ],
              ],
            ),
          ),
          // Badge with tertiary color
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: BondySpacing.lg,
              vertical: BondySpacing.sm,
            ),
            decoration: BoxDecoration(
              color: BondyColors.tertiary,
              borderRadius: BorderRadius.circular(BondyRadius.full),
            ),
            child: Text(
              daysText,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: BondyColors.onTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

**Key Changes:**
| Aspect | Before | After |
|--------|--------|-------|
| Background | Hardcoded warm gradient | Tertiary-based gradient |
| Border | `Border.all(color: #FFCC80)` | NONE |
| Icon | Emoji 🎉 | `Icons.celebration_rounded` |
| Border radius | 20px | 24px (round-lg) |

---

### 5.4 DiscoveryCardWidget

**Current State:**
- Has explicit `border: Border.all(color: #E5E7EB)` (violates "no lines")
- Uses emoji for avatar placeholder
- Border radius is 16px (should be 24px)
- Has shadow (violates "no shadow" rule)
- Uses hardcoded colors for text

**AFTER:**

```dart
// lib/widgets/home/discovery_card_widget.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class DiscoveryCardWidget extends StatelessWidget {
  final Map<String, dynamic> data;

  const DiscoveryCardWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final profiles = (data['profiles'] as List<dynamic>?) ?? [];

    return Container(
      margin: const EdgeInsets.only(
        left: BondySpacing.xl,
        right: BondySpacing.xl,
        top: BondySpacing.md,
        bottom: BondySpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: BondySpacing.lg),
            child: Row(
              children: [
                Text(
                  'Gợi ý kết nối cho bạn',
                  style: BondyTextStyles.titleMd(context),
                ),
                const SizedBox(width: BondySpacing.sm),
                Icon(
                  Icons.auto_awesome,
                  color: BondyColors.tertiary,
                  size: 18,
                ),
              ],
            ),
          ),
          if (profiles.isEmpty)
            _buildEmptyState()
          else
            SizedBox(
              height: 180,  // taller for better UX
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: profiles.length,
                separatorBuilder: (_, index) => const SizedBox(width: BondySpacing.lg),
                itemBuilder: (context, index) {
                  final profile = profiles[index] as Map<String, dynamic>;
                  return _ProfileCard(profile: profile);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(BondySpacing.xxl),
      decoration: BoxDecoration(
        color: BondyColors.surfaceContainerLow,  // lower surface
        borderRadius: BorderRadius.circular(BondyRadius.lg),
        // NO border
      ),
      child: Column(
        children: [
          Icon(
            Icons.person_search_rounded,
            color: BondyColors.textHint,
            size: 48,
          ),
          const SizedBox(height: BondySpacing.md),
          Text(
            'Thêm sở thích vào profile để Bondy gợi ý tốt hơn',
            style: BondyTextStyles.bodyMd(context),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final Map<String, dynamic> profile;

  const _ProfileCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final name = profile['name'] as String? ?? 'Ẩn danh';
    final city = profile['city'] as String? ?? '';
    final interests = (profile['common_interests'] as List<dynamic>?) ?? [];

    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed('/discover'),
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(BondySpacing.lg),
        decoration: BoxDecoration(
          // Card sits on surface-container-highest (white)
          color: BondyColors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(BondyRadius.lg),
          // NO border - use ghost border if accessibility requires
          // NO shadow - surface difference provides depth
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar with primary tint
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: BondyColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_rounded,
                color: BondyColors.onPrimaryContainer,
                size: 28,
              ),
            ),
            const SizedBox(height: BondySpacing.md),
            Text(
              name,
              style: BondyTextStyles.titleSm(context),
              overflow: TextOverflow.ellipsis,
            ),
            if (city.isNotEmpty) ...[
              const SizedBox(height: BondySpacing.xs),
              Text(
                city,
                style: BondyTextStyles.labelMd(context),
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (interests.isNotEmpty) ...[
              const SizedBox(height: BondySpacing.sm),
              // Connection chip style
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: interests.take(2).map((interest) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: BondySpacing.sm,
                      vertical: BondySpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: BondyColors.secondaryContainer,
                      borderRadius: BorderRadius.circular(BondyRadius.full),
                    ),
                    child: Text(
                      interest.toString(),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: BondyColors.onSecondaryContainer,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

**Key Changes:**
| Aspect | Before | After |
|--------|--------|-------|
| Border | `Border.all(color: #E5E7EB)` | NONE |
| Shadow | `withValues(alpha: 0.04)` | NONE |
| Avatar | Emoji 👤 | Icon on primaryContainer |
| Border radius | 16px | 24px (round-lg) |
| Interests | Plain text | Connection chips (secondaryContainer) |
| Empty state | Emoji + text | Icon + text |

---

### 5.5 SuggestionCardWidget

**Current State:**
- Uses multi-color gradient (pink to purple to lavender)
- Border radius is 20px (should be 24px)
- Has 30% opacity shadow (violates "6% max" rule)
- Uses emoji (🧘‍♀️) instead of proper icon

**AFTER:**

```dart
// lib/widgets/home/suggestion_card_widget.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class SuggestionCardWidget extends StatelessWidget {
  final Map<String, dynamic> data;

  const SuggestionCardWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final title = data['title'] as String? ?? 'Dành riêng cho bạn hôm nay';
    final content = data['content'] as String? ?? '';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(
        horizontal: BondySpacing.xl,
        vertical: BondySpacing.md,
      ),
      decoration: BoxDecoration(
        // Signature Gradient (REQUIRED for hero elements)
        gradient: BondyColors.signatureGradientDiagonal,
        borderRadius: BorderRadius.circular(BondyRadius.lg),
        // Ambient shadow: 6% opacity, large blur
        boxShadow: [
          BoxShadow(
            color: BondyColors.ambientShadow,
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(BondyRadius.lg),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Navigator.of(context).pushNamed('/content'),
            child: Padding(
              padding: const EdgeInsets.all(BondySpacing.xxl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge container
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: BondySpacing.md,
                      vertical: BondySpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(BondyRadius.full),
                    ),
                    child: Text(
                      'DAILY INSPIRATION',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: BondySpacing.lg),
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.2,
                      letterSpacing: -0.02,
                    ),
                  ),
                  if (content.isNotEmpty) ...[
                    const SizedBox(height: BondySpacing.sm),
                    Text(
                      content,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.85),
                        height: 1.4,
                      ),
                    ),
                  ],
                  const SizedBox(height: BondySpacing.xl),
                  // Icon (no emoji)
                  Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(BondyRadius.md),
                        ),
                        child: Icon(
                          Icons.self_improvement_rounded,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                      const Spacer(),
                      // CTA Button with signature gradient
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: BondySpacing.lg,
                          vertical: BondySpacing.md,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(BondyRadius.full),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Bắt đầu',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: BondyColors.primary,
                              ),
                            ),
                            const SizedBox(width: BondySpacing.sm),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: BondyColors.primary,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

**Key Changes:**
| Aspect | Before | After |
|--------|--------|-------|
| Gradient | Multi-color pink-purple-lavender | Signature Gradient (#FF0066 to #FF007F) |
| Shadow | 30% opacity | 6% opacity (ambientShadow) |
| Icon | Emoji 🧘‍♀️ | `Icons.self_improvement_rounded` |
| Border radius | 20px | 24px (round-lg) |

---

## 6. New Widget: RelationshipStrengthCard

### 6.1 Overview

This is a **NEW** widget not currently in the codebase. It should be added to display relationship health/strength metrics based on emotional check-in data.

**Design Requirements:**
- Glassmorphic card with backdrop blur
- Shows relationship "strength score" as a visual indicator
- Uses tertiary color (The Spark) for energy/activity
- Connection chips for shared activities

### 6.2 Specification

```dart
// lib/widgets/home/relationship_strength_card.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class RelationshipStrengthCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const RelationshipStrengthCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final partnerName = data['partner_name'] as String? ?? 'Người ấy';
    final strengthScore = data['strength_score'] as int? ?? 0;  // 0-100
    final commonInterests = (data['common_interests'] as List<dynamic>?) ?? [];
    final lastCheckin = data['last_checkin'] as String? ?? null;
    final streakDays = data['streak_days'] as int? ?? 0;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: BondySpacing.xl,
        vertical: BondySpacing.md,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(BondyRadius.lg),
        child: BackdropFilter(
          // Glassmorphism: 16px blur
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.all(BondySpacing.xxl),
            decoration: BoxDecoration(
              // Glass effect: semi-transparent white
              color: BondyColors.glassSurface,
              borderRadius: BorderRadius.circular(BondyRadius.lg),
              // Ghost border for accessibility
              border: Border.all(
                color: BondyColors.ghostBorder,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    // Heart icon with healing pulse animation placeholder
                    Container(
                      padding: const EdgeInsets.all(BondySpacing.md),
                      decoration: BoxDecoration(
                        color: BondyColors.tertiaryContainer.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.favorite_rounded,
                        color: BondyColors.tertiary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: BondySpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sức mạnh mối quan hệ',
                            style: BondyTextStyles.titleSm(context),
                          ),
                          const SizedBox(height: BondySpacing.xs),
                          Text(
                            'Cùng $partnerName xây dựng tương lai',
                            style: BondyTextStyles.labelMd(context),
                          ),
                        ],
                      ),
                    ),
                    // Streak badge
                    if (streakDays > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: BondySpacing.md,
                          vertical: BondySpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: BondyColors.tertiary,
                          borderRadius: BorderRadius.circular(BondyRadius.full),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.local_fire_department_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$streakDays ngày',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: BondySpacing.xl),

                // Strength meter (visual progress indicator)
                _buildStrengthMeter(context, strengthScore),

                const SizedBox(height: BondySpacing.xl),

                // Common interests (Connection Chips)
                if (commonInterests.isNotEmpty) ...[
                  Text(
                    'Sở thích chung',
                    style: BondyTextStyles.labelMd(context),
                  ),
                  const SizedBox(height: BondySpacing.sm),
                  Wrap(
                    spacing: BondySpacing.sm,
                    runSpacing: BondySpacing.sm,
                    children: commonInterests.take(4).map((interest) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: BondySpacing.md,
                          vertical: BondySpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: BondyColors.secondaryContainer,
                          borderRadius: BorderRadius.circular(BondyRadius.full),
                        ),
                        child: Text(
                          interest.toString(),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: BondyColors.onSecondaryContainer,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],

                // Last check-in info
                if (lastCheckin != null) ...[
                  const SizedBox(height: BondySpacing.lg),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 14,
                        color: BondyColors.textHint,
                      ),
                      const SizedBox(width: BondySpacing.xs),
                      Text(
                        'Check-in cuối: $lastCheckin',
                        style: BondyTextStyles.labelSm(context),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStrengthMeter(BuildContext context, int score) {
    // Color based on score: green (high), yellow (medium), red (low)
    Color meterColor;
    if (score >= 70) {
      meterColor = const Color(0xFF4CAF50);
    } else if (score >= 40) {
      meterColor = const Color(0xFFFF9800);
    } else {
      meterColor = const Color(0xFFE53935);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Điểm sức mạnh',
              style: BondyTextStyles.labelMd(context),
            ),
            Text(
              '$score%',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: meterColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: BondySpacing.sm),
        // Progress bar
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: BondyColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(BondyRadius.full),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: score / 100,
            child: Container(
              decoration: BoxDecoration(
                color: meterColor,
                borderRadius: BorderRadius.circular(BondyRadius.full),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
```

### 6.3 Integration

Add to `main_shell_screen.dart` home tab widget switch:

```dart
// In _HomeTabState widget builder, add new case:
'SUGGESTION_CARD' => SuggestionCardWidget(data: w.data),
'RELATIONSHIP_STRENGTH' => RelationshipStrengthCard(data: w.data),
```

---

## 7. Implementation Checklist Summary

| # | Task | File | Status |
|---|------|------|--------|
| 1 | Update color palette | `lib/theme/app_theme.dart` | PENDING |
| 2 | Add spacing/radius constants | `lib/theme/app_theme.dart` | PENDING |
| 3 | Add typography styles | `lib/theme/app_theme.dart` | PENDING |
| 4 | Add signature gradient | `lib/theme/app_theme.dart` | PENDING |
| 5 | Update glassmorphic nav bar | `lib/screens/home/main_shell_screen.dart` | PENDING |
| 6 | Update Match FAB style | `lib/screens/home/main_shell_screen.dart` | PENDING |
| 7 | Update Bondy Coach FAB | `lib/screens/home/main_shell_screen.dart` | PENDING |
| 8 | Remove gradient header (Home tab) | `lib/screens/home/main_shell_screen.dart` | PENDING |
| 9 | Refactor BannerWidget | `lib/widgets/home/banner_widget.dart` | PENDING |
| 10 | Refactor EmotionCheckinWidget | `lib/widgets/home/emotion_checkin_widget.dart` | PENDING |
| 11 | Refactor MilestoneReminderWidget | `lib/widgets/home/milestone_reminder_widget.dart` | PENDING |
| 12 | Refactor DiscoveryCardWidget | `lib/widgets/home/discovery_card_widget.dart` | PENDING |
| 13 | Refactor SuggestionCardWidget | `lib/widgets/home/suggestion_card_widget.dart` | PENDING |
| 14 | Create RelationshipStrengthCard | `lib/widgets/home/relationship_strength_card.dart` | PENDING |

---

## 8. API Integration Notes

### Home Content API

The home screen consumes widgets from `HomeService` via `HomeViewModel`. The widget types are:

| Widget Type | Expected Data Fields |
|-------------|---------------------|
| `BANNER` | `title`, `cta`, `action` |
| `EMOTION_CHECKIN` | `partner_name`, `relationship_id` |
| `MILESTONE_REMINDER` | `title`, `date`, `days_left` |
| `DISCOVERY_CARD` | `profiles` (array with `name`, `city`, `common_interests`) |
| `SUGGESTION_CARD` | `title`, `content` |
| `RELATIONSHIP_STRENGTH` (NEW) | `partner_name`, `strength_score`, `common_interests`, `last_checkin`, `streak_days` |

---

## 9. Critical Design Rules Summary

| Rule | Implementation |
|------|----------------|
| **NO 1px solid borders** | Use `surface-container-highest` on `surface` background |
| **NO pure black text** | Use `on-surface` (#302e30) |
| **NO 100% opaque shadows** | Max 6% opacity with pink tint |
| **NO hard corners** | Minimum `round-md` (16px), prefer `round-lg` (24px) |
| **Signature Gradient** | #FF0066 to #FF007F for all primary CTAs |
| **Glassmorphism** | 12-20px blur, 70% white for overlays |
| **Intentional Asymmetry** | Overlap typography onto images with negative margins |
| **Tonal Depth** | Replace dividers with soft color transitions |
| **Liquid Motion** | `ease-in-out` cubic-bezier (0.4, 0, 0.2, 1) for transitions |

---

*Document generated: 2026-05-14*
*Design System: "The Digital Sanctuary"*
*Implementation Owner: Flutter Development Team*