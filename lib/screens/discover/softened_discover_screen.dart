import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/discover/discover_profile_model.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/discover/discover_viewmodel.dart';

class SoftenedDiscoverScreen extends StatefulWidget {
  const SoftenedDiscoverScreen({super.key});

  @override
  State<SoftenedDiscoverScreen> createState() => _SoftenedDiscoverScreenState();
}

class _SoftenedDiscoverScreenState extends State<SoftenedDiscoverScreen> {
  late final DiscoverViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = DiscoverViewModel()..loadProfiles();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Kham pha nhe nhang'),
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _viewModel,
          builder: (context, _) {
            return RefreshIndicator(
              onRefresh: () => _viewModel.loadProfiles(),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildIntro(),
                  const SizedBox(height: 24),
                  Text(
                    'Goi y hom nay',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_viewModel.isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_viewModel.errorMessage != null &&
                      _viewModel.profiles.isEmpty)
                    _buildStateMessage(
                      icon: Icons.error_outline,
                      message: _viewModel.errorMessage!,
                      actionLabel: 'Thu lai',
                      onAction: () => _viewModel.loadProfiles(),
                    )
                  else if (_viewModel.profiles.isEmpty)
                    _buildStateMessage(
                      icon: Icons.spa_outlined,
                      message: 'Chua co goi y phu hop. Hay quay lai sau nhe.',
                      actionLabel: 'Tai lai',
                      onAction: () => _viewModel.loadProfiles(),
                    )
                  else
                    ..._viewModel.profiles.map(_buildProfileRow),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildIntro() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: BondyColors.primaryLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          const Icon(Icons.spa_outlined, size: 40, color: BondyColors.primary),
          const SizedBox(height: 12),
          Text(
            'Khong voi vang',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: BondyColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bondy hien thi cung hang doi Discover, nhung theo cach de doc va cham hon.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: BondyColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileRow(DiscoverProfile profile) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: BondyColors.cardBorder),
      ),
      child: Row(
        children: [
          _buildAvatar(profile),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${profile.name}, ${profile.age}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${profile.matchPercentage}% match',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: BondyColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () => _openProfileDetail(profile),
            style: OutlinedButton.styleFrom(
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text('Xem'),
          ),
        ],
      ),
    );
  }

  Future<void> _openProfileDetail(DiscoverProfile profile) async {
    final result = await Navigator.of(
      context,
    ).pushNamed('/profile-detail', arguments: profile);
    if (!mounted) return;
    if (_isProcessedSwipeResult(result)) {
      _viewModel.removeProfileById(profile.id);
    }
  }

  bool _isProcessedSwipeResult(Object? result) {
    return result == 'LIKE' || result == 'PASS' || result == 'SUPER_LIKE';
  }

  Widget _buildStateMessage({
    required IconData icon,
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(icon, size: 40, color: BondyColors.textHint),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: BondyColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }

  Widget _buildAvatar(DiscoverProfile profile) {
    if (profile.imageUrl.startsWith('http')) {
      return CircleAvatar(
        radius: 24,
        backgroundImage: NetworkImage(profile.imageUrl),
      );
    }

    final initial = profile.name.trim().isEmpty
        ? 'B'
        : profile.name.trim()[0].toUpperCase();
    return CircleAvatar(
      radius: 24,
      backgroundColor: BondyColors.primaryLight,
      child: Text(
        initial,
        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
      ),
    );
  }
}
