import 'package:flutter/material.dart';

import '../../models/discover/discover_profile_model.dart';
import '../../screens/healing/healing_stitch_style.dart';

class CommunityProfileCard extends StatelessWidget {
  final DiscoverProfile profile;
  final VoidCallback? onConnect;
  final VoidCallback? onSkip;
  final VoidCallback? onTap;

  const CommunityProfileCard({
    super.key,
    required this.profile,
    this.onConnect,
    this.onSkip,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = profile.imageUrl;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: HealingStitchColors.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [healingSoftShadow()],
        ),
        child: Column(
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: SizedBox(
                    width: 60,
                    height: 60,
                    child: imageUrl.startsWith('http')
                        ? Image.network(imageUrl, fit: BoxFit.cover)
                        : ColoredBox(
                            color: HealingStitchColors.paleCoral,
                            child: Center(
                              child: Text(
                                profile.name.isNotEmpty
                                    ? profile.name[0].toUpperCase()
                                    : '?',
                                style: healingText(
                                  size: 24,
                                  weight: FontWeight.w800,
                                  color: HealingStitchColors.coral,
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${profile.name}, ${profile.age}',
                        style: healingText(size: 18, weight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.favorite,
                            size: 14,
                            color: HealingStitchColors.coral,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${profile.matchPercentage}% đồng điệu',
                            style: healingText(
                              size: 13,
                              weight: FontWeight.w600,
                              color: HealingStitchColors.coral,
                            ),
                          ),
                        ],
                      ),
                      if (profile.tags.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          profile.tags.take(3).join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: healingText(size: 12, color: HealingStitchColors.textMuted),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: onSkip,
                    style: TextButton.styleFrom(
                      minimumSize: const Size(0, 44),
                      foregroundColor: HealingStitchColors.textMuted,
                    ),
                    child: Text('Bỏ qua', style: healingText(weight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: HealingStitchColors.warmGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [healingGlowShadow()],
                    ),
                    child: ElevatedButton(
                      onPressed: onConnect,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        minimumSize: const Size(0, 44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Kết nối',
                        style: healingText(
                          weight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
