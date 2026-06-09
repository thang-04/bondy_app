import 'package:flutter/material.dart';

import 'common/bondy_widgets.dart';

/// Primary action button used across the app.
///
/// The filled variant delegates to [BondyPrimaryButton] (the gradient CTA
/// pulled up from the Healing design system) so every CTA in the app shares
/// the same height, radius, gradient and glow. The outlined and loading
/// variants keep their classic Material treatment.
class BondyButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isOutlined;
  final bool isLoading;
  final IconData? icon;
  final double borderRadius;

  const BondyButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isOutlined = false,
    this.isLoading = false,
    this.icon,
    this.borderRadius = 30,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius)),
        ),
        child: const SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    }
    if (isOutlined) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius)),
        ),
        child: icon == null
            ? Text(text)
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 20),
                  const SizedBox(width: 8),
                  Text(text),
                ],
              ),
      );
    }
    return BondyPrimaryButton(
      label: text,
      icon: icon ?? Icons.arrow_forward,
      onTap: onPressed,
      borderRadius: borderRadius,
    );
  }
}
