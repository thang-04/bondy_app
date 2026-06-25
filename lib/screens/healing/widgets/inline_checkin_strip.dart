import 'package:flutter/material.dart';

import '../healing_stitch_style.dart';

/// Dải mời gọi check-in **inline** trên Home — không phải popup. User chủ động
/// chạm một biểu cảm để mở [EmotionalCheckinSheet]. (Redesign §5.1, §4.1)
class InlineCheckinStrip extends StatelessWidget {
  /// Gọi với mood đã chọn (hoặc `null` khi chạm "›" để mở sheet không chọn sẵn).
  final void Function(String? mood) onPick;

  const InlineCheckinStrip({super.key, required this.onPick});

  static const List<Map<String, String>> _moods = [
    {'emoji': '😢', 'mood': 'SAD'},
    {'emoji': '😰', 'mood': 'ANXIOUS'},
    {'emoji': '😐', 'mood': 'NEUTRAL'},
    {'emoji': '🙂', 'mood': 'CALM'},
    {'emoji': '😊', 'mood': 'HAPPY'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('inline-checkin-strip'),
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      decoration: BoxDecoration(
        color: HealingStitchColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: HealingStitchColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bạn thấy thế nào hôm nay?',
            style: healingText(size: 14, weight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final m in _moods) ...[
                _MoodDot(
                  emoji: m['emoji']!,
                  onTap: () => onPick(m['mood']),
                ),
                const SizedBox(width: 6),
              ],
              const Spacer(),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onPick(null),
                child: const Icon(
                  Icons.chevron_right,
                  color: HealingStitchColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MoodDot extends StatelessWidget {
  final String emoji;
  final VoidCallback onTap;

  const _MoodDot({required this.emoji, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: HealingStitchColors.contentBackground,
          shape: BoxShape.circle,
        ),
        child: Text(emoji, style: const TextStyle(fontSize: 22)),
      ),
    );
  }
}
