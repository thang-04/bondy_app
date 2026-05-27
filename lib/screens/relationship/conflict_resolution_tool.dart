import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/bondy_button.dart';
import '../../widgets/common/bondy_widgets.dart';

/// Conflict resolution screen styled to match the Healing/Bondy design
/// language: warm cream background, coral palette accents on step tiles,
/// Manrope typography (via [bondyText]) and the shared [BondyPrimaryButton]
/// CTA — instead of the previous mix of arbitrary blue/pink/purple hexes
/// that broke the warm tone.
class ConflictResolutionTool extends StatelessWidget {
  const ConflictResolutionTool({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BondyColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BondyTopBar(
              title: 'Giải quyết mâu thuẫn',
              trailingIcon: Icons.favorite_border,
              onTrailing: () =>
                  Navigator.of(context).pushNamed('/relationship/checkin'),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cùng nhau vượt qua khó khăn',
                      style: bondyText(
                        size: 24,
                        weight: FontWeight.w800,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Mâu thuẫn là cơ hội để thấu hiểu nhau sâu sắc hơn. '
                      'Cùng thực hiện các bước sau nhé.',
                      style: bondyText(
                        size: 14,
                        color: BondyColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 28),
                    const _StepItem(
                      number: '1',
                      title: 'Dành 15 phút hạ hỏa',
                      description:
                          'Trước khi bắt đầu, cả hai hãy dành thời gian để '
                          'tâm trí bình tĩnh lại.',
                      icon: Icons.timer_outlined,
                      accent: BondyColors.coral,
                    ),
                    const _StepItem(
                      number: '2',
                      title: 'Chia sẻ cảm xúc của bạn',
                      description:
                          'Dùng cấu trúc "Anh/Em thấy... khi..." thay vì chỉ '
                          'trích đối phương.',
                      icon: Icons.record_voice_over_outlined,
                      accent: BondyColors.pink,
                    ),
                    const _StepItem(
                      number: '3',
                      title: 'Lắng nghe không ngắt lời',
                      description:
                          'Hãy để đối phương nói hết suy nghĩ của mình '
                          'trước khi phản hồi.',
                      icon: Icons.hearing_outlined,
                      accent: BondyColors.purple,
                    ),
                    const _StepItem(
                      number: '4',
                      title: 'Tìm kiếm giải pháp chung',
                      description:
                          'Cùng nhau đưa ra các phương án mà cả hai đều '
                          'thấy thoải mái.',
                      icon: Icons.lightbulb_outline,
                      accent: BondyColors.orange,
                    ),
                    const SizedBox(height: 12),
                    BondyPrimaryButton(
                      label: 'Bắt đầu phiên kết nối',
                      icon: Icons.favorite,
                      onTap: () {
                        // Hook up active session flow when available.
                      },
                    ),
                    const SizedBox(height: 12),
                    BondyButton(
                      text: 'Check-in cảm xúc ngay',
                      isOutlined: true,
                      icon: Icons.spa_outlined,
                      onPressed: () => Navigator.of(context)
                          .pushNamed('/relationship/checkin'),
                    ),
                    const SizedBox(height: 12),
                    BondyButton(
                      text: 'Hỏi Bondy gợi ý',
                      isOutlined: true,
                      icon: Icons.auto_awesome,
                      onPressed: () =>
                          Navigator.of(context).pushNamed('/chatbot'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  final String number;
  final String title;
  final String description;
  final IconData icon;
  final Color accent;

  const _StepItem({
    required this.number,
    required this.title,
    required this.description,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BondyColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: BondyColors.cardBorder),
        boxShadow: [bondySoftShadow()],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Bước $number',
                      style: bondyText(
                        size: 11,
                        weight: FontWeight.w800,
                        color: accent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: bondyText(size: 16, weight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: bondyText(
                    size: 13,
                    color: BondyColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
