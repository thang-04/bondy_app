import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:appinio_swiper/appinio_swiper.dart';
import '../../theme/app_theme.dart';
import '../../models/discover/discover_profile_model.dart';
import '../../services/discover_service.dart';
import '../../services/onboarding_router.dart';
import '../../viewmodels/discover/discover_viewmodel.dart';
import '../../widgets/match/new_match_receipt_sheet.dart';
import '../../widgets/common/bondy_feedback.dart';
import 'widgets/discover_matching_card.dart';
import 'widgets/discover_filters_sheet.dart';
import '../../widgets/discover/like_quota_exceeded_dialog.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/subscription/subscription_viewmodel.dart';

String discoverSwipeActionForDirection(AxisDirection direction) {
  switch (direction) {
    case AxisDirection.left:
      return 'PASS';
    case AxisDirection.right:
      return 'LIKE';
    case AxisDirection.up:
      return 'SUPER_LIKE';
    case AxisDirection.down:
      return 'PASS';
  }
}

class DiscoverMatchingScreen extends StatefulWidget {
  const DiscoverMatchingScreen({super.key});

  @override
  State<DiscoverMatchingScreen> createState() => _DiscoverMatchingScreenState();
}

class _DiscoverMatchingScreenState extends State<DiscoverMatchingScreen> {
  final AppinioSwiperController _swiperController = AppinioSwiperController();
  late final DiscoverService _discoverService;
  late final DiscoverViewModel _viewModel;
  String? _swipeFeedbackAction;
  bool _swipeFeedbackVisible = false;
  Timer? _swipeFeedbackTimer;

  @override
  void initState() {
    super.initState();
    _discoverService = DiscoverService();
    _viewModel = DiscoverViewModel(service: _discoverService);
    _viewModel.loadFilters();
    _viewModel.loadProfiles();
    _viewModel.addListener(_onViewModelUpdate);
  }

  void _onViewModelUpdate() {
    if (_viewModel.profileIncomplete) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showProfileIncompleteDialog();
      });
      return;
    }
    // Quota chip nằm trong AppBar (ngoài AnimatedBuilder của body) nên cần
    // setState mỗi lần viewmodel notify — nếu không sẽ không thấy "remaining"
    // giảm sau mỗi lần like.
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelUpdate);
    _swipeFeedbackTimer?.cancel();
    _swiperController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  void _onSwipeBegin(
    int previousIndex,
    int targetIndex,
    SwiperActivity activity,
  ) {
    if (activity is! Swipe) return;
    _showSwipeFeedback(discoverSwipeActionForDirection(activity.direction));
  }

  Future<void> _onSwipeEnd(
    int previousIndex,
    int targetIndex,
    SwiperActivity activity,
  ) async {
    if (activity is! Swipe) return;
    final profiles = _viewModel.profiles;
    if (previousIndex >= profiles.length) return;
    final profile = profiles[previousIndex];
    final action = discoverSwipeActionForDirection(activity.direction);
    final matched = await _viewModel.swipe(profile.id, action);
    if (!mounted) return;

    // Tests #14/#18: nếu server từ chối (quota / mạng lỗi), KHÔNG được coi
    // card đã được xử lý — phải hoàn tác animation và giữ card lại trong deck.
    // Nếu để removeProfileAt() chạy thì người dùng tưởng đã like/pass thành công.
    if (_viewModel.quotaExceeded) {
      await _swiperController.unswipe();
      if (!mounted) return;
      _showQuotaDialog();
      return;
    }
    if (_viewModel.lastSwipeFailed) {
      await _swiperController.unswipe();
      if (!mounted) return;
      final message =
          _viewModel.errorMessage ??
          'Không gửi được thao tác. Vui lòng thử lại.';
      BondyFeedback.showError(context, message);
      return;
    }

    _viewModel.removeProfileAt(previousIndex);
    if (matched && _viewModel.lastMatchId != null) {
      _showNewMatchDialog(
        _viewModel.lastMatchId!,
        _viewModel.lastConversationId,
        profile,
      );
      _viewModel.clearLastMatch();
    }
  }

  void _showSwipeFeedback(String action) {
    _swipeFeedbackTimer?.cancel();
    HapticFeedback.selectionClick();
    setState(() {
      _swipeFeedbackAction = action;
      _swipeFeedbackVisible = true;
    });
    _swipeFeedbackTimer = Timer(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() => _swipeFeedbackVisible = false);
    });
  }

  Future<void> _onRewind() async {
    final rewound = await _viewModel.rewindLastSwipe();
    if (!mounted) return;
    if (rewound) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã hoàn tác thao tác vừa rồi.')),
      );
    } else if (_viewModel.errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_viewModel.errorMessage!)));
    }
  }

  void _showQuotaDialog() {
    showDialog(
      context: context,
      builder: (ctx) => const LikeQuotaExceededDialog(),
    );
  }

  void _showNewMatchDialog(
    String matchId,
    String? chatId,
    DiscoverProfile profile,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      builder: (ctx) => NewMatchReceiptSheet(
        otherUserName: profile.name,
        otherUserPhoto: profile.imageUrl.isNotEmpty ? profile.imageUrl : null,
        compatibilityScore: profile.matchPercentage,
        factors: _buildMatchReceiptFactors(profile),
        onOpenChat: () {
          Navigator.pop(ctx);
          if (chatId != null) {
            Navigator.of(context).pushNamed(
              '/chat',
              arguments: {
                'chatId': chatId,
                'matchId': matchId,
                'otherUserId': profile.id,
                'name': profile.name,
                'photo': profile.imageUrl.isNotEmpty ? profile.imageUrl : null,
              },
            );
          } else {
            Navigator.of(
              context,
            ).pushNamed('/match-confirm', arguments: {'matchId': matchId});
          }
        },
        onDismiss: () => Navigator.pop(ctx),
      ),
    );
  }

  List<NewMatchReceiptFactor> _buildMatchReceiptFactors(
    DiscoverProfile profile,
  ) {
    final score = profile.matchPercentage.clamp(0, 100);
    final interestScore = (score - (profile.tags.isNotEmpty ? 6 : 12)).clamp(
      0,
      100,
    );
    final goalScore = (score - 14).clamp(0, 100);

    return [
      NewMatchReceiptFactor(label: 'Tính cách', score: score),
      NewMatchReceiptFactor(label: 'Sở thích', score: interestScore),
      NewMatchReceiptFactor(label: 'Mục tiêu', score: goalScore),
    ];
  }

  void _showProfileIncompleteDialog() {
    final nextAction = _viewModel.profileIncompleteNextAction;
    final route = OnboardingRouter.routeForAction(nextAction);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hồ sơ chưa hoàn chỉnh'),
        content: Text(_profileIncompleteMessage(nextAction)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Để sau'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _viewModel.clearProfileIncomplete();
              Navigator.of(context).pushNamed(route);
            },
            child: const Text('Đi hoàn thiện ngay'),
          ),
        ],
      ),
    );
  }

  String _profileIncompleteMessage(String? nextAction) {
    switch (nextAction) {
      case 'ADD_PHOTOS':
        return 'Bạn cần thêm ít nhất 1 ảnh đại diện để khám phá người phù hợp.';
      case 'SET_LOCATION':
        return 'Bạn cần thiết lập vị trí để tìm người gần bạn.';
      case 'COMPLETE_PROFILE':
        return 'Bạn cần hoàn thành thông tin cơ bản (tên, giới tính, ngày sinh).';
      case 'ADD_INTERESTS':
        return 'Bạn cần chọn ít nhất 3 sở thích để chúng tôi gợi ý phù hợp.';
      case 'COMPLETE_SURVEY':
        return 'Bạn cần hoàn thành bài khảo sát để cải thiện gợi ý.';
      default:
        return 'Vui lòng hoàn thành hồ sơ để sử dụng tính năng khám phá.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final subViewModel = context.watch<SubscriptionViewModel>();
    final hasUnlimitedLikes = subViewModel.currentSubscription?.unlimitedLikes == true;

    return Scaffold(
      backgroundColor: BondyColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Khám phá'),
        actions: [
          if (_viewModel.quota != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Chip(
                  label: Text(
                    hasUnlimitedLikes
                        ? '∞ like'
                        : '${_viewModel.quota!.remaining}/${_viewModel.quota!.limit} like',
                    style: const TextStyle(fontSize: 11),
                  ),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          IconButton(
            onPressed: () async {
              final filters = await showModalBottomSheet<DiscoverFilters>(
                context: context,
                isScrollControlled: true,
                builder: (_) => DiscoverFiltersSheet(
                  service: _discoverService,
                  initial: _viewModel.activeFilters,
                ),
              );
              if (filters != null) {
                await _viewModel.applyFilters(filters);
              }
            },
            icon: const Icon(Icons.tune),
            tooltip: 'Bộ lọc',
          ),
          IconButton(
            onPressed: () =>
                Navigator.of(context).pushNamed('/discover/softened'),
            icon: const Icon(Icons.spa_outlined),
            tooltip: 'Chế độ nhẹ nhàng',
          ),
        ],
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _viewModel,
          builder: (context, _) {
            if (_viewModel.isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: BondyColors.primary),
              );
            }

            if (_viewModel.errorMessage != null &&
                _viewModel.profiles.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    _viewModel.errorMessage!,
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            if (_viewModel.isEmpty) {
              return const Center(
                child: Text('Chưa có gợi ý phù hợp. Hãy quay lại sau nhé.'),
              );
            }

            final profiles = _viewModel.profiles;
            return Stack(
              children: [
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Người phù hợp với bạn',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Dựa trên sự đồng điệu cảm xúc',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: BondyColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Expanded area for the Swiper
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: AppinioSwiper(
                          controller: _swiperController,
                          swipeOptions: const SwipeOptions.only(
                            left: true,
                            right: true,
                            up: true,
                          ),
                          onSwipeBegin: _onSwipeBegin,
                          onSwipeEnd: _onSwipeEnd,
                          cardCount: profiles.length,
                          cardBuilder: (BuildContext context, int index) {
                            return DiscoverMatchingCard(
                              profile: profiles[index],
                            );
                          },
                        ),
                      ),
                    ),

                    // Bottom Action buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Rewind last swipe
                          _buildActionButton(
                            icon: Icons.replay,
                            color: const Color(0xFF6B7280),
                            onTap: _onRewind,
                            size: 48,
                            iconSize: 22,
                          ),
                          const SizedBox(width: 16),

                          // Dislike / Swipe Left
                          _buildActionButton(
                            icon: Icons.close,
                            color: const Color(0xFFEF4444),
                            onTap: () {
                              _showSwipeFeedback('PASS');
                              _swiperController.swipeLeft();
                            },
                          ),
                          const SizedBox(width: 16),

                          // Super Like (swipe up)
                          _buildActionButton(
                            icon: Icons.star_rounded,
                            color: const Color(0xFFF59E0B),
                            onTap: () {
                              _showSwipeFeedback('SUPER_LIKE');
                              _swiperController.swipeUp();
                            },
                            size: 64, // Larger central button
                            iconSize: 32,
                          ),
                          const SizedBox(width: 16),

                          // Like / Swipe Right
                          _buildActionButton(
                            icon: Icons.favorite,
                            color: BondyColors.primary,
                            onTap: () {
                              _showSwipeFeedback('LIKE');
                              _swiperController.swipeRight();
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                _buildSwipeFeedback(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    double size = 56,
    double iconSize = 28,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.25),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(color: color.withValues(alpha: 0.1), width: 1.5),
        ),
        child: Icon(icon, color: color, size: iconSize),
      ),
    );
  }

  Widget _buildSwipeFeedback() {
    final action = _swipeFeedbackAction;
    if (action == null) return const SizedBox.shrink();

    final isPass = action == 'PASS';
    final isSuper = action == 'SUPER_LIKE';
    final color = isPass
        ? const Color(0xFFEF4444)
        : isSuper
        ? const Color(0xFFF59E0B)
        : BondyColors.primary;
    final icon = isPass
        ? Icons.close
        : isSuper
        ? Icons.star_rounded
        : Icons.favorite;
    final label = isPass
        ? 'Da bo qua'
        : isSuper
        ? 'Super Like'
        : 'Da thich';

    return Positioned(
      left: 0,
      right: 0,
      top: 12,
      child: IgnorePointer(
        child: AnimatedOpacity(
          opacity: _swipeFeedbackVisible ? 1 : 0,
          duration: const Duration(milliseconds: 180),
          child: Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: color.withValues(alpha: 0.28)),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.22),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: color, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
