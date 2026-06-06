import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'healing_stitch_style.dart';
import '../../viewmodels/subscription/subscription_viewmodel.dart';

class HealingDashboardTab extends StatelessWidget {
  final bool isActive;

  const HealingDashboardTab({super.key, this.isActive = true});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: HealingStitchColors.warmBackground,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 118),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HealingTopBar(
                title: 'Hành trình Chữa lành',
                onBack: () => Navigator.of(context).maybePop(),
                onTrailing: () =>
                    Navigator.of(context).pushNamed('/healing/mode'),
              ),
              const HealingWeekTabs(),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hôm nay',
                            style: healingText(
                              size: 24,
                              weight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Sẵn sàng cho một ngày mới?',
                            style: healingText(
                              size: 13,
                              color: HealingStitchColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: HealingStitchColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: HealingStitchColors.border),
                        boxShadow: [healingSoftShadow(0.035)],
                      ),
                      child: Text(
                        '12 Thg 10',
                        style: healingText(size: 11, weight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _TodayRitualCard(
                  onStart: () =>
                      Navigator.of(context).pushNamed('/healing/audio-player'),
                ),
              ),
              const SizedBox(height: 26),
              _AudioLibrary(
                onViewAll: () => Navigator.of(context).pushNamed('/content'),
              ),
              const SizedBox(height: 18),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: _WeeklyProgressCard(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TodayRitualCard extends StatelessWidget {
  final VoidCallback onStart;

  const _TodayRitualCard({required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: HealingStitchColors.surface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: HealingStitchColors.border),
        boxShadow: [healingSoftShadow()],
      ),
      child: Stack(
        children: [
          SizedBox(
            height: 208,
            width: double.infinity,
            child: Image.asset(
              HealingStitchAssets.dailyHero,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
          Positioned.fill(
            top: 92,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0),
                    HealingStitchColors.surface,
                    HealingStitchColors.surface,
                  ],
                  stops: const [0, 0.3, 1],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 132, 18, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.86),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.spa_outlined,
                        size: 15,
                        color: HealingStitchColors.orange,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Chữa lành tâm hồn',
                        style: healingText(size: 11, weight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 11),
                Text(
                  'Hoạt động nhẹ nhàng hôm nay',
                  style: healingText(size: 19, weight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                const _RitualItem(
                  icon: Icons.air,
                  title: 'Thở sâu 5 phút',
                  subtitle: 'Giúp bình tĩnh tâm trí',
                ),
                const SizedBox(height: 10),
                const _RitualItem(
                  icon: Icons.edit_note,
                  title: 'Viết nhật ký ngắn',
                  subtitle: 'Ghi lại cảm xúc hiện tại',
                ),
                const SizedBox(height: 20),
                HealingGradientButton(label: 'Bắt đầu', onTap: onStart),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RitualItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _RitualItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: HealingStitchColors.warmBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: HealingStitchColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: HealingStitchColors.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [healingSoftShadow(0.035)],
            ),
            child: Icon(icon, color: HealingStitchColors.coral, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: healingText(size: 13, weight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: healingText(
                    size: 11,
                    color: HealingStitchColors.textMuted,
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

class _AudioLibrary extends StatelessWidget {
  final VoidCallback onViewAll;

  const _AudioLibrary({required this.onViewAll});

  @override
  Widget build(BuildContext context) {
    final subViewModel = context.watch<SubscriptionViewModel>();
    final isPremium = subViewModel.currentSubscription?.premiumHealing == true;

    final items = [
      (
        HealingStitchAssets.dailyAudioWater,
        'Nhạc nền thư giãn',
        '15 phút • Ambient',
        false,
        '/healing/audio-player',
      ),
      (
        HealingStitchAssets.dailyAudioBeach,
        'Audio chữa lành',
        '10 phút • Giọng đọc',
        false,
        '/healing/audio-player',
      ),
      (
        HealingStitchAssets.dailyAudioForest,
        'Thiền định sâu',
        isPremium ? 'Đã mở khóa' : 'Premium',
        !isPremium,
        '/healing/audio-player',
      ),
    ];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Thư viện âm thanh',
                  style: healingText(size: 20, weight: FontWeight.w800),
                ),
              ),
              TextButton(
                onPressed: onViewAll,
                child: Text(
                  'Xem tất cả',
                  style: healingText(
                    size: 13,
                    weight: FontWeight.w800,
                    color: HealingStitchColors.coral,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 198,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              final item = items[index];
              return GestureDetector(
                onTap: () {
                  if (item.$4) {
                    Navigator.of(context).pushNamed('/settings/premium');
                  } else {
                    Navigator.of(context).pushNamed(item.$5);
                  }
                },
                child: _AudioCard(
                  image: item.$1,
                  title: item.$2,
                  subtitle: item.$3,
                  locked: item.$4,
                ),
              );
            },
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemCount: items.length,
          ),
        ),
      ],
    );
  }
}

class _AudioCard extends StatelessWidget {
  final String image;
  final String title;
  final String subtitle;
  final bool locked;

  const _AudioCard({
    required this.image,
    required this.title,
    required this.subtitle,
    required this.locked,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: HealingStitchColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: HealingStitchColors.border),
        boxShadow: [healingSoftShadow(0.035)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(image, fit: BoxFit.cover),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Container(
                      width: 34,
                      height: 34,
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        locked ? Icons.lock : Icons.play_arrow,
                        size: locked ? 18 : 22,
                        color: locked
                            ? HealingStitchColors.textMuted
                            : HealingStitchColors.coral,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: healingText(size: 13, weight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: healingText(
              size: 11,
              weight: locked ? FontWeight.w800 : FontWeight.w600,
              color: locked
                  ? HealingStitchColors.orange
                  : HealingStitchColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyProgressCard extends StatelessWidget {
  const _WeeklyProgressCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: HealingStitchColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: HealingStitchColors.border),
        boxShadow: [healingSoftShadow()],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: HealingStitchColors.paleCoral,
              borderRadius: BorderRadius.circular(23),
            ),
            child: const Icon(
              Icons.trending_up,
              color: HealingStitchColors.coral,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tiến độ tuần này',
                  style: healingText(
                    size: 12,
                    weight: FontWeight.w800,
                    color: HealingStitchColors.textMuted,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: 0.6,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFF2EEE9),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      HealingStitchColors.coral,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Text(
            '60%',
            style: healingText(
              size: 20,
              weight: FontWeight.w900,
              color: HealingStitchColors.coral,
            ),
          ),
        ],
      ),
    );
  }
}
