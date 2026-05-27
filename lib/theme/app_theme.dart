import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BondyColors {
  // Stitch design updated to Tailwind Rose/Red gradient
  static const Color primary = Color(0xFFF87171); // From Tailwind text-red-400 equivalent
  static const Color primaryDark = Color(0xFFE11D48); // Deeper red for dark areas
  static const Color primaryLight = Color(0xFFFFF1F2); // Rose-50 for faint backgrounds
  static const Color secondary = Color(0xFFFDA4AF); // Gradient To color (rose-300)
  static const Color background = Color(0xFFFFF1F2); // Rose-50
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF2D0A15);
  static const Color textSecondary = Color(0xFF8A6A75);
  static const Color textHint = Color(0xFFB89AA5);
  static const Color divider = Color(0xFFE5E7EB);
  static const Color error = Color(0xFFEF4444);
  static const Color cardBorder = Color(0xFFE5E7EB);
  static const Color selectedCard = Color(0xFFFFF1F2);
  static const Color selectedCardBorder = Color(0xFFF87171);
  static const Color chatBubbleUser = Color(0xFFF87171);
  static const Color chatBubbleOther = Color(0xFFF3F4F6);
  static const Color overlay = Color(0x80000000);

  // Common UI Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [primary, secondary],
  );
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
      textTheme: GoogleFonts.plusJakartaSansTextTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: BondyColors.textPrimary),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: BondyColors.textPrimary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: BondyColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: BondyColors.textPrimary,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          side: const BorderSide(color: BondyColors.divider),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: BondyColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: BondyColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: BondyColors.primary, width: 2),
        ),
        hintStyle: GoogleFonts.plusJakartaSans(
          color: BondyColors.textHint,
          fontSize: 14,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: BondyColors.cardBorder),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
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
    );
  }
}
