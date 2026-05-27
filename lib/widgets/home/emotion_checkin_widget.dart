// lib/widgets/home/emotion_checkin_widget.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EmotionCheckinWidget extends StatelessWidget {
  final Map<String, dynamic> data;

  const EmotionCheckinWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final partnerName = data['partner_name'] as String? ?? 'Người ấy';
    final relationshipId = data['relationship_id'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xfff5eff1),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xffffffff),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFb70047).withValues(alpha: 0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE0E6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.favorite,
                    color: Color(0xFFb70047),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Check-in cảm xúc hôm nay',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Bạn đang cảm thấy thế nào với $partnerName?',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.5),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _MoodChip(icon: Icons.sentiment_satisfied, label: 'Vui', mood: 'happy', relationshipId: relationshipId),
                _MoodChip(icon: Icons.spa, label: 'Bình yên', mood: 'peaceful', relationshipId: relationshipId),
                _MoodChip(icon: Icons.sentiment_dissatisfied, label: 'Buồn', mood: 'sad', relationshipId: relationshipId),
                _MoodChip(icon: Icons.psychology, label: 'Lo lắng', mood: 'anxious', relationshipId: relationshipId),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MoodChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String mood;
  final String relationshipId;

  const _MoodChip({
    required this.icon,
    required this.label,
    required this.mood,
    required this.relationshipId,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã ghi nhận cảm xúc: $label'),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFE0E6).withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: const Color(0xFFb70047),
              size: 28,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}
