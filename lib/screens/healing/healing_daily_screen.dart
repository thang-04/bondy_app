import 'package:flutter/material.dart';

import '../../widgets/navigation/bondy_bottom_nav_bar.dart';
import 'daily_ritual_personalization.dart';
import 'healing_stitch_style.dart';

class HealingDailyScreen extends StatelessWidget {
  final String? mood;
  final int? intensity;

  const HealingDailyScreen({super.key, this.mood, this.intensity});

  @override
  Widget build(BuildContext context) {
    final args = _resolveArgs(context);
    final ritualModel = buildDailyRitualModel(
      mood: args.mood,
      intensity: args.intensity,
    );
    return Scaffold(
      backgroundColor: HealingStitchColors.creamBackground,
      bottomNavigationBar: BondyBottomNavBar(
        currentIndex: 1,
        onTabSelected: (index) {
          final route = switch (index) {
            0 => '/home',
            1 => '/home/healing',
            2 => '/home/matches',
            3 => '/home/profile',
            _ => '/home',
          };
          Navigator.of(context).pushNamedAndRemoveUntil(route, (_) => false);
        },
        onMatchTap: () => Navigator.of(context).pushNamed('/discover'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            HealingTopBar(
              title: 'Hành trình chữa lành',
              trailingIcon: Icons.account_circle_outlined,
              onBack: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 28),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: HealingStitchColors.pink.withValues(
                              alpha: 0.18,
                            ),
                          ),
                          boxShadow: [healingSoftShadow(0.035)],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: HealingStitchColors.pink,
                            ),
                            const SizedBox(width: 7),
                            Text(
                              _dailyBadge(args),
                              style: healingText(
                                size: 12,
                                weight: FontWeight.w900,
                                color: HealingStitchColors.pink,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _CompactTodayCard(
                      ritualModel: ritualModel,
                      onStart: () => Navigator.of(
                        context,
                      ).pushNamed(
                        resolvePrimaryRouteByCta(ritualModel.ctaLabel),
                      ),
                    ),
                  ),
                  const SizedBox(height: 26),
                  _CompactAudioLibrary(
                    onViewAll: () =>
                        Navigator.of(context).pushNamed('/content'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  HealingDailyArgs _resolveArgs(BuildContext context) {
    if (mood != null && intensity != null) {
      return HealingDailyArgs(mood: mood!, intensity: intensity!);
    }

    final routeArgs = ModalRoute.of(context)?.settings.arguments;
    if (routeArgs is HealingDailyArgs) return routeArgs;
    if (routeArgs is Map) {
      final argMood = routeArgs['mood']?.toString();
      final argIntensity = routeArgs['intensity'];
      final parsedIntensity = argIntensity is int
          ? argIntensity
          : int.tryParse(argIntensity?.toString() ?? '');
      if (argMood != null && parsedIntensity != null) {
        return HealingDailyArgs(mood: argMood, intensity: parsedIntensity);
      }
    }

    return const HealingDailyArgs(mood: 'NEUTRAL', intensity: 3);
  }

  String _dailyBadge(HealingDailyArgs args) {
    return 'Hôm nay - ${_moodLabel(args.mood)} ${args.intensity}/10';
  }

  String _moodLabel(String mood) {
    return switch (mood.toUpperCase()) {
      'SAD' => 'buồn',
      'ANXIOUS' => 'lo lắng',
      'ANGRY' => 'bực',
      'CALM' => 'ổn',
      'HAPPY' => 'tích cực',
      _ => 'cảm xúc',
    };
  }
}

class _CompactTodayCard extends StatelessWidget {
  final DailyRitualModel ritualModel;
  final VoidCallback onStart;

  const _CompactTodayCard({required this.ritualModel, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white),
        boxShadow: [healingSoftShadow()],
      ),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 2,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  HealingStitchAssets.compactHero,
                  fit: BoxFit.cover,
                  alignment: Alignment.centerRight,
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.64),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ritualModel.heroTitle,
                        style: healingText(
                          size: 21,
                          weight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Dành thời gian cho bản thân để hồi phục năng lượng.',
                        style: healingText(
                          size: 13,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                _CompactRitualRow(
                  icon: Icons.air,
                  iconColor: Color(0xFF3B82F6),
                  iconBackground: Color(0xFFEFF6FF),
                  title: ritualModel.firstItemTitle,
                  subtitle: ritualModel.firstItemSubtitle,
                ),
                const SizedBox(height: 12),
                _CompactRitualRow(
                  icon: Icons.edit_note,
                  iconColor: HealingStitchColors.purple,
                  iconBackground: Color(0xFFF5F0FF),
                  title: ritualModel.secondItemTitle,
                  subtitle: ritualModel.secondItemSubtitle,
                ),
                const SizedBox(height: 18),
                HealingGradientButton(
                  label: ritualModel.ctaLabel,
                  icon: Icons.play_arrow,
                  onTap: onStart,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactRitualRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String subtitle;

  const _CompactRitualRow({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: HealingStitchColors.creamBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF2F0ED)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: healingText(size: 13, weight: FontWeight.w900),
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
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE5E7EB), width: 2),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactAudioLibrary extends StatelessWidget {
  final VoidCallback onViewAll;

  const _CompactAudioLibrary({required this.onViewAll});

  @override
  Widget build(BuildContext context) {
    final tracks = [
      (
        HealingStitchAssets.compactAudioWater,
        'Nhạc nền thư giãn',
        'Âm thanh tự nhiên - 30p',
        Icons.nature_people_outlined,
        HealingStitchColors.orange,
      ),
      (
        HealingStitchAssets.compactAudioStones,
        'Audio chữa lành',
        'Dẫn thiền - 15p',
        Icons.self_improvement,
        HealingStitchColors.purple,
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
                  style: healingText(size: 20, weight: FontWeight.w900),
                ),
              ),
              TextButton(
                onPressed: onViewAll,
                child: Text(
                  'Xem tất cả',
                  style: healingText(
                    size: 13,
                    weight: FontWeight.w800,
                    color: HealingStitchColors.pink,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 198,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              final track = tracks[index];
              return GestureDetector(
                onTap: onViewAll,
                child: SizedBox(
                  width: 250,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.asset(track.$1, fit: BoxFit.cover),
                              Align(
                                alignment: Alignment.bottomRight,
                                child: Container(
                                  width: 42,
                                  height: 42,
                                  margin: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.32),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.play_arrow,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Transform.translate(
                        offset: const Offset(0, -10),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFF7F4F2)),
                            boxShadow: [healingSoftShadow(0.035)],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                track.$2,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: healingText(
                                  size: 15,
                                  weight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(track.$4, size: 14, color: track.$5),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      track.$3,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: healingText(
                                        size: 11,
                                        color: HealingStitchColors.textMuted,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemCount: tracks.length,
          ),
        ),
      ],
    );
  }
}
