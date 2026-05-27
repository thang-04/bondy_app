import 'package:flutter/material.dart';

import '../../../models/healing/healing_models.dart';
import '../healing_stitch_style.dart';

class TodayCheckinSummaryCard extends StatelessWidget {
  final HealingLogSnapshot? todayMood;
  final VoidCallback onViewResult;

  const TodayCheckinSummaryCard({
    super.key,
    required this.todayMood,
    required this.onViewResult,
  });

  @override
  Widget build(BuildContext context) {
    final timeText = _formatCheckinTime(todayMood?.createdAt);
    final moodLabel = todayMood == null ? null : _moodLabel(todayMood!.mood);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onViewResult,
        child: Container(
          key: const Key('today-checkin-summary-card'),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF2F0ED)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: HealingStitchColors.paleCoral,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.favorite,
                  color: HealingStitchColors.pink,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Tóm tắt hôm nay',
                            style: healingText(weight: FontWeight.w900),
                          ),
                        ),
                        if (timeText != null)
                          Text(
                            timeText,
                            style: healingText(
                              size: 12,
                              weight: FontWeight.w800,
                              color: HealingStitchColors.textMuted,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (todayMood != null)
                      Text(
                        '$moodLabel - ${todayMood!.intensity}/10',
                        style: healingText(
                          size: 13,
                          weight: FontWeight.w800,
                          color: HealingStitchColors.textSoft,
                        ),
                      )
                    else
                      Text(
                        'Bạn đã check-in hôm nay',
                        style: healingText(
                          size: 13,
                          weight: FontWeight.w800,
                          color: HealingStitchColors.textSoft,
                        ),
                      ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: onViewResult,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        iconAlignment: IconAlignment.end,
                        icon: const Icon(Icons.arrow_forward, size: 16),
                        label: Text(
                          'Xem lại kết quả',
                          style: healingText(
                            size: 13,
                            weight: FontWeight.w900,
                            color: HealingStitchColors.pink,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _moodLabel(String mood) {
  return switch (mood) {
    'SAD' => 'Hơi buồn',
    'ANXIOUS' => 'Đang lo lắng',
    'STRESSED' => 'Căng thẳng',
    'CALM' => 'Tạm ổn',
    'HAPPY' => 'Tích cực',
    'ANGRY' => 'Đang bực',
    'NEUTRAL' => 'Bình thường',
    _ => mood,
  };
}

String? _formatCheckinTime(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return null;
  final hour = parsed.hour.toString().padLeft(2, '0');
  final minute = parsed.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
