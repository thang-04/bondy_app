// lib/widgets/home/milestone_reminder_widget.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFCC80)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFF9800).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Text('🎉', style: TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 4),
                if (date.isNotEmpty)
                  Text(
                    date,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFF9800),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              daysText,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
