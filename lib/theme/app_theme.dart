import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../screens/healing/healing_stitch_style.dart';

/// Canonical app-wide color palette. The values are inherited from the
/// Healing (Stitch) design — [HealingStitchColors] is kept as the raw
/// source-of-truth; this class exposes both semantic names (primary,
/// background…) and direct accent names (coral, pink…) so new code can
/// pick whichever fits.
class BondyColors {
  // Semantic
  static const Color primary = HealingStitchColors.coral;
  static const Color primaryDark = HealingStitchColors.pink;
  static const Color primaryLight = HealingStitchColors.paleCoral;
  static const Color secondary = HealingStitchColors.coralLight;
  static const Color background = HealingStitchColors.warmBackground;
  static const Color backgroundCream = HealingStitchColors.creamBackground;
  static const Color surface = HealingStitchColors.surface;
  static const Color textPrimary = HealingStitchColors.textMain;
  static const Color textSecondary = HealingStitchColors.textMuted;
  static const Color textHint = HealingStitchColors.textSoft;
  static const Color divider = HealingStitchColors.border;
  static const Color error = HealingStitchColors.pink;
  static const Color cardBorder = HealingStitchColors.border;
  static const Color selectedCard = HealingStitchColors.paleCoral;
  static const Color selectedCardBorder = HealingStitchColors.coralLight;
  // Chat bubbles now follow the coral palette instead of arbitrary hex values.
  static const Color chatBubbleUser = HealingStitchColors.coralLight;
  static const Color chatBubbleOther = HealingStitchColors.paleCoral;
  static const Color overlay = Color(0x80000000);
  static const Color surfaceContainerLow = HealingStitchColors.creamBackground;
  static const Color ghostBorder = Color(0xFFF2D7DF);

  // Direct accents (mirror the Healing palette).
  static const Color coral = HealingStitchColors.coral;
  static const Color coralLight = HealingStitchColors.coralLight;
  static const Color orange = HealingStitchColors.orange;
  static const Color pink = HealingStitchColors.pink;
  static const Color purple = HealingStitchColors.purple;
  static const Color paleCoral = HealingStitchColors.paleCoral;

  // Common UI Gradient
  static const LinearGradient primaryGradient = HealingStitchColors.warmGradient;
  static const LinearGradient signatureGradient = HealingStitchColors.brandGradient;
}

class BondyRadius {
  static const double sm = 12;
  static const double md = 20;
  static const double lg = 24;
  static const double xl = 32;
  static const double full = 999;
}

class BondyTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: BondyColors.primary,
        primary: BondyColors.primary,
        surface: BondyColors.surface,
        onPrimary: Colors.white,
      ),
      scaffoldBackgroundColor: BondyColors.background,
      fontFamily: GoogleFonts.manrope().fontFamily,
      textTheme: GoogleFonts.manropeTextTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: BondyColors.textPrimary),
        titleTextStyle: GoogleFonts.manrope(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: BondyColors.textPrimary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: BondyColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.manrope(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: BondyColors.textPrimary,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          side: const BorderSide(color: BondyColors.divider),
          textStyle: GoogleFonts.manrope(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: BondyColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: BondyColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: BondyColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: BondyColors.primary, width: 1.5),
        ),
        hintStyle: GoogleFonts.manrope(
          color: BondyColors.textHint,
          fontSize: 14,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: BondyColors.cardBorder),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: const Color(0xFF2D2A26),
        contentTextStyle: GoogleFonts.manrope(color: Colors.white),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: BondyColors.surface,
        selectedItemColor: BondyColors.primary,
        unselectedItemColor: BondyColors.textHint,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.manrope(
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: GoogleFonts.manrope(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
