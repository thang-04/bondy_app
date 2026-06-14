import 'package:flutter/material.dart';
import '../widgets/common/bondy_widgets.dart';
import 'app_theme.dart';

/// @deprecated Use [BondyColors] (from `theme/app_theme.dart`) and
/// [bondyText] (from `widgets/common/bondy_widgets.dart`) instead.
/// Kept temporarily to avoid breaking older imports. Will be removed.
@Deprecated(
  'Use BondyColors and bondyText from app_theme.dart / bondy_widgets.dart',
)
class BondyDesignTokens {
  static const Color warmBackground = BondyColors.background;
  static const Color creamBackground = BondyColors.backgroundCream;
  static const Color surface = BondyColors.surface;
  static const Color textMain = BondyColors.textPrimary;
  static const Color textMuted = BondyColors.textSecondary;
  static const Color coral = BondyColors.coral;
  static const Color pink = BondyColors.pink;

  static const LinearGradient warmGradient = BondyColors.primaryGradient;
  static const LinearGradient brandGradient = BondyColors.signatureGradient;

  static const double radiusMd = 20;
  static const double radiusLg = 24;

  static TextStyle displayText({
    double size = 24,
    FontWeight weight = FontWeight.w800,
    Color color = textMain,
  }) => bondyText(size: size, weight: weight, color: color);

  static TextStyle bodyText({
    double size = 14,
    FontWeight weight = FontWeight.w500,
    Color color = textMuted,
  }) => bondyText(size: size, weight: weight, color: color);
}
