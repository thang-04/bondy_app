import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/home/home_widget_model.dart';
import '../../models/user_profile_model.dart';
import '../../services/discover_service.dart';
import '../../services/healing/healing_service.dart';
import '../../services/profile_service.dart';
import '../../viewmodels/home/home_viewmodel.dart';
import '../../widgets/common/bondy_feedback.dart';
import '../healing/widgets/emotional_checkin_dialog.dart';

/// =============================================================================
/// Bondy Home Dashboard
/// =============================================================================
///
/// Replaces the legacy _HomeTab inside MainShellScreen. Visual design matches
/// `home_bondy.html` reference (warm cream palette, stacked Featured Card,
/// 3-cell Bento grid).
///
/// Logic kept intact:
///   - Pulls user profile for greeting + avatar
///   - Pulls home widgets (banner / suggestion / discovery) and renders them
///     as small ribbon cards above the bento (so server-driven content still
///     flows through this screen).
///   - Bento cells route to existing screens: /discover, /home/healing,
///     /relationship/home.
///   - Floating "Hỏi Bondy" → /chatbot.
///   - Healing-gate banner appears if the discover service says the user
///     hasn't checked in within 24h.
class HomeDashboardScreen extends StatefulWidget {
  final VoidCallback? onNavigateToHealing;
  final VoidCallback? onNavigateToMatches;
  final VoidCallback? onNavigateToProfile;

  const HomeDashboardScreen({
    super.key,
    this.onNavigateToHealing,
    this.onNavigateToMatches,
    this.onNavigateToProfile,
  });

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  late final HomeViewModel _homeViewModel;
  final ProfileService _profileService = ProfileService();
  final DiscoverService _discoverService = DiscoverService();

  UserProfileModel? _profile;
  bool _healingGateNeeded = false;
  bool _loadingProfile = true;

  @override
  void initState() {
    super.initState();
    _homeViewModel = HomeViewModel();
    _homeViewModel.loadAuthenticatedContent();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      final profile = await _profileService.getProfile();
      if (!mounted) return;
      setState(() => _profile = profile);
    } catch (_) {
      // Profile load is non-blocking; greeting falls back to default.
    } finally {
      if (mounted) setState(() => _loadingProfile = false);
    }

    // Surface healing gate so the user is nudged to check in before swiping.
    // Best-effort — never blocks the home render.
    try {
      final fetch = await _discoverService.fetchProfilesFull();
      final gate = fetch.healingGate;
      if (gate != null && gate['needsCheckin'] == true && mounted) {
        setState(() => _healingGateNeeded = true);
      }
    } catch (_) {
      // discover may fail (no candidates yet, network blip) — keep banner off.
    }
  }

  @override
  void dispose() {
    _homeViewModel.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await Future.wait([
      _homeViewModel.refreshAuthenticated(),
      _bootstrap(),
    ]);
  }

  Future<void> _showCheckinDialog() async {
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (dialogContext) => EmotionalCheckinDialog(
        onSubmit: (mood, intensity, note) async {
          await HealingService().checkIn(
            mood: mood,
            intensity: intensity,
            note: note.isNotEmpty ? note : null,
          );
          if (mounted) {
            setState(() => _healingGateNeeded = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Check-in thành công!')),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Palette.background,
      floatingActionButton: _AskBondyFab(
        onTap: () => Navigator.of(context).pushNamed('/chatbot'),
      ),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: _Palette.primary,
          onRefresh: _refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _HomeTopBar(
                  avatarUrl: _profile?.image ??
                      (_profile?.photos.isNotEmpty == true
                          ? _profile!.photos.first
                          : null),
                  displayName: _profile?.displayName,
                  onAvatarTap: widget.onNavigateToProfile,
                ),
              ),
              SliverToBoxAdapter(
                child: _Greeting(
                  name: _firstName(_profile?.displayName),
                  loading: _loadingProfile,
                ),
              ),
              if (_healingGateNeeded)
                SliverToBoxAdapter(
                  child: _HealingGateBanner(
                    onTap: _showCheckinDialog,
                    onDismiss: () => setState(() => _healingGateNeeded = false),
                  ),
                ),
              SliverToBoxAdapter(
                child: _FeaturedJourneyCard(
                  onStart: () => Navigator.of(context).pushNamed('/healing/daily'),
                ),
              ),
              SliverToBoxAdapter(
                child: _QuickDiscoveryBento(
                  onMatchTap: () => Navigator.of(context).pushNamed('/discover'),
                  onHealingTap: widget.onNavigateToHealing ??
                      () => Navigator.of(context).pushNamed('/home/healing'),
                  onRelationshipTap: () =>
                      Navigator.of(context).pushNamed('/relationship/home'),
                ),
              ),
              SliverToBoxAdapter(
                child: _ServerDrivenSection(viewModel: _homeViewModel),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 160)),
            ],
          ),
        ),
      ),
    );
  }

  String? _firstName(String? displayName) {
    if (displayName == null || displayName.trim().isEmpty) return null;
    final parts = displayName.trim().split(RegExp(r'\s+'));
    return parts.last; // Vietnamese name convention — last token = given name
  }
}

// =============================================================================
// Palette + soft helpers — mirrors the Tailwind config from home_bondy.html
// =============================================================================

class _Palette {
  static const background = Color(0xFFFFF9F5);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceContainer = Color(0xFFFFF1EB);
  static const surfaceContainerLow = Color(0xFFFFF5F2);
  static const surfaceContainerHigh = Color(0xFFFFEDE6);
  static const onSurface = Color(0xFF5D4E46);
  static const onSurfaceMuted = Color(0xFF9C8A82);
  static const primary = Color(0xFFFF7E5F);
  static const primaryDeep = Color(0xFF822D00);
  static const secondary = Color(0xFFE5989B);
  static const outlineVariant = Color(0xFFFFD9C0);

  static const gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF6B6B), Color(0xFFFFB28E)],
  );

  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: const Color(0xFF5D4E46).withValues(alpha: 0.08),
          blurRadius: 30,
          offset: const Offset(0, 10),
        ),
      ];

  static List<BoxShadow> get headerShadow => [
        BoxShadow(
          color: const Color(0xFFFFB28E).withValues(alpha: 0.15),
          blurRadius: 30,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get glow => [
        BoxShadow(
          color: const Color(0xFFFF7E5F).withValues(alpha: 0.25),
          blurRadius: 25,
          offset: const Offset(0, 8),
        ),
      ];
}

TextStyle _font({
  double size = 14,
  FontWeight weight = FontWeight.w500,
  Color color = _Palette.onSurface,
  double? height,
  double? letterSpacing,
}) {
  return GoogleFonts.plusJakartaSans(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );
}

// =============================================================================
// Sections
// =============================================================================

class _HomeTopBar extends StatelessWidget {
  final String? avatarUrl;
  final String? displayName;
  final VoidCallback? onAvatarTap;

  const _HomeTopBar({this.avatarUrl, this.displayName, this.onAvatarTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
      decoration: BoxDecoration(
        color: _Palette.background.withValues(alpha: 0.92),
        boxShadow: _Palette.headerShadow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.bubble_chart_rounded,
                  color: Color(0xFFFF6B6B), size: 28),
              const SizedBox(width: 8),
              ShaderMask(
                shaderCallback: (rect) => _Palette.gradient.createShader(rect),
                child: Text(
                  'Bondy',
                  style: _font(
                    size: 24,
                    weight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: onAvatarTap,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _Palette.outlineVariant, width: 2),
              ),
              clipBehavior: Clip.antiAlias,
              child: avatarUrl != null && avatarUrl!.startsWith('http')
                  ? Image.network(
                      avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          _avatarFallback(displayName),
                    )
                  : _avatarFallback(displayName),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarFallback(String? name) {
    final initial = (name == null || name.trim().isEmpty)
        ? 'B'
        : name.trim().substring(0, 1).toUpperCase();
    return Container(
      color: _Palette.surfaceContainerHigh,
      alignment: Alignment.center,
      child: Text(
        initial,
        style: _font(size: 16, weight: FontWeight.w800, color: _Palette.primary),
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  final String? name;
  final bool loading;

  const _Greeting({this.name, this.loading = false});

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Chào buổi sáng'
        : hour < 18
            ? 'Chào buổi chiều'
            : 'Chào buổi tối';

    final displayName = name?.trim().isNotEmpty == true ? ', ${name!.trim()}' : '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loading ? 'Đang tải...' : '$greeting$displayName 👋',
            style: _font(
              size: 28,
              weight: FontWeight.w800,
              color: _Palette.onSurface,
              height: 1.2,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Hôm nay bạn cảm thấy thế nào?',
            style: _font(
              size: 14,
              color: _Palette.onSurfaceMuted,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _HealingGateBanner extends StatelessWidget {
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _HealingGateBanner({required this.onTap, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            decoration: BoxDecoration(
              color: _Palette.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _Palette.outlineVariant.withValues(alpha: 0.6),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.spa_outlined,
                      color: _Palette.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Check-in cảm xúc hôm nay',
                          style: _font(
                              size: 14,
                              weight: FontWeight.w700,
                              color: _Palette.onSurface)),
                      const SizedBox(height: 2),
                      Text('Dành 2 phút trước khi kết nối người mới',
                          style: _font(
                              size: 11,
                              color: _Palette.onSurfaceMuted,
                              height: 1.4)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      size: 18, color: _Palette.onSurfaceMuted),
                  onPressed: onDismiss,
                  tooltip: 'Để sau',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Stacked "Recommended for you" card. Two ghost cards behind plus a fully
/// rendered foreground card.
class _FeaturedJourneyCard extends StatelessWidget {
  final VoidCallback onStart;

  const _FeaturedJourneyCard({required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: SizedBox(
        height: 460,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Ghost card 2 (furthest)
            Positioned.fill(
              top: 24,
              left: 22,
              right: 22,
              child: Container(
                decoration: BoxDecoration(
                  color: _Palette.surfaceContainerHigh.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
            ),
            // Ghost card 1
            Positioned.fill(
              top: 12,
              left: 12,
              right: 12,
              child: Container(
                decoration: BoxDecoration(
                  color: _Palette.surfaceContainer.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
            ),
            // Foreground card
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: _Palette.surface,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: _Palette.softShadow,
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 240,
                      width: double.infinity,
                      child: Stack(
                        children: [
                          // Decorative gradient placeholder (no asset dep)
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  const Color(0xFFFFD9C0),
                                  const Color(0xFFFFB28E)
                                      .withValues(alpha: 0.8),
                                ],
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.self_improvement_rounded,
                                size: 90,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 16,
                            left: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.95),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: Text(
                                'MINDFUL MODE',
                                style: _font(
                                  size: 10,
                                  weight: FontWeight.w800,
                                  color: _Palette.primary,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Đề xuất dành cho bạn',
                              style: _font(
                                  size: 20,
                                  weight: FontWeight.w700,
                                  color: _Palette.onSurface)),
                          const SizedBox(height: 8),
                          Text(
                            'Bắt đầu hành trình thấu hiểu bản thân và kết nối sâu sắc hơn với những người xung quanh.',
                            style: _font(
                              size: 14,
                              color: _Palette.onSurfaceMuted,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: Material(
                              borderRadius: BorderRadius.circular(28),
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: onStart,
                                borderRadius: BorderRadius.circular(28),
                                child: Ink(
                                  height: 54,
                                  decoration: BoxDecoration(
                                    gradient: _Palette.gradient,
                                    borderRadius: BorderRadius.circular(28),
                                    boxShadow: _Palette.glow,
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Bắt đầu hành trình',
                                      style: _font(
                                        size: 16,
                                        weight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
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
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickDiscoveryBento extends StatelessWidget {
  final VoidCallback onMatchTap;
  final VoidCallback onHealingTap;
  final VoidCallback onRelationshipTap;

  const _QuickDiscoveryBento({
    required this.onMatchTap,
    required this.onHealingTap,
    required this.onRelationshipTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Khám phá nhanh',
                  style: _font(
                      size: 18,
                      weight: FontWeight.w700,
                      color: _Palette.onSurface)),
              Text('XEM TẤT CẢ',
                  style: _font(
                      size: 11,
                      weight: FontWeight.w700,
                      color: _Palette.primary,
                      letterSpacing: 2)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _BentoCard(
                  icon: Icons.favorite_rounded,
                  iconColor: _Palette.primary,
                  title: 'Kết đôi',
                  subtitle: 'Tìm người phù hợp',
                  onTap: onMatchTap,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _BentoCard(
                  icon: Icons.self_improvement_rounded,
                  iconColor: _Palette.primaryDeep,
                  title: 'Chữa lành',
                  subtitle: 'Nuôi dưỡng tâm hồn',
                  onTap: onHealingTap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _BentoRowCard(
            icon: Icons.diversity_1_rounded,
            iconColor: _Palette.secondary,
            title: 'Mối quan hệ',
            subtitle: 'Xây dựng gắn kết bền vững',
            onTap: onRelationshipTap,
          ),
        ],
      ),
    );
  }
}

class _BentoCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _BentoCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _Palette.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: _Palette.outlineVariant.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(height: 12),
              Text(title,
                  style: _font(
                      size: 14,
                      weight: FontWeight.w700,
                      color: _Palette.onSurface)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style:
                      _font(size: 11, color: _Palette.onSurfaceMuted)),
            ],
          ),
        ),
      ),
    );
  }
}

class _BentoRowCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _BentoRowCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _Palette.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: _Palette.outlineVariant.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: _font(
                            size: 14,
                            weight: FontWeight.w700,
                            color: _Palette.onSurface)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style:
                            _font(size: 11, color: _Palette.onSurfaceMuted)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: _Palette.onSurfaceMuted.withValues(alpha: 0.4)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Renders the server-driven widget list (banner / suggestion / discovery)
/// underneath the bento as compact tiles. Keeps the home dynamic without
/// dominating the layout.
class _ServerDrivenSection extends StatelessWidget {
  final HomeViewModel viewModel;

  const _ServerDrivenSection({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final state = viewModel.state;

        if (state is HomeLoading) {
          return const SizedBox(
            height: 80,
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child:
                    CircularProgressIndicator(strokeWidth: 2, color: _Palette.primary),
              ),
            ),
          );
        }

        if (state is HomeError) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: BondyErrorBanner(
              message: state.message,
              onRetry: () => viewModel.refreshAuthenticated(),
            ),
          );
        }

        final widgets = (state as HomeLoaded).widgets;
        if (widgets.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Gợi ý hôm nay',
                  style: _font(
                      size: 18,
                      weight: FontWeight.w700,
                      color: _Palette.onSurface)),
              const SizedBox(height: 12),
              ...widgets.map((w) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ServerWidgetTile(widget: w),
                  )),
            ],
          ),
        );
      },
    );
  }
}

/// Compact ribbon for any server-driven home widget. Keeps the visual
/// language consistent regardless of widget type — title + description +
/// CTA route.
class _ServerWidgetTile extends StatelessWidget {
  final HomeWidget widget;

  const _ServerWidgetTile({required this.widget});

  @override
  Widget build(BuildContext context) {
    final accent = _accentForType(widget.widgetType);
    final title = (widget.data['title'] ?? widget.data['headline'] ?? '')
        .toString();
    final subtitle = (widget.data['subtitle'] ??
            widget.data['description'] ??
            widget.data['body'] ??
            '')
        .toString();

    if (title.isEmpty && subtitle.isEmpty) {
      return const SizedBox.shrink();
    }

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => _route(context),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _Palette.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: _Palette.outlineVariant.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.$2,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(accent.$1, color: accent.$3, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title.isNotEmpty)
                      Text(title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _font(
                              size: 14,
                              weight: FontWeight.w700,
                              color: _Palette.onSurface)),
                    if (subtitle.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: _font(
                                size: 12,
                                color: _Palette.onSurfaceMuted,
                                height: 1.4)),
                      ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: _Palette.onSurfaceMuted.withValues(alpha: 0.4)),
            ],
          ),
        ),
      ),
    );
  }

  (IconData, Color, Color) _accentForType(String type) {
    switch (type) {
      case 'BANNER':
        return (
          Icons.campaign_rounded,
          _Palette.primary.withValues(alpha: 0.12),
          _Palette.primary,
        );
      case 'EMOTION_CHECKIN':
        return (
          Icons.favorite_border_rounded,
          _Palette.secondary.withValues(alpha: 0.18),
          _Palette.secondary,
        );
      case 'MILESTONE_REMINDER':
        return (
          Icons.emoji_events_rounded,
          const Color(0xFFFFE9C7),
          const Color(0xFFD68C18),
        );
      case 'DISCOVERY_CARD':
        return (
          Icons.travel_explore_rounded,
          _Palette.outlineVariant.withValues(alpha: 0.5),
          _Palette.primaryDeep,
        );
      case 'SUGGESTION_CARD':
      default:
        return (
          Icons.lightbulb_outline_rounded,
          _Palette.surfaceContainerHigh,
          _Palette.primary,
        );
    }
  }

  void _route(BuildContext context) {
    final action = (widget.data['action'] ?? '').toString();
    final route = (widget.data['route'] ?? '').toString();

    if (route.isNotEmpty) {
      Navigator.of(context).pushNamed(route);
      return;
    }
    switch (action) {
      case 'COMPLETE_SURVEY':
        Navigator.of(context).pushNamed('/survey/intro');
        break;
      case 'EMOTION_CHECKIN':
      case 'HEALING_CHECKIN':
        Navigator.of(context).pushNamed('/healing/daily');
        break;
      case 'OPEN_DISCOVER':
        Navigator.of(context).pushNamed('/discover');
        break;
      case 'OPEN_RELATIONSHIP':
        Navigator.of(context).pushNamed('/relationship/home');
        break;
      default:
        Navigator.of(context).pushNamed('/home/healing');
    }
  }
}

class _AskBondyFab extends StatelessWidget {
  final VoidCallback onTap;

  const _AskBondyFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 60),
      child: Material(
        color: Colors.transparent,
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                  color: _Palette.outlineVariant.withValues(alpha: 0.5)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFB28E).withValues(alpha: 0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.chat_bubble_rounded,
                    color: _Palette.primary, size: 20),
                const SizedBox(width: 8),
                Text('Hỏi Bondy',
                    style: _font(
                        size: 14,
                        weight: FontWeight.w700,
                        color: _Palette.onSurface)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
