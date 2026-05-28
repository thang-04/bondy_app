import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/bondy_exceptions.dart' show QuotaExceededException;
import '../../models/discover/discover_profile_model.dart';
import '../../services/api_client.dart';
import '../../services/discover_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/bondy_feedback.dart';
import '../../widgets/discover/like_quota_exceeded_dialog.dart';
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
  int _currentPhotoIndex = 0;

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
    } on QuotaExceededException {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => const LikeQuotaExceededDialog(),
      );
    } catch (e) {
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
      floatingActionButton: FloatingActionButton(
        onPressed: _isSubmitting ? null : () => _swipe('LIKE'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Color(0xFFFF4B8B), Color(0xFFFF6B6B)],
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x66FF4B8B),
                blurRadius: 15,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: _isSubmitting
              ? const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  ),
                )
              : const Icon(Icons.favorite, color: Colors.white, size: 28),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 520,
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
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHero(profile),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildIcebreaker(profile),
                  const SizedBox(height: 24),
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
                  const SizedBox(height: 24),
                  _buildPhotoGallery(profile),
                  const SizedBox(height: 24),
                  _buildDatingGoal(profile),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(DiscoverProfile profile) {
    final photos = profile.photos.isNotEmpty 
        ? profile.photos 
        : (profile.imageUrl.isNotEmpty ? [profile.imageUrl] : <String>[]);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final imageChild = (photos.isNotEmpty && _currentPhotoIndex < photos.length && photos[_currentPhotoIndex].startsWith('http'))
            ? Image.network(
                photos[_currentPhotoIndex],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildHeroPlaceholder(profile),
              )
            : _buildHeroPlaceholder(profile);

        return GestureDetector(
          onTapUp: (details) {
            final x = details.localPosition.dx;
            if (x < width * 0.35) {
              if (_currentPhotoIndex > 0) {
                setState(() {
                  _currentPhotoIndex--;
                });
              }
            } else if (x > width * 0.65) {
              if (_currentPhotoIndex < photos.length - 1) {
                setState(() {
                  _currentPhotoIndex++;
                });
              }
            }
          },
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(40),
              bottomRight: Radius.circular(40),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                imageChild,
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.75),
                        Colors.black.withValues(alpha: 0.1),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.45, 0.8],
                    ),
                  ),
                ),
                if (photos.length > 1)
                  Positioned(
                    top: 100,
                    left: 20,
                    right: 20,
                    child: Row(
                      children: List.generate(
                        photos.length,
                        (idx) => Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            height: 3,
                            decoration: BoxDecoration(
                              color: idx == _currentPhotoIndex
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 24,
                  left: 24,
                  right: 24,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '${profile.name}, ${profile.age}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              profile.distance,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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

  Widget _buildIcebreaker(DiscoverProfile profile) {
    final icebreakerText = profile.prompts.isNotEmpty 
        ? '"${profile.prompts.first.prompt}: ${profile.prompts.first.answer}"'
        : '"Hãy thử hỏi ${profile.name} về những hoạt động cuối tuần yêu thích của cô ấy nhé."';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        border: Border.all(color: const Color(0xFFE0E7FF)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline_rounded, color: Color(0xFF4F46E5), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GỢI Ý MỞ LỜI',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF4F46E5),
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  icebreakerText,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: const Color(0xFF4B5563),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoGallery(DiscoverProfile profile) {
    final photos = profile.photos.isNotEmpty 
        ? profile.photos 
        : (profile.imageUrl.isNotEmpty ? [profile.imageUrl] : <String>[]);
    if (photos.length <= 1) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hình ảnh',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: photos.length,
            itemBuilder: (context, index) {
              final isSelected = index == _currentPhotoIndex;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _currentPhotoIndex = index;
                  });
                },
                child: Container(
                  width: 120,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: isSelected
                        ? Border.all(color: BondyColors.primary, width: 3)
                        : null,
                    image: DecorationImage(
                      image: NetworkImage(photos[index]),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _getDatingGoalText(String? goal) {
    switch (goal) {
      case 'LONG_TERM':
        return 'Mối quan hệ lâu dài';
      case 'MARRIAGE':
        return 'Muốn tìm người bạn đời';
      case 'DATING':
        return 'Hẹn hò tìm hiểu';
      case 'FRIENDSHIP':
        return 'Kết bạn';
      case 'NOT_SURE':
        return 'Chưa xác định';
      default:
        return goal ?? 'Mối quan hệ lâu dài';
    }
  }

  String _getDatingGoalSubtitle(String? goal) {
    switch (goal) {
      case 'LONG_TERM':
        return 'Mong muốn kết nối nghiêm túc';
      case 'MARRIAGE':
        return 'Muốn xây dựng gia đình lâu dài';
      case 'DATING':
        return 'Trải nghiệm và tìm hiểu đối phương';
      case 'FRIENDSHIP':
        return 'Mở rộng vòng bạn bè cảm xúc';
      case 'NOT_SURE':
        return 'Mở lòng với mọi kiểu kết nối';
      default:
        return 'Mong muốn kết nối nghiêm túc';
    }
  }

  Widget _buildDatingGoal(DiscoverProfile profile) {
    final goalText = _getDatingGoalText(profile.datingGoal);
    final goalSubtitle = _getDatingGoalSubtitle(profile.datingGoal);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mục tiêu',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.favorite_rounded, color: Color(0xFFFF4B8B), size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goalText,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      goalSubtitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompatibility(DiscoverProfile profile) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BondyColors.primaryLight,
        borderRadius: BorderRadius.circular(16),
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
