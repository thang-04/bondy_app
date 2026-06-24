import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:appinio_swiper/appinio_swiper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../../models/discover/discover_profile_model.dart';
import '../../services/discover_service.dart';
import '../../services/profile_service.dart';
import '../../services/onboarding_router.dart';
import '../../viewmodels/discover/discover_viewmodel.dart';
import '../../widgets/match/new_match_receipt_sheet.dart';
import '../../widgets/common/bondy_feedback.dart';
import '../../widgets/onboarding/swipe_tutorial_overlay.dart';
import 'widgets/discover_matching_card.dart';
import 'widgets/discover_filters_sheet.dart';
import '../../widgets/discover/like_quota_exceeded_dialog.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/chat/chat_viewmodel.dart';
import '../../viewmodels/subscription/subscription_viewmodel.dart';
import '../../services/analytics_service.dart';

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
  String? _currentUserPhoto;
  
  final GlobalKey _bottomButtonsKey = GlobalKey();
  bool _showSwipeTutorial = false;

  // AppinioSwiper tự quản lý index của deck. KHÔNG được xóa profile khỏi list
  // trong lúc quẹt — nếu xóa, swiper vừa tự tăng index vừa bị thu nhỏ list nên
  // nhảy cóc qua 1 card (bug "double card / card sau không hiện"). Chỉ tạo
  // swiper mới (index về 0) bằng cách đổi _deckRevision khi nạp lại deck.
  int _deckRevision = 0;
  bool _deckEnded = false;

  // Queue tuần tự cho API swipe — tránh race condition khi quẹt nhanh.
  final Queue<_SwipeJob> _swipeQueue = Queue();
  bool _isProcessingSwipe = false;

  @override
  void initState() {
    super.initState();
    _discoverService = DiscoverService();
    _viewModel = DiscoverViewModel(service: _discoverService);
    _viewModel.addListener(_onViewModelUpdate);
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    _loadCurrentUserPhoto();
    await _viewModel.loadFilters();
    if (!mounted) return;
    await _viewModel.loadProfiles();
    _resetDeckView();
    _precacheNextImages();
    if (_viewModel.profiles.isNotEmpty) {
      _checkSwipeTutorial();
    }
  }

  Future<void> _checkSwipeTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeen = prefs.getBool('has_seen_swipe_tutorial') ?? false;
    if (!hasSeen && mounted) {
      setState(() => _showSwipeTutorial = true);
    }
  }

  Future<void> _dismissSwipeTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_swipe_tutorial', true);
    if (mounted) {
      setState(() => _showSwipeTutorial = false);
    }
  }

  /// Tạo lại swiper từ đầu deck (index về 0) sau khi list được nạp lại hoàn
  /// toàn — initial load, đổi bộ lọc, hoặc hoàn tác (rewind).
  void _resetDeckView() {
    if (!mounted) return;
    setState(() {
      _deckRevision++;
      _deckEnded = false;
    });
  }

  Future<void> _loadCurrentUserPhoto() async {
    try {
      final profile = await ProfileService().getProfile();
      if (!mounted) return;
      final photo = profile.photos.isNotEmpty
          ? profile.photos.first
          : profile.image;
      setState(() => _currentUserPhoto = photo);
    } catch (_) {}
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

    // Capture profile trước khi mutate list.
    final profile = profiles[previousIndex];
    final action = discoverSwipeActionForDirection(activity.direction);

    // Pre-check quota ĐỒNG BỘ trước khi remove card — nếu hết quota thì giữ
    // card lại ngay lập tức, không cần chờ server.
    if ((action == 'LIKE' || action == 'SUPER_LIKE') &&
        _viewModel.quota != null &&
        _viewModel.quota!.remaining <= 0) {
      await _swiperController.unswipe();
      if (!mounted) return;
      _showQuotaDialog();
      return;
    }

    // ── KHÔNG xóa card khỏi list ở đây ──
    // AppinioSwiper đã tự tăng index sang card kế tiếp. Nếu xóa profile khỏi
    // list nữa thì list co lại + index tăng = nhảy cóc qua 1 card (bug card sau
    // không hiện). Để swiper tự quản lý; card đã quẹt sẽ biến mất khỏi feed ở
    // lần nạp lại sau (server đã loại nó qua exclusion set).
    _precacheNextImages(start: targetIndex);

    // Track swipe event
    if (action == 'LIKE') {
      analytics.swipeLike(profile.id);
    } else if (action == 'PASS') {
      analytics.swipePass(profile.id);
    } else if (action == 'SUPER_LIKE') {
      analytics.track('swipe_super_like', {'targetUserId': profile.id});
    }

    // Enqueue API call xử lý tuần tự ở background.
    _swipeQueue.add(_SwipeJob(profile: profile, action: action));
    _processSwipeQueue();
  }

  /// Xử lý queue swipe tuần tự — mỗi lần chỉ 1 API call chạy.
  Future<void> _processSwipeQueue() async {
    if (_isProcessingSwipe) return;
    _isProcessingSwipe = true;

    while (_swipeQueue.isNotEmpty) {
      final job = _swipeQueue.removeFirst();
      try {
        final matched = await _viewModel.swipe(job.profile.id, job.action);
        if (!mounted) break;

        if (matched && _viewModel.lastMatchId != null) {
          await context.read<ChatViewModel>().fetchChats();
          if (!mounted) break;
          _showNewMatchDialog(
            _viewModel.lastMatchId!,
            _viewModel.lastConversationId,
            job.profile,
            _viewModel.lastMatchPreview,
          );
          _viewModel.clearLastMatch();
        }

        // Nếu server từ chối (hết quota, mạng lỗi…) thì đưa card vừa quẹt trở
        // lại bằng unswipe() — KHÔNG chèn lại vào list (sẽ làm lệch index của
        // swiper). unswipe lùi swiper đúng 1 bước về card vừa rồi.
        if (_viewModel.lastSwipeFailed || _viewModel.quotaExceeded) {
          if (!mounted) break;
          await _swiperController.unswipe();
          if (!mounted) break;
          if (_viewModel.quotaExceeded) {
            _showQuotaDialog();
          } else {
            BondyFeedback.showError(
              context,
              _viewModel.errorMessage ??
                  'Không gửi được thao tác. Vui lòng thử lại.',
            );
          }
        }
      } catch (_) {
        // Lỗi không mong muốn — báo lỗi, card sẽ xuất hiện lại ở lần nạp sau.
        if (mounted) {
          BondyFeedback.showError(
            context,
            'Không gửi được thao tác. Vui lòng thử lại.',
          );
        }
        break;
      }
    }

    _isProcessingSwipe = false;
  }

  /// Precache ảnh cho 2-3 card tiếp theo (tính từ [start]) để giảm lag.
  void _precacheNextImages({int start = 0}) {
    if (!mounted) return;
    final profiles = _viewModel.profiles;
    if (profiles.isEmpty) return;
    final from = start.clamp(0, profiles.length);
    final to = (from + 3).clamp(0, profiles.length);
    for (int i = from; i < to; i++) {
      final url = profiles[i].imageUrl;
      if (url.isNotEmpty && url.startsWith('http')) {
        precacheImage(NetworkImage(url), context).catchError((_) {});
      }
      // Cũng precache ảnh đầu tiên trong gallery nếu khác imageUrl
      if (profiles[i].photos.isNotEmpty) {
        final firstPhoto = profiles[i].photos.first;
        if (firstPhoto != url && firstPhoto.startsWith('http')) {
          precacheImage(NetworkImage(firstPhoto), context).catchError((_) {});
        }
      }
    }
  }

  Future<void> _openProfileDetail(DiscoverProfile profile) async {
    final result = await Navigator.of(
      context,
    ).pushNamed('/profile-detail', arguments: profile);
    if (!mounted) return;
    if (_isProcessedSwipeResult(result)) {
      // Đã quẹt trong màn chi tiết → server đã loại profile này. Nạp lại deck và
      // reset swiper về đầu thay vì xóa thủ công (tránh lệch index của swiper).
      await _viewModel.loadProfiles();
      if (!mounted) return;
      _resetDeckView();
      await _viewModel.loadQuota();
      _precacheNextImages();
    }
  }

  bool _isProcessedSwipeResult(Object? result) {
    return result == 'LIKE' || result == 'PASS' || result == 'SUPER_LIKE';
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
      // rewindLastSwipe đã nạp lại feed → reset swiper về đầu deck mới.
      _resetDeckView();
      _precacheNextImages();
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
    SwipeMatchPreview? matchPreview,
  ) {
    final previewOther = matchPreview?.other;
    final otherUserId = previewOther?.id.isNotEmpty == true
        ? previewOther!.id
        : profile.id;
    final otherUserName = previewOther?.name.trim().isNotEmpty == true
        ? previewOther!.name
        : profile.name;
    final otherUserPhoto =
        previewOther?.photo ??
        (profile.imageUrl.isNotEmpty ? profile.imageUrl : null) ??
        (profile.photos.isNotEmpty ? profile.photos.first : null);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      builder: (ctx) => NewMatchReceiptSheet(
        currentUserPhoto: matchPreview?.current.photo ?? _currentUserPhoto,
        otherUserName: otherUserName,
        otherUserPhoto: otherUserPhoto,
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
                'otherUserId': otherUserId,
                'name': otherUserName,
                'photo': otherUserPhoto,
                'chatAccepted': false,
                'isInitiator': true,
                'isMessageRequest': false,
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
    final hasUnlimitedLikes =
        subViewModel.currentSubscription?.unlimitedLikes == true;

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
                _resetDeckView();
                _precacheNextImages();
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
                        child: _deckEnded
                            ? _buildDeckEnded()
                            : AppinioSwiper(
                                // Đổi key khi nạp lại deck để swiper khởi tạo lại
                                // từ index 0 (không có API reset index công khai).
                                key: ValueKey(_deckRevision),
                                controller: _swiperController,
                                swipeOptions: const SwipeOptions.only(
                                  left: true,
                                  right: true,
                                  up: true,
                                ),
                                onSwipeBegin: _onSwipeBegin,
                                onSwipeEnd: _onSwipeEnd,
                                onEnd: () {
                                  if (mounted) {
                                    setState(() => _deckEnded = true);
                                  }
                                },
                                cardCount: profiles.length,
                                cardBuilder:
                                    (BuildContext context, int index) {
                                      return DiscoverMatchingCard(
                                        profile: profiles[index],
                                        onOpenDetail: _openProfileDetail,
                                      );
                                    },
                                ),
                      ),
                    ),

                    // Bottom Action buttons
                    Padding(
                      key: _bottomButtonsKey,
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
                              if (_deckEnded) return;
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
                              if (_deckEnded) return;
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
                              if (_deckEnded) return;
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
                if (_showSwipeTutorial)
                  Positioned.fill(
                    child: SwipeTutorialOverlay(
                      bottomButtonsKey: _bottomButtonsKey,
                      onDismiss: _dismissSwipeTutorial,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Hiển thị khi đã quẹt hết deck đã nạp — cho phép tải thêm gợi ý.
  Widget _buildDeckEnded() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.favorite_border,
            size: 56,
            color: BondyColors.primary,
          ),
          const SizedBox(height: 12),
          Text(
            'Bạn đã xem hết gợi ý hiện có.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () async {
              await _viewModel.loadProfiles();
              if (!mounted) return;
              _resetDeckView();
              _precacheNextImages();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Tải thêm'),
          ),
        ],
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
        ? 'Đã bỏ qua'
        : isSuper
        ? 'Super Like'
        : 'Đã thích';

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

/// Job struct cho swipe queue.
class _SwipeJob {
  final DiscoverProfile profile;
  final String action;

  const _SwipeJob({required this.profile, required this.action});
}
