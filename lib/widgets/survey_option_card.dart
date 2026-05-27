import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class SurveyOptionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? emoji;
  final bool isSelected;
  final VoidCallback onTap;

  const SurveyOptionCard({
    super.key,
    required this.title,
    this.subtitle,
    this.emoji,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? BondyColors.selectedCard : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? BondyColors.selectedCardBorder
                : BondyColors.cardBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            if (emoji != null) ...[
              Text(emoji!, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 16),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: BondyColors.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: BondyColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: BondyColors.primary,
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
                  border: Border.all(color: BondyColors.divider, width: 2),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
