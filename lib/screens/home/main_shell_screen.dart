import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/user_profile_model.dart';
import '../../services/profile_service.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/home/home_viewmodel.dart';
import '../../widgets/home/banner_widget.dart';
import '../../widgets/home/suggestion_card_widget.dart';
import '../../widgets/home/emotion_checkin_widget.dart';
import '../../widgets/home/milestone_reminder_widget.dart';
import '../../widgets/home/discovery_card_widget.dart';

class MainShellScreen extends StatefulWidget {
  final ProfileService? profileService;

  const MainShellScreen({super.key, this.profileService});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _currentIndex = 0;
  late final ProfileService _profileService;

  @override
  void initState() {
    super.initState();
    _profileService = widget.profileService ?? ProfileService();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const _HomeTab(),
          const _HealingTab(),
          const _CommunityTab(),
          _ProfileTab(profileService: _profileService),
        ],
      ),
      extendBody: true,
      bottomNavigationBar: Container(
        height: 90,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16, top: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Home
              _buildNavItem(0, Icons.home_outlined, Icons.home, 'Home'),
              // Healing
              _buildNavItem(
                1,
                Icons.self_improvement_outlined,
                Icons.self_improvement,
                'Healing',
              ),
              // MATCH (floating center)
              _buildMatchButton(context),
              // Matches (with badge)
              _buildNavItemWithBadge(
                2,
                Icons.chat_bubble_outline,
                Icons.chat_bubble,
                'Matches',
              ),
              // Profile
              _buildNavItem(3, Icons.person_outline, Icons.person, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    IconData activeIcon,
    String label,
  ) {
    final isActive = _currentIndex == index;
    final color = isActive ? const Color(0xFFFF5864) : const Color(0xFF9CA3AF);
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isActive ? activeIcon : icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItemWithBadge(
    int index,
    IconData icon,
    IconData activeIcon,
    String label,
  ) {
    final isActive = _currentIndex == index;
    final color = isActive ? const Color(0xFFFF5864) : const Color(0xFF9CA3AF);
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(isActive ? activeIcon : icon, color: color, size: 24),
                Positioned(
                  top: -1,
                  right: -3,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF5864),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed('/discover'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform.translate(
            offset: const Offset(0, -14),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFFF5864),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF5864).withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(Icons.favorite, color: Colors.white, size: 26),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -12),
            child: Text(
              'MATCH',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFEB5757),
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===== HOME TAB =====
class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  late final HomeViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = HomeViewModel();
    _viewModel.loadAuthenticatedContent();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F6),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).pushNamed('/chatbot'),
        backgroundColor: const Color(0xFFFF4D6D),
        icon: const Icon(Icons.chat_bubble, color: Colors.white, size: 20),
        label: Text(
          'Hỏi Bondy',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header (cố định, không cuộn) ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFF8A65), Color(0xFFE91E63)],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bondy',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Chào buổi sáng 👋',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                  const CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: Color(0xFFFFE0CC),
                      child: Text('👤', style: TextStyle(fontSize: 22)),
                    ),
                  ),
                ],
              ),
            ),

            // ── Dynamic widget list ──
            Expanded(
              child: ListenableBuilder(
                listenable: _viewModel,
                builder: (context, _) {
                  final state = _viewModel.state;

                  if (state is HomeLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFFF4D6D),
                      ),
                    );
                  }

                  if (state is HomeError) {
                    return RefreshIndicator(
                      color: const Color(0xFFFF4D6D),
                      onRefresh: () => _viewModel.refreshAuthenticated(),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            children: [
                              const Text('😕', style: TextStyle(fontSize: 48)),
                              const SizedBox(height: 16),
                              Text(
                                state.message,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  color: const Color(0xFF6B7280),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Kéo xuống để thử lại',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: const Color(0xFF9CA3AF),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  // HomeLoaded
                  final widgets = (state as HomeLoaded).widgets;
                  return RefreshIndicator(
                    color: const Color(0xFFFF4D6D),
                    onRefresh: () => _viewModel.refreshAuthenticated(),
                    child: ListView.builder(
                      padding: const EdgeInsets.only(top: 16, bottom: 100),
                      itemCount: widgets.length,
                      itemBuilder: (context, index) {
                        final w = widgets[index];
                        return switch (w.widgetType) {
                          'BANNER' => BannerWidget(data: w.data),
                          'EMOTION_CHECKIN' => EmotionCheckinWidget(
                            data: w.data,
                          ),
                          'MILESTONE_REMINDER' => MilestoneReminderWidget(
                            data: w.data,
                          ),
                          'DISCOVERY_CARD' => DiscoveryCardWidget(data: w.data),
                          'SUGGESTION_CARD' => SuggestionCardWidget(
                            data: w.data,
                          ),
                          _ => const SizedBox.shrink(), // unknown type — bỏ qua
                        };
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===== HEALING TAB =====
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
class _CommunityTab extends StatelessWidget {
  const _CommunityTab();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Khám phá',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: BondyColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tìm người đồng điệu với bạn',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: BondyColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            // Discovery cards
            ...List.generate(3, (index) {
              final profiles = [
                {'name': 'Minh Anh', 'age': '25', 'emoji': '🌸', 'match': '85'},
                {
                  'name': 'Hoàng Long',
                  'age': '27',
                  'emoji': '🌿',
                  'match': '78',
                },
                {'name': 'Thu Hà', 'age': '23', 'emoji': '🌻', 'match': '92'},
              ];
              final p = profiles[index];
              return GestureDetector(
                onTap: () => Navigator.of(context).pushNamed('/profile-detail'),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: BondyColors.primaryLight,
                            child: Text(
                              p['emoji']!,
                              style: const TextStyle(fontSize: 28),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${p['name']}, ${p['age']}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.favorite,
                                      size: 14,
                                      color: BondyColors.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${p['match']}% đồng điệu',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        color: BondyColors.primary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {},
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 44),
                              ),
                              child: const Text('Bỏ qua'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                _showMatchModal(context, p['name']!);
                              },
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(0, 44),
                              ),
                              child: const Text('Kết nối'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showMatchModal(BuildContext context, String name) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 16),
              Text(
                'Chúc mừng!',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: BondyColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Bạn và $name đã kết nối!',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  color: BondyColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.of(context).pushNamed('/chat');
                },
                child: const Text('Gửi tin nhắn'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Để sau',
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

  const _ProfileTab({required this.profileService});

  @override
  State<_ProfileTab> createState() => _ProfileTabState();

  static Widget _buildStat(String value, String label) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: BondyColors.primaryLight,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: BondyColors.primary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: BondyColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildMenuItem(
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        leading: Icon(icon, color: BondyColors.textPrimary),
        title: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: BondyColors.textHint),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        onTap: onTap,
      ),
    );
  }
}

class _ProfileTabState extends State<_ProfileTab> {
  UserProfileModel? _profile;
  bool _isLoading = true;
  String? _errorMessage;

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
      final profile = await widget.profileService.getProfile();
      if (!mounted) return;
      setState(() => _profile = profile);
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
                  _ProfileTab._buildStat('3', 'Ngày streak'),
                  _ProfileTab._buildStat('1', 'Kết nối'),
                  _ProfileTab._buildStat('5', 'Hoạt động'),
                ],
              ),
              const SizedBox(height: 32),
              if (_errorMessage != null) _buildErrorCard(),
              _ProfileTab._buildMenuItem(
                Icons.person_outline,
                'Chỉnh sửa hồ sơ',
                _openEditProfile,
              ),
              _ProfileTab._buildMenuItem(Icons.favorite_outline, 'Sở thích', () {}),
              _ProfileTab._buildMenuItem(
                Icons.favorite_outline,
                'Mối quan hệ của tôi',
                () => Navigator.of(context).pushNamed('/relationship/home'),
              ),
              _ProfileTab._buildMenuItem(
                Icons.star_outline,
                'Bondy Premium',
                () => Navigator.of(context).pushNamed('/settings/premium'),
              ),
              _ProfileTab._buildMenuItem(
                Icons.lock_outline,
                'Đổi mật khẩu',
                () => Navigator.of(context).pushNamed('/settings/change-password'),
              ),
              _ProfileTab._buildMenuItem(Icons.shield_outlined, 'Quyền riêng tư', () {}),
              _ProfileTab._buildMenuItem(Icons.notifications_outlined, 'Thông báo', () {}),
              _ProfileTab._buildMenuItem(Icons.help_outline, 'Trợ giúp', () {}),
              _ProfileTab._buildMenuItem(Icons.info_outline, 'Về Bondy', () {}),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () {},
                child: Text(
                  'Đăng xuất',
                  style: GoogleFonts.plusJakartaSans(
                    color: BondyColors.error,
                    fontWeight: FontWeight.w600,
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
        profile?.displayName ?? (_isLoading ? 'Đang tải...' : 'Người dùng Bondy');
    final subtitle = profile == null
        ? (_isLoading ? 'Đang tải thông tin tài khoản' : 'Kéo xuống để tải lại hồ sơ')
        : [
            if (profile.email.isNotEmpty) profile.email,
            if (profile.bio?.isNotEmpty == true) profile.bio!,
            if (profile.city?.isNotEmpty == true) profile.city!,
          ].join('\n');

    return Column(
      children: [
        _buildAvatar(profile, displayName),
        const SizedBox(height: 12),
        Text(
          displayName,
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: BondyColors.textSecondary,
          ),
        ),
        if (_isLoading) ...[
          const SizedBox(height: 16),
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ],
      ],
    );
  }

  Widget _buildAvatar(UserProfileModel? profile, String displayName) {
    final avatarUrl = profile?.image ??
        (profile?.photos.isNotEmpty == true ? profile!.photos.first : null);

    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: BondyColors.primaryLight,
        shape: BoxShape.circle,
        border: Border.all(color: BondyColors.primary, width: 3),
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
    );
  }

  Widget _avatarPlaceholder(String displayName) {
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
    return Center(
      child: Text(
        initial,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 34,
          fontWeight: FontWeight.w700,
          color: BondyColors.primary,
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: BondyColors.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Không thể tải hồ sơ. Kéo xuống để thử lại.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: BondyColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
