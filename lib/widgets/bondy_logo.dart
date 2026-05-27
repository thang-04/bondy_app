import 'package:flutter/material.dart';

/// Bondy heart-shaped logo widget.
/// Renders the new app logo image.
class BondyLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final bool showTagline;

  const BondyLogo({
    super.key,
    this.size = 200, // Increased default size
    this.showText = true, // The new logo image already has text, but kept for compatibility if needed.
    this.showTagline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Using the new image logo
        Image.asset(
          'assets/images/logo.png',
          width: size,
          height: size,
          fit: BoxFit.contain,
        ),
      ],
    );
  }
}

/// Mini version of Bondy logo for headers and navigation
class BondyLogoMini extends StatelessWidget {
  final double size;

  const BondyLogoMini({super.key, this.size = 64});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/logo.png',
          width: size,
          height: size,
          fit: BoxFit.contain,
        ),
      ],
    );
  }
}
