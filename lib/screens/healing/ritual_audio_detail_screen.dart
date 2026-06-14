import 'package:flutter/material.dart';

import '../../widgets/navigation/bondy_bottom_nav_bar.dart';
import 'healing_navigation.dart';
import 'healing_stitch_style.dart';

class RitualAudioDetailScreen extends StatelessWidget {
  const RitualAudioDetailScreen({super.key});

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
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
          children: [
            HealingTopBar(
              title: 'Audio ritual',
              onBack: () => Navigator.of(context).maybePop(),
            ),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: SizedBox(
                width: double.infinity,
                height: 320,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      HealingStitchAssets.meditation,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const ColoredBox(
                            color: HealingStitchColors.paleCoral,
                            child: Center(
                              child: Icon(
                                Icons.headphones,
                                color: HealingStitchColors.pink,
                                size: 52,
                              ),
                            ),
                          ),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.55),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    const Align(
                      alignment: Alignment.bottomRight,
                      child: Padding(
                        padding: EdgeInsets.all(18),
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.play_arrow,
                            color: HealingStitchColors.pink,
                            size: 30,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Bài tập thở giúp dịu lại',
              style: healingText(size: 28, weight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              'Bondy Wellness - guided 5 phút',
              style: healingText(size: 13, color: HealingStitchColors.textSoft),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFF2F0ED)),
                boxShadow: [healingSoftShadow(0.05)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bạn sẽ nhận được gì sau 5 phút',
                    style: healingText(size: 16, weight: FontWeight.w900),
                  ),
                  const SizedBox(height: 14),
                  const _BenefitRow(
                    icon: Icons.air,
                    title: 'Nhịp thở đều hơn',
                    subtitle: 'Giúp cơ thể thoát khỏi trạng thái căng cứng.',
                  ),
                  const SizedBox(height: 12),
                  const _BenefitRow(
                    icon: Icons.spa_outlined,
                    title: 'Đầu óc nhẹ hơn',
                    subtitle: 'Có thêm khoảng trống trước khi phản ứng.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SizedBox(
          width: double.infinity,
          child: HealingGradientButton(
            label: 'Phát ngay',
            icon: Icons.play_arrow,
            onTap: () =>
                Navigator.of(context).pushNamed('/healing/audio-player'),
          ),
        ),
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _BenefitRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
              Text(title, style: healingText(weight: FontWeight.w900)),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: healingText(
                  size: 12,
                  height: 1.35,
                  color: HealingStitchColors.textSoft,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
