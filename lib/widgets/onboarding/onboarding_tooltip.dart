import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingTooltip extends StatelessWidget {
  final String title;
  final String content;
  final String icon;
  final int currentStep;
  final int totalSteps;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const OnboardingTooltip({
    super.key,
    required this.title,
    required this.content,
    required this.icon,
    required this.currentStep,
    required this.totalSteps,
    required this.onNext,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A24),
        border: Border.all(color: const Color(0xFFFF6B6B).withOpacity(0.3)),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'BƯỚC $currentStep/$totalSteps',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFFF9F80),
                  letterSpacing: 1.0,
                ),
              ),
              Text(icon, style: const TextStyle(fontSize: 18)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              height: 1.4,
              color: const Color(0xFFD0D0D6),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Chấm chỉ số bước (indicators)
              Row(
                children: List.generate(
                  totalSteps,
                  (index) => Container(
                    margin: const EdgeInsets.only(right: 6),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: index + 1 == currentStep
                          ? const Color(0xFFFF6B6B)
                          : const Color(0xFF4A4A5A),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              // Các nút hành động
              Row(
                children: [
                  TextButton(
                    onPressed: onSkip,
                    child: Text(
                      'Bỏ qua',
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFFA0A0A0),
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      backgroundColor: const Color(0xFFFF6B6B),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    onPressed: onNext,
                    child: Text(
                      currentStep == totalSteps ? 'Xong' : 'Tiếp tục',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
