// lib/widgets/home/emotion_checkin_widget.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/relationship_service.dart';
import '../common/bondy_feedback.dart';

class EmotionCheckinWidget extends StatelessWidget {
  final Map<String, dynamic> data;

  const EmotionCheckinWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final partnerName = data['partner_name'] as String? ?? 'Người ấy';

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
          Row(
            children: [
              const Icon(Icons.favorite, color: Color(0xFFb70047), size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Check-in với $partnerName',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Chia sẻ cảm xúc hôm nay để hai bạn thấu hiểu nhau hơn.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () =>
                  Navigator.of(context).pushNamed('/relationship/checkin'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFb70047),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('Bắt đầu check-in'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Quick mood chip used when inline check-in is enabled.
class HomeQuickMoodChip extends StatelessWidget {
  final String label;
  final String mood;

  const HomeQuickMoodChip({super.key, required this.label, required this.mood});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        try {
          await RelationshipService().submitCheckin(mood: mood);
          if (!context.mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Đã ghi nhận: $label')));
        } catch (e) {
          if (!context.mounted) return;
          BondyFeedback.showError(context, e);
        }
      },
      child: Column(
        children: [
          Icon(Icons.circle, size: 8, color: Colors.grey.shade400),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}
