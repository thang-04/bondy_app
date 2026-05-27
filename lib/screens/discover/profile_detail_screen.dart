import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/bondy_exceptions.dart' show QuotaExceededException;
import '../../models/discover/discover_profile_model.dart';
import '../../services/api_client.dart';
import '../../services/discover_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/bondy_feedback.dart';
import 'widgets/report_bottom_sheet.dart';

class ProfileDetailScreen extends StatefulWidget {
  const ProfileDetailScreen({super.key});

  @override
  State<ProfileDetailScreen> createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends State<ProfileDetailScreen> {
  late final DiscoverService _discoverService = DiscoverService(
    apiClient: ApiClient(),
  );
  bool _isSubmitting = false;

  DiscoverProfile? get _profile {
    final args = ModalRoute.of(context)?.settings.arguments;
    return args is DiscoverProfile ? args : null;
  }

  Future<void> _swipe(String action) async {
    final profile = _profile;
    if (profile == null || _isSubmitting) return;

    setState(() => _isSubmitting = true);
    try {
      if (action == 'LIKE') {
        await _discoverService.checkLikeQuota();
      }
      final result = await _discoverService.swipe(
        targetUserId: profile.id,
        action: action,
      );
      if (!mounted) return;
      final navigator = Navigator.of(context);
      if (result.matched && result.matchId != null) {
        navigator.pop(action);
        if (result.conversationId != null) {
          await navigator.pushNamed(
            '/chat',
            arguments: {
              'chatId': result.conversationId,
              'matchId': result.matchId,
              'otherUserId': profile.id,
              'name': profile.name,
              'photo': profile.imageUrl.isNotEmpty ? profile.imageUrl : null,
            },
          );
        } else {
          await navigator.pushNamed(
            '/match-confirm',
            arguments: {'matchId': result.matchId},
          );
        }
        return;
      }
      navigator.pop(action);
    } on QuotaExceededException catch (e) {
      // Test #14: hết quota ⇒ không pop màn detail.
      if (!mounted) return;
      BondyFeedback.showError(context, e, fallback: e.message);
    } catch (e) {
      // Test #18: lỗi mạng ⇒ giữ nguyên màn hình, báo lỗi rõ ràng.
      if (!mounted) return;
      BondyFeedback.showError(context, e);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    if (profile == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.person_off_outlined,
                  size: 44,
                  color: BondyColors.textHint,
                ),
                const SizedBox(height: 12),
                Text(
                  'Không tìm thấy hồ sơ.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: BondyColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            leading: IconButton(
              icon: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.arrow_back_ios_new,
                  size: 16,
                  color: BondyColors.textPrimary,
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                onPressed: _isSubmitting
                    ? null
                    : () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) =>
                              ReportBottomSheet(targetUserId: profile.id),
                        );
                      },
                icon: const CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.flag_outlined,
                    size: 18,
                    color: BondyColors.textPrimary,
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(background: _buildHero(profile)),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${profile.name}, ${profile.age}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    profile.distance,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: BondyColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildCompatibility(profile),
                  const SizedBox(height: 24),
                  Text(
                    'Về tôi',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    profile.bio.isEmpty
                        ? 'Người này chưa thêm giới thiệu.'
                        : profile.bio,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: BondyColors.textSecondary,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Sở thích',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (profile.tags.isEmpty)
                    Text(
                      'Chưa có sở thích.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: BondyColors.textSecondary,
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: profile.tags.map(_buildTag).toList(),
                    ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isSubmitting
                              ? null
                              : () => _swipe('PASS'),
                          icon: const Icon(Icons.close),
                          label: const Text('Bỏ qua'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isSubmitting
                              ? null
                              : () => _swipe('LIKE'),
                          icon: _isSubmitting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.favorite),
                          label: const Text('Kết nối'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(DiscoverProfile profile) {
    if (profile.imageUrl.startsWith('http')) {
      return Image.network(
        profile.imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _buildHeroPlaceholder(profile),
      );
    }

    return _buildHeroPlaceholder(profile);
  }

  Widget _buildHeroPlaceholder(DiscoverProfile profile) {
    final initial = profile.name.trim().isEmpty
        ? 'B'
        : profile.name.trim()[0].toUpperCase();
    return Container(
      color: BondyColors.primaryLight,
      child: Center(
        child: Text(
          initial,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 80,
            fontWeight: FontWeight.w800,
            color: BondyColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildCompatibility(DiscoverProfile profile) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BondyColors.primaryLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.favorite, color: BondyColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${profile.matchPercentage}% match',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: BondyColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: BondyColors.primaryLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
