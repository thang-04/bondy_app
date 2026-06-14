import 'package:flutter/material.dart';

import '../../widgets/navigation/bondy_bottom_nav_bar.dart';
import 'healing_navigation.dart';
import 'healing_stitch_style.dart';

class StarterRecommendationScreen extends StatelessWidget {
  const StarterRecommendationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HealingStitchColors.creamBackground,
      bottomNavigationBar: BondyBottomNavBar(
        currentIndex: 1,
        onTabSelected: (index) {
          final route = switch (index) {
            0 => '/home',
            1 => healingHomeRoute,
            2 => '/home/matches',
            3 => '/home/profile',
            _ => '/home',
          };
          Navigator.of(context).pushNamedAndRemoveUntil(route, (_) => false);
        },
        onMatchTap: () => Navigator.of(context).pushNamed('/discover'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            HealingTopBar(
              title: 'Starter',
              onBack: () => Navigator.of(context).maybePop(),
            ),
            const SizedBox(height: 10),
            Text(
              'Khởi động hành trình của bạn',
              style: healingText(size: 24, weight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              '3 gợi ý nhẹ nhàng để bắt đầu.',
              style: healingText(size: 13, color: HealingStitchColors.textSoft),
            ),
            const SizedBox(height: 18),
            _StarterItem(
              title: 'Bài tập 5 phút',
              subtitle: 'Thở sâu và ổn định nhịp cảm xúc',
              icon: Icons.self_improvement,
              onTap: () => Navigator.of(context).pushNamed(
                healingExerciseDetailRoute,
                arguments: 'exercise-self-worth-checklist',
              ),
            ),
            const SizedBox(height: 10),
            _StarterItem(
              title: 'Bài đọc nhập môn',
              subtitle: 'Hiểu điều gì đang xảy ra với cảm xúc của bạn',
              icon: Icons.menu_book_outlined,
              onTap: () => Navigator.of(context).pushNamed(
                healingArticleDetailRoute,
                arguments: 'article-ghosting-self-worth',
              ),
            ),
            const SizedBox(height: 10),
            _StarterItem(
              title: 'Lộ trình 7 ngày',
              subtitle: 'Bắt đầu lại với tiến trình nhỏ mỗi ngày',
              icon: Icons.route_outlined,
              onTap: () => Navigator.of(
                context,
              ).pushNamed(healingPlanRoute, arguments: const {'preview': true}),
            ),
          ],
        ),
      ),
    );
  }
}

class _StarterItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _StarterItem({
    required this.title,
    required this.subtitle,
    required this.icon,
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
