import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class MoodEntry {
  final String mood;
  final int percentage;

  const MoodEntry({required this.mood, required this.percentage});
}

class MoodDistributionChart extends StatelessWidget {
  final List<MoodEntry> entries;

  const MoodDistributionChart({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BondyColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BondyColors.divider),
      ),
      child: Column(children: entries.map((e) => _buildRow(e)).toList()),
    );
  }

  Widget _buildRow(MoodEntry entry) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              _moodLabel(entry.mood),
              style: const TextStyle(
                fontSize: 13,
                color: BondyColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: entry.percentage / 100,
                minHeight: 10,
                backgroundColor: BondyColors.divider,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _moodColor(entry.mood),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 36,
            child: Text(
              '${entry.percentage}%',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: BondyColors.textSecondary,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  String _moodLabel(String mood) {
    const labels = {
      'happy': 'Vui vẻ',
      'excited': 'Phấn khích',
      'calm': 'Bình tĩnh',
      'neutral': 'Bình thường',
      'anxious': 'Lo lắng',
      'sad': 'Buồn',
      'angry': 'Tức giận',
    };
    return labels[mood] ?? mood;
  }

  Color _moodColor(String mood) {
    const colors = {
      'happy': Color(0xFF4CAF50),
      'excited': Color(0xFFFF9800),
      'calm': Color(0xFF2196F3),
      'neutral': Color(0xFF9E9E9E),
      'anxious': Color(0xFFFF7043),
      'sad': Color(0xFF607D8B),
      'angry': Color(0xFFF44336),
    };
    return colors[mood] ?? BondyColors.primary;
  }
}
