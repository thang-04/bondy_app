import 'package:flutter/material.dart';

import '../healing_stitch_style.dart';

/// Onboarding Healing dạng **một sheet duy nhất**, chỉ mở khi user chạm
/// "Bắt đầu nhẹ nhàng" — thay cho first_time_entry_bottom_sheet auto-bật và
/// màn starter_recommendation riêng. (Redesign §5.8)
class HealingOnboardingSheet extends StatelessWidget {
  final VoidCallback onExercise;
  final VoidCallback onReading;
  final VoidCallback onPlan;

  const HealingOnboardingSheet({
    super.key,
    required this.onExercise,
    required this.onReading,
    required this.onPlan,
  });

  /// Mở sheet onboarding. Các callback nên tự lo điều hướng.
  static Future<void> show(
    BuildContext context, {
    required VoidCallback onExercise,
    required VoidCallback onReading,
    required VoidCallback onPlan,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => HealingOnboardingSheet(
        onExercise: () {
          Navigator.of(sheetContext).pop();
          onExercise();
        },
        onReading: () {
          Navigator.of(sheetContext).pop();
          onReading();
        },
        onPlan: () {
          Navigator.of(sheetContext).pop();
          onPlan();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: HealingStitchColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: HealingStitchColors.border,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Bắt đầu nhẹ nhàng',
              style: healingText(size: 20, weight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              'Chọn một bước nhỏ — bạn có thể đổi bất cứ lúc nào.',
              style: healingText(
                size: 13,
                color: HealingStitchColors.textSoft,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            _StarterTile(
              icon: Icons.self_improvement,
              title: 'Bài tập 5 phút',
              subtitle: 'Thở sâu và ổn định nhịp cảm xúc',
              onTap: onExercise,
            ),
            const SizedBox(height: 10),
            _StarterTile(
              icon: Icons.menu_book_outlined,
              title: 'Bài đọc nhập môn',
              subtitle: 'Hiểu điều gì đang xảy ra với cảm xúc của bạn',
              onTap: onReading,
            ),
            const SizedBox(height: 10),
            _StarterTile(
              icon: Icons.route_outlined,
              title: 'Lộ trình 7 ngày',
              subtitle: 'Bắt đầu lại với tiến trình nhỏ mỗi ngày',
              onTap: onPlan,
            ),
          ],
        ),
      ),
    );
  }
}

class _StarterTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _StarterTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFF2F0ED)),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: HealingStitchColors.paleCoral,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: HealingStitchColors.pink, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: healingText(size: 15, weight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: healingText(
                        size: 12,
                        color: HealingStitchColors.textSoft,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: HealingStitchColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
