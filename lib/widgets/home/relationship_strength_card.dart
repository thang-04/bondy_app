import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';

class RelationshipStrengthCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const RelationshipStrengthCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final partnerName = data['partner_name']?.toString().trim();
    final displayName = partnerName?.isNotEmpty == true ? partnerName! : 'bạn';
    final score = _intValue(data['strength_score']).clamp(0, 100);
    final streakDays = _intValue(data['streak_days']);
    final interests = _stringList(data['common_interests']).take(3).toList();
    final lastCheckin = data['last_checkin']?.toString().trim();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: BondyColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: BondyColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sức mạnh mối quan hệ',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: BondyColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Cùng $displayName xây dựng tương lai',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: BondyColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _ScoreBadge(score: score),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: score / 100,
              minHeight: 8,
              backgroundColor: BondyColors.primaryLight,
              valueColor: const AlwaysStoppedAnimation<Color>(
                BondyColors.primary,
              ),
            ),
          ),
          if (streakDays > 0) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(
                  Icons.local_fire_department_rounded,
                  size: 18,
                  color: BondyColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  '$streakDays ngày',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: BondyColors.textPrimary,
                  ),
                ),
              ],
            ),
          ],
          if (interests.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: interests
                  .map((interest) => _InterestChip(label: interest))
                  .toList(),
            ),
          ],
          if (lastCheckin != null && lastCheckin.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              'Check-in cuối: $lastCheckin',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: BondyColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  int _intValue(Object? value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  List<String> _stringList(Object? value) {
    if (value is! List) return const [];
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }
}

class _ScoreBadge extends StatelessWidget {
  final int score;

  const _ScoreBadge({required this.score});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 62,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: BondyColors.primaryLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$score%',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: BondyColors.primaryDark,
        ),
      ),
    );
  }
}

class _InterestChip extends StatelessWidget {
  final String label;

  const _InterestChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: BondyColors.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: BondyColors.cardBorder),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: BondyColors.textPrimary,
        ),
      ),
    );
  }
}
