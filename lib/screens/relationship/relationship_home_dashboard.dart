import 'package:flutter/material.dart';

import '../healing/healing_stitch_style.dart';
import '../../viewmodels/relationship/relationship_viewmodel.dart';

class RelationshipHomeDashboard extends StatefulWidget {
  const RelationshipHomeDashboard({super.key});

  @override
  State<RelationshipHomeDashboard> createState() =>
      _RelationshipHomeDashboardState();
}

class _RelationshipHomeDashboardState extends State<RelationshipHomeDashboard> {
  late final RelationshipViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = RelationshipViewModel();
    _viewModel.loadDashboard();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        final dash = _viewModel.dashboard;
        if (_viewModel.isLoading && dash == null) {
          return const Scaffold(
            backgroundColor: HealingStitchColors.warmBackground,
            body: Center(
              child: CircularProgressIndicator(color: HealingStitchColors.coral),
            ),
          );
        }

        if (dash == null || !dash.hasRelationship) {
          return Scaffold(
            backgroundColor: HealingStitchColors.warmBackground,
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Của chúng mình',
                      style: healingText(size: 24, weight: FontWeight.w800),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Mời người yêu tham gia Bondy để cùng check-in, ghi nhận cột mốc và giải quyết mâu thuẫn.',
                      style: healingText(color: HealingStitchColors.textMuted),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: HealingStitchColors.warmGradient,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: ElevatedButton(
                          onPressed: () =>
                              Navigator.of(context).pushNamed('/relationship/invite'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            minimumSize: const Size(double.infinity, 52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text(
                            'Mời người yêu',
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
              ),
            ),
          );
        }

        final photo = dash.partnerPhotoUrl;
        return Scaffold(
          backgroundColor: HealingStitchColors.warmBackground,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Của chúng mình',
                            style: healingText(size: 24, weight: FontWeight.w800),
                          ),
                          Text(
                            dash.partnerName ?? 'Người yêu',
                            style: healingText(
                              size: 14,
                              color: HealingStitchColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      CircleAvatar(
                        radius: 24,
                        backgroundImage: photo != null && photo.startsWith('http')
                            ? NetworkImage(photo)
                            : null,
                        backgroundColor: HealingStitchColors.paleCoral,
                        child: photo == null || !photo.startsWith('http')
                            ? Text(
                                (dash.partnerName ?? '?')[0].toUpperCase(),
                                style: healingText(weight: FontWeight.w800),
                              )
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: HealingStitchColors.warmGradient,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [healingGlowShadow()],
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${dash.daysTogether} ngày bên nhau',
                          style: healingText(
                            size: 20,
                            weight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          dash.nextMilestoneTitle != null
                              ? 'Sắp tới: ${dash.nextMilestoneTitle}'
                              : 'Streak ${dash.streakDays} ngày check-in',
                          style: healingText(
                            size: 14,
                            color: Colors.white.withValues(alpha: 0.92),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _ActionTile(
                    icon: Icons.favorite_outline,
                    title: 'Check-in cảm xúc',
                    onTap: () =>
                        Navigator.of(context).pushNamed('/relationship/checkin'),
                  ),
                  _ActionTile(
                    icon: Icons.handshake_outlined,
                    title: 'Giải quyết mâu thuẫn',
                    onTap: () => Navigator.of(context)
                        .pushNamed('/relationship/conflict-tool'),
                  ),
                  _ActionTile(
                    icon: Icons.celebration_outlined,
                    title: 'Cột mốc',
                    onTap: () => Navigator.of(context)
                        .pushNamed('/relationship/milestones'),
                  ),
                  _ActionTile(
                    icon: Icons.bar_chart_outlined,
                    title: 'Báo cáo tuần',
                    onTap: () => Navigator.of(context)
                        .pushNamed('/relationship/weekly-report'),
                  ),
                  if (dash.recentCheckins.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Check-in gần đây',
                      style: healingText(size: 16, weight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    ...dash.recentCheckins.take(5).map(
                      (c) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Text(c.mood, style: const TextStyle(fontSize: 28)),
                        title: Text(
                          c.isMine ? 'Bạn' : (dash.partnerName ?? 'Người yêu'),
                          style: healingText(weight: FontWeight.w600),
                        ),
                        subtitle: c.note != null && c.note!.isNotEmpty
                            ? Text(c.note!, style: healingText(size: 13))
                            : null,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: HealingStitchColors.surface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: HealingStitchColors.coral),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: healingText(size: 16, weight: FontWeight.w700),
                  ),
                ),
                const Icon(Icons.chevron_right, color: HealingStitchColors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
