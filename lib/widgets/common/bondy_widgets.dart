import 'package:flutter/material.dart';

import '../../screens/healing/healing_stitch_style.dart';

/// Canonical app-wide widgets. These were originally defined in the Healing
/// module ([HealingStitchColors] etc.) but the Healing aesthetic IS the
/// Bondy design language — these aliases promote the widgets to first-class
/// app primitives so other modules can adopt them without importing through
/// the healing module path.
///
/// New code should reference [BondyTopBar], [BondyPrimaryButton], etc.
/// The original `Healing*` names remain as backward-compat aliases.
typedef BondyIconButton = HealingIconButton;
typedef BondyTopBar = HealingTopBar;
typedef BondyPrimaryButton = HealingGradientButton;
typedef BondyWeekTabs = HealingWeekTabs;
typedef BondyRouteBottomNav = HealingRouteBottomNav;

/// Canonical text style helper. Aliases [healingText] under the Bondy name.
TextStyle bondyText({
  double size = 14,
  FontWeight weight = FontWeight.w500,
  Color color = HealingStitchColors.textMain,
  double? height,
}) => healingText(size: size, weight: weight, color: color, height: height);

/// Canonical soft shadow used by cards and surfaces.
BoxShadow bondySoftShadow([double opacity = 0.05]) =>
    healingSoftShadow(opacity);

/// Canonical glow shadow used by active/CTA elements.
BoxShadow bondyGlowShadow([Color color = HealingStitchColors.coral]) =>
    healingGlowShadow(color);
