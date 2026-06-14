import 'package:flutter/material.dart';

import '../../widgets/navigation/bondy_bottom_nav_bar.dart';
import 'healing_navigation.dart';
import 'healing_stitch_style.dart';

class ReflectionCompleteSheet extends StatelessWidget {
  const ReflectionCompleteSheet({super.key});

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
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              HealingTopBar(
                title: 'Hoàn thành bài tập',
                onBack: () => Navigator.of(context).maybePop(),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFF2F0ED)),
                  boxShadow: [healingSoftShadow(0.04)],
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 64,
                      color: Color(0xFF16A34A),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Bạn đã làm rất tốt!',
                      textAlign: TextAlign.center,
                      style: healingText(size: 20, weight: FontWeight.w900),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Mỗi bước nhỏ đều giúp bạn nhẹ lòng hơn.',
                      textAlign: TextAlign.center,
                      style: healingText(
                        size: 14,
                        color: HealingStitchColors.textSoft,
                      ),
                    ),
                    const SizedBox(height: 24),
                    HealingGradientButton(
                      label: 'Tiếp tục khám phá',
                      icon: Icons.explore,
                      onTap: () => Navigator.of(context).pushNamed('/content'),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: () => Navigator.of(
                        context,
                      ).pushNamedAndRemoveUntil(healingHomeRoute, (_) => false),
                      child: const Text('Về Healing Home'),
                    ),
                  ],
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
