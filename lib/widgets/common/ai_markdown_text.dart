import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';

class AiMarkdownText extends StatelessWidget {
  final String data;
  final TextStyle? style;
  final Color? color;
  final double? fontSize;
  final FontWeight? fontWeight;
  final double? height;
  final bool selectable;

  const AiMarkdownText({
    super.key,
    required this.data,
    this.style,
    this.color,
    this.fontSize,
    this.fontWeight,
    this.height,
    this.selectable = false,
  });

  @override
  Widget build(BuildContext context) {
    final baseStyle = _baseStyle();
    final headingStyle = baseStyle.copyWith(
      fontSize: (baseStyle.fontSize ?? 14) + 1,
      fontWeight: FontWeight.w800,
      height: 1.28,
    );
    final compactHeadingStyle = baseStyle.copyWith(
      fontWeight: FontWeight.w800,
      height: 1.32,
    );

    return MarkdownBody(
      data: data,
      selectable: selectable,
      softLineBreak: true,
      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
        p: baseStyle,
        pPadding: EdgeInsets.zero,
        a: baseStyle.copyWith(
          color: BondyColors.primary,
          decoration: TextDecoration.underline,
        ),
        strong: baseStyle.copyWith(fontWeight: FontWeight.w800),
        em: baseStyle.copyWith(fontStyle: FontStyle.italic),
        h1: headingStyle,
        h2: headingStyle,
        h3: compactHeadingStyle,
        h4: compactHeadingStyle,
        h5: compactHeadingStyle,
        h6: compactHeadingStyle,
        h1Padding: EdgeInsets.zero,
        h2Padding: EdgeInsets.zero,
        h3Padding: EdgeInsets.zero,
        h4Padding: EdgeInsets.zero,
        h5Padding: EdgeInsets.zero,
        h6Padding: EdgeInsets.zero,
        listBullet: baseStyle,
        listIndent: 18,
        listBulletPadding: const EdgeInsets.only(right: 4),
        blockSpacing: 6,
        code: baseStyle.copyWith(
          fontFamily: 'monospace',
          fontSize: (baseStyle.fontSize ?? 14) * 0.92,
          backgroundColor: BondyColors.primary.withValues(alpha: 0.08),
        ),
        codeblockPadding: const EdgeInsets.all(8),
        codeblockDecoration: BoxDecoration(
          color: BondyColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        blockquote: baseStyle.copyWith(color: BondyColors.textSecondary),
        blockquotePadding: const EdgeInsets.fromLTRB(10, 6, 8, 6),
        blockquoteDecoration: BoxDecoration(
          color: BondyColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: const Border(
            left: BorderSide(color: BondyColors.primary, width: 3),
          ),
        ),
      ),
    );
  }

  TextStyle _baseStyle() {
    final fallback = GoogleFonts.plusJakartaSans(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: BondyColors.textPrimary,
      height: 1.45,
    );
    final merged = fallback.merge(style);
    return merged.copyWith(
      color: color ?? merged.color ?? BondyColors.textPrimary,
      fontSize: fontSize ?? merged.fontSize ?? 14,
      fontWeight: fontWeight ?? merged.fontWeight ?? FontWeight.w500,
      height: height ?? merged.height ?? 1.45,
    );
  }
}
