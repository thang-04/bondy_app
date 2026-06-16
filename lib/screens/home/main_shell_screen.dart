import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/discover/discover_profile_model.dart';
import '../../models/user_profile_model.dart';
import '../../services/profile_service.dart';
import '../../services/auth_service.dart';
import '../../core/bondy_error_mapper.dart';
import '../../core/bondy_exceptions.dart' show QuotaExceededException;
import '../../widgets/common/bondy_feedback.dart';
import '../../theme/app_theme.dart';
import '../../widgets/navigation/bondy_bottom_nav_bar.dart';
import '../../viewmodels/chat/chat_viewmodel.dart';
import '../../viewmodels/relationship/relationship_viewmodel.dart';
import '../healing/healing_mode_dashboard_screen.dart';
import '../chat/matches_list_screen.dart';
import '../relationship/relationship_home_dashboard.dart';
import '../healing/healing_stitch_style.dart';
import '../../viewmodels/community/community_viewmodel.dart';
import '../../widgets/community/community_profile_card.dart';
import '../../services/discover_service.dart';
import '../auth/interests_setup_screen.dart';
import 'home_dashboard_screen.dart';
import '../../widgets/discover/like_quota_exceeded_dialog.dart';

class MainShellScreen extends StatefulWidget {
  final ProfileService? profileService;
  final int initialIndex;

  const MainShellScreen({
    super.key,
    this.profileService,
    this.initialIndex = 0,
  });

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen>
    with WidgetsBindingObserver {
  late int _currentIndex;
  late final ProfileService _profileService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentIndex = widget.initialIndex;
    _profileService = widget.profileService ?? ProfileService();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ChatViewModel>().fetchChats();
      context.read<RelationshipViewModel>().loadDashboard();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<RelationshipViewModel>().loadDashboard();
    }
  }

  void _selectTab(int index) {
    setState(() => _currentIndex = index);
    if (index == 0) {
      context.read<RelationshipViewModel>().loadDashboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalUnread = context.watch<ChatViewModel>().totalUnreadCount;
    return Scaffold(
      backgroundColor: BondyColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          RelationshipModeHome(
            standardHome: HomeDashboardScreen(
              onNavigateToHealing: () => _selectTab(1),
              onNavigateToMatches: () => _selectTab(2),
              onNavigateToProfile: () => _selectTab(3),
            ),
            relationshipHome: RelationshipHomeDashboard(
              viewModel: context.read<RelationshipViewModel>(),
              showBackButton: false,
            ),
          ),
          HealingModeDashboardScreen(
            isActive: _currentIndex == 1,
            showBottomNavigation: false,
          ),
          const _MatchesTab(),
          _ProfileTab(
            profileService: _profileService,
            onNavigateToHome: () => _selectTab(0),
          ),
        ],
      ),
      extendBody: true,
      bottomNavigationBar: BondyBottomNavBar(
        currentIndex: _currentIndex,
        onTabSelected: _selectTab,
        onMatchTap: () => Navigator.of(context).pushNamed('/discover'),
        hasMatchBadge: totalUnread > 0,
      ),
    );
  }
}

class RelationshipModeHome extends StatelessWidget {
  final Widget standardHome;
  final Widget relationshipHome;

  const RelationshipModeHome({
    super.key,
    required this.standardHome,
    required this.relationshipHome,
  });

  @override
  Widget build(BuildContext context) {
    final hasRelationship = context
        .watch<RelationshipViewModel>()
        .hasActiveRelationship;
    return hasRelationship ? relationshipHome : standardHome;
  }
}

// Legacy _HomeTab replaced by HomeDashboardScreen (see home_dashboard_screen.dart).

// ===== HEALING TAB =====
// ignore: unused_element
class _HealingTab extends StatelessWidget {
  const _HealingTab();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hành trình Chữa lành',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: BondyColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            // Week tabs
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildWeekTab('Tuần 1', true),
                  _buildWeekTab('Tuần 2', false),
                  _buildWeekTab('Tuần 3', false),
                  _buildWeekTab('Tuần 4', false),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Today card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: BondyColors.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hôm nay',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sẵn sàng cho một ngày mới?',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Activities
            Text(
              'Hoạt động nhẹ nhàng hôm nay',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _buildActivityCard('📝', 'Viết nhật ký cảm xúc', '5 phút', false),
            const SizedBox(height: 8),
            _buildActivityCard('🧘', 'Bài tập hít thở', '3 phút', true),
            const SizedBox(height: 8),
            _buildActivityCard('💭', 'Suy ngẫm tích cực', '10 phút', false),
            const SizedBox(height: 24),
            // Audio library
            Text(
              'Thư viện âm thanh',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => Navigator.of(context).pushNamed('/content'),
              child: _buildAudioCard(
                '🎵',
                'Nhạc nền thư giãn',
                '15 phút • Ambient',
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => Navigator.of(context).pushNamed('/content'),
              child: _buildAudioCard(
                '🎙️',
                'Audio chữa lành',
                '10 phút • Giọng đọc',
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => Navigator.of(context).pushNamed('/content'),
              child: _buildAudioCard('🔒', 'Thiền định sâu', 'Premium'),
            ),
            const SizedBox(height: 24),
            // Bondy Coach section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.psychology,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Bondy Coach',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Cảm thấy muốn chia sẻ? Mình lắng nghe bạn.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pushNamed('/chatbot'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Nói chuyện với Bondy',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF6366F1),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Weekly progress
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: BondyColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tiến độ tuần này',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(7, (index) {
                      final days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
                      final completed = index < 2;
                      return Column(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: completed
                                  ? BondyColors.primary
                                  : BondyColors.divider,
                              shape: BoxShape.circle,
                            ),
                            child: completed
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 16,
                                  )
                                : null,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            days[index],
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: BondyColors.textHint,
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildWeekTab(String label, bool isActive) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? BondyColors.primary : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive ? BondyColors.primary : BondyColors.divider,
        ),
      ),
      child: Center(
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : BondyColors.textSecondary,
          ),
        ),
      ),
    );
  }

  static Widget _buildActivityCard(
    String emoji,
    String title,
    String duration,
    bool completed,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: BondyColors.cardBorder),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    decoration: completed ? TextDecoration.lineThrough : null,
                  ),
                ),
                Text(
                  duration,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: BondyColors.textHint,
                  ),
                ),
              ],
            ),
          ),
          if (completed)
            const Icon(Icons.check_circle, color: BondyColors.primary)
          else
            const Icon(Icons.play_circle_outline, color: BondyColors.textHint),
        ],
      ),
    );
  }

  static Widget _buildAudioCard(String emoji, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: BondyColors.cardBorder),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: BondyColors.textHint,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.play_arrow, color: BondyColors.primary),
        ],
      ),
    );
  }
}

// ===== COMMUNITY TAB =====
class _MatchesTab extends StatelessWidget {
  const _MatchesTab();

  @override
  Widget build(BuildContext context) {
    return const MatchesListScreen(embedded: true);
  }
}

class _CommunityTab extends StatefulWidget {
  const _CommunityTab();

  @override
  State<_CommunityTab> createState() => _CommunityTabState();
}

class _CommunityTabState extends State<_CommunityTab> {
  late final CommunityViewModel _viewModel;
  final DiscoverService _discoverService = DiscoverService();

  @override
  void initState() {
    super.initState();
    _viewModel = CommunityViewModel();
    _viewModel.loadFeed();
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
        return Scaffold(
          backgroundColor: HealingStitchColors.warmBackground,
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: _viewModel.loadFeed,
              color: HealingStitchColors.coral,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cộng đồng',
                      style: healingText(size: 24, weight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tìm người đồng điệu với bạn',
                      style: healingText(
                        size: 14,
                        color: HealingStitchColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_viewModel.isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(
                            color: HealingStitchColors.coral,
                          ),
                        ),
                      )
                    else if (_viewModel.errorMessage != null)
                      BondyErrorBanner(
                        message: _viewModel.errorMessage!,
                        onRetry: _viewModel.loadFeed,
                      )
                    else if (_viewModel.profiles.isEmpty)
                      Text(
                        'Chưa có gợi ý. Hoàn thiện hồ sơ và quay lại sau nhé.',
                        style: healingText(
                          color: HealingStitchColors.textMuted,
                        ),
                      )
                    else
                      ..._viewModel.profiles.map(
                        (profile) => CommunityProfileCard(
                          profile: profile,
                          onTap: () => _openProfileDetail(profile),
                          onConnect: () => _handleConnect(profile),
                          onSkip: () => _handleSkip(profile),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openProfileDetail(DiscoverProfile profile) async {
    final result = await Navigator.of(
      context,
    ).pushNamed('/profile-detail', arguments: profile);
    if (!mounted) return;
    if (_isProcessedSwipeResult(result)) {
      await _viewModel.loadFeed();
    }
  }

  bool _isProcessedSwipeResult(Object? result) {
    return result == 'LIKE' || result == 'PASS' || result == 'SUPER_LIKE';
  }

  Future<void> _handleConnect(DiscoverProfile profile) async {
    try {
      final result = await _discoverService.swipe(
        targetUserId: profile.id,
        action: 'LIKE',
      );
      if (!mounted) return;
      // Test #3, #12: chỉ cần matched=true là match thật — chat đã được server
      // tạo sẵn trong cùng transaction. Nếu chưa có conversationId thì rơi về
      // match-confirm thay vì báo nhầm "đã gửi lượt thích".
      if (result.matched && result.matchId != null) {
        if (result.conversationId != null) {
          _showMatchModal(
            context,
            profile: profile,
            matchId: result.matchId!,
            chatId: result.conversationId!,
          );
        } else {
          await Navigator.of(
            context,
          ).pushNamed('/match-confirm', arguments: {'matchId': result.matchId});
        }
      } else {
        // Test #11: one-way like ⇒ chỉ báo đã gửi, KHÔNG bảo "đã kết nối".
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Đã gửi lượt thích. Khi cả hai cùng thích nhau, Bondy sẽ mở chat.',
            ),
          ),
        );
      }
      await _viewModel.loadFeed();
    } on QuotaExceededException {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => const LikeQuotaExceededDialog(),
      );
    } catch (e) {
      // Test #18: lỗi mạng / lỗi server ⇒ báo rõ ràng, KHÔNG báo đã like.
      if (!mounted) return;
      BondyFeedback.showError(context, e);
    }
  }

  Future<void> _handleSkip(DiscoverProfile profile) async {
    try {
      await _discoverService.swipe(targetUserId: profile.id, action: 'PASS');
      if (!mounted) return;
      await _viewModel.loadFeed();
    } catch (e) {
      if (!mounted) return;
      BondyFeedback.showError(context, e);
    }
  }

  void _showMatchModal(
    BuildContext context, {
    required DiscoverProfile profile,
    required String matchId,
    required String chatId,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.favorite, size: 56, color: BondyColors.primary),
              const SizedBox(height: 16),
              Text(
                'Co ket noi moi!',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: BondyColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ban va ${profile.name} da thich nhau. Chat da san sang.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  color: BondyColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  Navigator.of(context).pushNamed(
                    '/chat',
                    arguments: {
                      'chatId': chatId,
                      'matchId': matchId,
                      'otherUserId': profile.id,
                      'name': profile.name,
                      'photo': profile.imageUrl.isNotEmpty
                          ? profile.imageUrl
                          : null,
                      'chatAccepted': false,
                      'isInitiator': true,
                      'isMessageRequest': false,
                    },
                  );
                },
                child: const Text('Nhan tin ngay'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(
                  'De sau',
                  style: GoogleFonts.plusJakartaSans(
                    color: BondyColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===== PROFILE TAB =====
class _ProfileTab extends StatefulWidget {
  final ProfileService profileService;
  final VoidCallback? onNavigateToHome;

  const _ProfileTab({required this.profileService, this.onNavigateToHome});

  @override
  State<_ProfileTab> createState() => _ProfileTabState();

  static Widget _buildStat({
    required String value,
    required String label,
    required IconData icon,
    required Color bgColor,
    required Color accentColor,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        height: 94,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: accentColor, size: 18),
                const SizedBox(width: 6),
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: accentColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: BondyColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Icon(
        icon,
        color: BondyColors.textPrimary.withValues(alpha: 0.7),
        size: 20,
      ),
      title: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: BondyColors.textPrimary,
        ),
      ),
      trailing:
          trailing ??
          const Icon(
            Icons.chevron_right_rounded,
            color: BondyColors.textHint,
            size: 20,
          ),
      onTap: onTap,
    );
  }
}

class _ProfileTabState extends State<_ProfileTab> {
  UserProfileModel? _profile;
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  String? _errorMessage;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        widget.profileService.getProfile(),
        widget.profileService.getProfileStats(),
      ]);
      if (!mounted) return;
      setState(() {
        _profile = results[0] as UserProfileModel;
        _stats = results[1] as Map<String, dynamic>;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = BondyErrorMapper.message(error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    await _authService.logout();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/onboarding', (_) => false);
  }

  Future<void> _openEditProfile() async {
    final changed = await Navigator.of(context).pushNamed('/edit-profile');
    if (changed == true) {
      await _loadProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadProfile,
        color: BondyColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              _buildProfileHeader(),
              const SizedBox(height: 32),
              Row(
                children: [
                  _ProfileTab._buildStat(
                    value: '${_stats['streakDays'] ?? 0}',
                    label: 'Ngày streak',
                    icon: Icons.local_fire_department_rounded,
                    bgColor: const Color(0xFFFFF5F0), // Cam pastel nhạt
                    accentColor: const Color(0xFFF97316), // Cam đậm
                  ),
                  _ProfileTab._buildStat(
                    value: '${_stats['matchCount'] ?? 0}',
                    label: 'Kết nối',
                    icon: Icons.favorite_rounded,
                    bgColor: const Color(0xFFFFF0F5), // Hồng pastel nhạt
                    accentColor: const Color(0xFFEC4899), // Hồng đậm
                  ),
                  _ProfileTab._buildStat(
                    value: '${_stats['weeklyActivities'] ?? 0}',
                    label: 'Tuần này',
                    icon: Icons.check_circle_rounded,
                    bgColor: const Color(0xFFF5F3FF), // Tím pastel nhạt
                    accentColor: const Color(0xFF8B5CF6), // Tím đậm
                  ),
                ],
              ),
              const SizedBox(height: 32),
              if (_errorMessage != null) ...[
                BondyErrorBanner(
                  message: _errorMessage!,
                  onRetry: _loadProfile,
                ),
                const SizedBox(height: 16),
              ],

              // Nhóm 1: Cá nhân hóa & Premium
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _ProfileTab._buildMenuItem(
                      icon: Icons.favorite_outline_rounded,
                      label: 'Sở thích',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              const InterestsSetupScreen(fromProfile: true),
                        ),
                      ),
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Divider(
                        height: 1,
                        thickness: 0.5,
                        color: Color(0xFFF3F4F6),
                      ),
                    ),
                    _ProfileTab._buildMenuItem(
                      icon: Icons.star_outline_rounded,
                      label: 'Bondy Premium',
                      onTap: () =>
                          Navigator.of(context).pushNamed('/settings/premium'),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'PRO',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Nhóm 2: Bảo mật & Thiết lập
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _ProfileTab._buildMenuItem(
                      icon: Icons.lock_outline_rounded,
                      label: 'Đổi mật khẩu',
                      onTap: () => Navigator.of(
                        context,
                      ).pushNamed('/settings/change-password'),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Divider(
                        height: 1,
                        thickness: 0.5,
                        color: Color(0xFFF3F4F6),
                      ),
                    ),
                    _ProfileTab._buildMenuItem(
                      icon: Icons.shield_outlined,
                      label: 'Quyền riêng tư',
                      onTap: () =>
                          Navigator.of(context).pushNamed('/settings/privacy'),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Divider(
                        height: 1,
                        thickness: 0.5,
                        color: Color(0xFFF3F4F6),
                      ),
                    ),
                    _ProfileTab._buildMenuItem(
                      icon: Icons.notifications_outlined,
                      label: 'Thông báo',
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Nhóm 3: Hỗ trợ & Thông tin
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _ProfileTab._buildMenuItem(
                      icon: Icons.help_outline_rounded,
                      label: 'Trợ giúp',
                      onTap: () {},
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Divider(
                        height: 1,
                        thickness: 0.5,
                        color: Color(0xFFF3F4F6),
                      ),
                    ),
                    _ProfileTab._buildMenuItem(
                      icon: Icons.info_outline_rounded,
                      label: 'Về Bondy',
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Nút Đăng xuất Outlined Đỏ Pastel
              GestureDetector(
                onTap: _logout,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F2), // red-50
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFFECDD3), // red-200
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.logout_rounded,
                          color: BondyColors.error,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Đăng xuất',
                          style: GoogleFonts.plusJakartaSans(
                            color: BondyColors.error,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
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
      ),
    );
  }

  Widget _buildProfileHeader() {
    final profile = _profile;
    final displayName =
        profile?.displayName ??
        (_isLoading ? 'Đang tải...' : 'Người dùng Bondy');

    final detailsList = [
      if (profile != null && profile.email.isNotEmpty) profile.email,
      if (profile?.bio?.isNotEmpty == true) profile!.bio!,
      if (profile?.city?.isNotEmpty == true) profile!.city!,
    ];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(BondyRadius.lg), // 24.0
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Nút chỉnh sửa mờ ở góc trên bên phải
          Positioned(
            top: 16,
            right: 16,
            child: GestureDetector(
              onTap: _openEditProfile,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: BondyColors.background.withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.edit_rounded,
                  size: 18,
                  color: BondyColors.textSecondary,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              children: [
                _buildAvatar(profile, displayName),
                const SizedBox(height: 16),
                Text(
                  displayName,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: BondyColors.textPrimary,
                  ),
                ),
                if (detailsList.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    detailsList.join('  •  '),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      height: 1.4,
                      color: BondyColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                if (_isLoading) ...[
                  const SizedBox(height: 16),
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: BondyColors.primary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(UserProfileModel? profile, String displayName) {
    final avatarUrl =
        profile?.image ??
        (profile?.photos.isNotEmpty == true ? profile!.photos.first : null);

    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: BondyColors.primary.withValues(alpha: 0.15),
          width: 4,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: avatarUrl == null
            ? _avatarPlaceholder(displayName)
            : ClipOval(
                child: Image.network(
                  avatarUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _avatarPlaceholder(displayName),
                ),
              ),
      ),
    );
  }

  Widget _avatarPlaceholder(String displayName) {
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6366F1), // Indigo
            Color(0xFFEC4899), // Pink
          ],
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

/// Full-screen community feed (navigated from Home).
class CommunityFeedScreen extends StatelessWidget {
  const CommunityFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cộng đồng')),
      body: const _CommunityTab(),
    );
  }
}
