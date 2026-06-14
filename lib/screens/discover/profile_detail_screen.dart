import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/bondy_exceptions.dart' show QuotaExceededException;
import '../../models/discover/discover_profile_model.dart';
import '../../services/api_client.dart';
import '../../services/discover_service.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/chat/chat_viewmodel.dart';
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
        await context.read<ChatViewModel>().fetchChats();
        if (!mounted) return;
        navigator.pop(action);
        if (result.conversationId != null) {
          final previewOther = result.matchPreview?.other;
          final otherUserId = previewOther?.id.isNotEmpty == true
              ? previewOther!.id
              : profile.id;
          final otherUserName = previewOther?.name.trim().isNotEmpty == true
              ? previewOther!.name
              : profile.name;
          final otherUserPhoto =
              previewOther?.photo ??
              (profile.imageUrl.isNotEmpty ? profile.imageUrl : null);
          await navigator.pushNamed(
            '/chat',
            arguments: {
              'chatId': result.conversationId,
              'matchId': result.matchId,
              'otherUserId': otherUserId,
              'name': otherUserName,
              'photo': otherUserPhoto,
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
        onPressed: _isSubmitting
            ? null
            : () {
                HapticFeedback.lightImpact();
                _swipe('LIKE');
              },
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFFFD3A84), Color(0xFFFF6B6B)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFD3A84).withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 6),
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
              : const Icon(Icons.favorite, color: Colors.white, size: 30),
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
            flexibleSpace: FlexibleSpaceBar(background: _buildHero(profile)),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hàng 1: Bento Grid nhỏ (% match & dating goal)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildCompatibility(profile)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildDatingGoal(profile)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Hàng 2: Gợi ý mở lời
                  _buildIcebreaker(profile),
                  const SizedBox(height: 16),

                  // Hàng 3: Về tôi
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.menu_book_rounded,
                              color: BondyColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Về tôi',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: BondyColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
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
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Hàng 4: Sở thích
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: BondyColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Sở thích',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: BondyColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (profile.tags.isEmpty &&
                            _buildDeepMatchTags(profile).isEmpty)
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
                            children: [
                              ..._buildDeepMatchTags(profile),
                              ...profile.tags.map(_buildTag),
                            ],
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildPhotoGallery(profile),
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
        final imageChild =
            (photos.isNotEmpty &&
                _currentPhotoIndex < photos.length &&
                photos[_currentPhotoIndex].startsWith('http'))
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
                    top: MediaQuery.of(context).padding.top + 12,
                    left: 20,
                    right: 20,
                    child: Row(
                      children: List.generate(
                        photos.length,
                        (idx) => Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            height: 2,
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
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.25),
                                width: 1,
                              ),
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
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB), // Amber pastel
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFEF3C7), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_rounded,
            color: Color(0xFFD97706), // Amber đậm
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GỢI Ý MỞ LỜI',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFD97706),
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  icebreakerText,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: const Color(0xFF78350F),
                    height: 1.5,
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.photo_library_rounded,
                color: BondyColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Hình ảnh',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: BondyColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
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
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 100,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? BondyColors.primary
                            : Colors.transparent,
                        width: 3,
                      ),
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
      ),
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      height: 106,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3FF), // Tím pastel
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.favorite_border_rounded,
            color: Color(0xFF8B5CF6),
            size: 24,
          ),
          const SizedBox(height: 10),
          Text(
            goalText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF6D28D9),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            goalSubtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF8B85C1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompatibility(DiscoverProfile profile) {
    return GestureDetector(
      onTap: () => _showCompatibilityBottomSheet(profile),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        height: 106,
        decoration: BoxDecoration(
          color: const Color(0xFFFFF0F5), // Hồng pastel
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.favorite_rounded,
              color: Color(0xFFEC4899),
              size: 24,
            ),
            const SizedBox(height: 10),
            Text(
              '${profile.matchPercentage}% Match',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF9D174D),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Mức độ hòa hợp',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: const Color(0xFFC97A9E),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String label) {
    final colors = [
      {'bg': const Color(0xFFEFF6FF), 'fg': const Color(0xFF1E40AF)}, // Blue
      {'bg': const Color(0xFFFFF0F5), 'fg': const Color(0xFF9D174D)}, // Pink
      {'bg': const Color(0xFFECFDF5), 'fg': const Color(0xFF065F46)}, // Green
      {'bg': const Color(0xFFFFF7ED), 'fg': const Color(0xFF9A3412)}, // Orange
      {'bg': const Color(0xFFF5F3FF), 'fg': const Color(0xFF5B21B6)}, // Purple
    ];

    final colorPair = colors[label.hashCode % colors.length];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: colorPair['bg'],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: colorPair['fg'],
        ),
      ),
    );
  }

  // Static translations
  static const Map<String, String> _zodiacNames = {
    'aries': 'Bạch Dương',
    'taurus': 'Kim Ngưu',
    'gemini': 'Song Tử',
    'cancer': 'Cự Giải',
    'leo': 'Sư Tử',
    'virgo': 'Xử Nữ',
    'libra': 'Thiên Bình',
    'scorpio': 'Bọ Cạp',
    'sagittarius': 'Nhân Mã',
    'capricorn': 'Ma Kết',
    'aquarius': 'Bảo Bình',
    'pisces': 'Song Ngư',
  };

  static const Map<String, String> _zodiacSymbols = {
    'aries': '♈',
    'taurus': '♉',
    'gemini': '♊',
    'cancer': '♋',
    'leo': '♌',
    'virgo': '♍',
    'libra': '♎',
    'scorpio': '♏',
    'sagittarius': '♐',
    'capricorn': '♑',
    'aquarius': '♒',
    'pisces': '♓',
  };

  static const Map<String, String> _freeTimeLabels = {
    'morning': 'Sáng',
    'afternoon': 'Chiều',
    'evening': 'Tối',
    'weekend': 'Cuối tuần',
    'flexible': 'Linh hoạt',
  };

  static const Map<String, String> _partnerTypeLabels = {
    'confidant': 'Bạn tâm sự',
    'lover': 'Người yêu',
    'life_partner': 'Bạn đời',
    'undecided': 'Chưa xác định',
  };

  List<Widget> _buildDeepMatchTags(DiscoverProfile profile) {
    final dm = profile.deepMatch;
    if (dm == null) return const [];

    final list = <Widget>[];

    if (dm.zodiacSign != null) {
      final signLower = dm.zodiacSign!.toLowerCase();
      final name = _zodiacNames[signLower] ?? dm.zodiacSign;
      final symbol = _zodiacSymbols[signLower] ?? '';
      list.add(
        _buildSpecialTag(
          '$symbol Cung $name',
          const Color(0xFFFDF2F8),
          const Color(0xFFDB2777),
        ),
      );
    }

    if (dm.lifePathNumber != null) {
      list.add(
        _buildSpecialTag(
          '🔢 Số chủ đạo ${dm.lifePathNumber}',
          const Color(0xFFF5F3FF),
          const Color(0xFF7C3AED),
        ),
      );
    }

    if (dm.desiredPartnerType != null) {
      final partnerName =
          _partnerTypeLabels[dm.desiredPartnerType] ?? dm.desiredPartnerType;
      list.add(
        _buildSpecialTag(
          '🎯 Tìm: $partnerName',
          const Color(0xFFECFDF5),
          const Color(0xFF059669),
        ),
      );
    }

    if (dm.freeTimeSlots.isNotEmpty) {
      final times = dm.freeTimeSlots
          .map((t) => _freeTimeLabels[t] ?? t)
          .join(', ');
      list.add(
        _buildSpecialTag(
          '⏰ Rảnh: $times',
          const Color(0xFFFFF7ED),
          const Color(0xFFEA580C),
        ),
      );
    }

    return list;
  }

  Widget _buildSpecialTag(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: fg.withValues(alpha: 0.15), width: 1),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }

  void _showCompatibilityBottomSheet(DiscoverProfile profile) {
    final factors = profile.compatibilityFactors;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.only(
            top: 14,
            left: 24,
            right: 24,
            bottom: 32,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Mức độ tương thích sâu',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: BondyColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)],
                      ).createShader(bounds),
                      child: Text(
                        '${profile.matchPercentage}%',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 54,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Match',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: BondyColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                if (factors.isEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Text(
                      'Độ tương thích được tính dựa trên các yếu tố cơ bản. Hãy trò chuyện để hiểu nhau hơn nhé!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: BondyColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ),
                ] else ...[
                  ...factors.map((factor) {
                    final title = _getFactorTitle(factor.type);
                    final desc = _getFactorDesc(factor.type, factor.score);
                    final percent = (factor.score * 100).toInt();

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                title,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: BondyColors.textPrimary,
                                ),
                              ),
                              Text(
                                '$percent%',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: BondyColors.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Stack(
                              children: [
                                Container(
                                  height: 8,
                                  width: double.infinity,
                                  color: BondyColors.primaryLight,
                                ),
                                FractionallySizedBox(
                                  widthFactor: factor.score.clamp(0.0, 1.0),
                                  child: Container(
                                    height: 8,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFEC4899),
                                          Color(0xFF8B5CF6),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            desc,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: BondyColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
                const SizedBox(height: 12),
                const Divider(color: Colors.black12),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Text('✨', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Hai bạn có nhiều tần số rung động tương đồng. Đừng ngần ngại gửi một lượt thích nhé!',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: BondyColors.textSecondary,
                            height: 1.4,
                          ),
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

  String _getFactorTitle(String type) {
    switch (type) {
      case 'zodiac':
        return 'Hòa hợp Cung hoàng đạo';
      case 'lifePath':
        return 'Kết nối Tần số học';
      case 'schedule':
        return 'Đồng điệu Lịch biểu';
      case 'interest':
        return 'Điểm chung Sở thích';
      case 'datingGoal':
        return 'Đồng nhất Mục tiêu';
      case 'vibe':
        return 'Đồng điệu Tâm hồn';
      default:
        return 'Yếu tố tương đồng';
    }
  }

  String _getFactorDesc(String type, double score) {
    if (score >= 0.8) {
      switch (type) {
        case 'zodiac':
          return 'Cung hoàng đạo của hai bạn cực kỳ lý tưởng để tạo nên mối quan hệ bền vững.';
        case 'lifePath':
          return 'Con số chủ đạo cộng hưởng mạnh mẽ, thúc đẩy sự thấu hiểu sâu sắc.';
        case 'schedule':
          return 'Khung giờ rảnh trùng khớp hoàn hảo, rất thuận tiện để trò chuyện và gặp gỡ.';
        case 'interest':
          return 'Có rất nhiều sở thích chung để cùng nhau trải nghiệm.';
        case 'datingGoal':
          return 'Mục tiêu kết nối hoàn toàn đồng nhất, cùng nhìn về một hướng.';
        default:
          return 'Độ tương thích cực kỳ cao, hai tâm hồn rất hòa hợp.';
      }
    } else if (score >= 0.5) {
      switch (type) {
        case 'zodiac':
          return 'Mối liên kết cung hoàng đạo khá tốt, dễ dàng chia sẻ cảm xúc.';
        case 'lifePath':
          return 'Tần số học chỉ ra hai bạn có thể học hỏi và hỗ trợ nhau phát triển.';
        case 'schedule':
          return 'Có những khoảng thời gian chung trong ngày để kết nối.';
        case 'interest':
          return 'Chia sẻ một vài thói quen và đam mê chung thú vị.';
        case 'datingGoal':
          return 'Quan điểm về mối quan hệ khá tương đồng.';
        default:
          return 'Có nhiều điểm chung tốt đẹp để cùng nhau xây dựng kết nối.';
      }
    } else {
      switch (type) {
        case 'zodiac':
          return 'Cung hoàng đạo cần sự nhường nhịn và thấu hiểu nhau hơn.';
        case 'lifePath':
          return 'Hai bạn sở hữu những nét cá tính riêng biệt đầy cuốn hút.';
        case 'schedule':
          return 'Lịch biểu hơi lệch nhưng sự chủ động sẽ xóa nhòa khoảng cách.';
        case 'interest':
          return 'Thế giới sở thích khác biệt là cơ hội tuyệt vời để khám phá điều mới từ nhau.';
        case 'datingGoal':
          return 'Hãy kiên nhẫn tìm hiểu thêm để tìm ra tiếng nói chung.';
        default:
          return 'Một chút khác biệt sẽ làm cho hành trình khám phá nhau thêm phần thú vị.';
      }
    }
  }
}
