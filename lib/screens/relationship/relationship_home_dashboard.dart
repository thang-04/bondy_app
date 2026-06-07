import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../healing/healing_stitch_style.dart';
import '../../services/auth_service.dart';
import '../../services/relationship_service.dart';
import '../../viewmodels/relationship/relationship_viewmodel.dart';
import '../../widgets/common/bondy_feedback.dart';

class RelationshipHomeDashboard extends StatefulWidget {
  final RelationshipViewModel? viewModel;

  const RelationshipHomeDashboard({super.key, this.viewModel});

  @override
  State<RelationshipHomeDashboard> createState() =>
      _RelationshipHomeDashboardState();
}

class _RelationshipHomeDashboardState extends State<RelationshipHomeDashboard> {
  late final RelationshipViewModel _viewModel;
  final AuthService _authService = AuthService();

  String _myDisplayName = 'Bạn';
  String? _myPhotoUrl;

  @override
  void initState() {
    super.initState();
    _viewModel = widget.viewModel ?? RelationshipViewModel();
    _loadInitialRelationshipData();
    _loadMyProfile();
  }

  Future<void> _loadInitialRelationshipData() async {
    if (_viewModel.dashboard == null) {
      await _viewModel.loadDashboard();
    }
    if (!mounted || !_viewModel.hasActiveRelationship) return;
    await _viewModel.loadDailyAction();
  }

  Future<void> _loadMyProfile() async {
    try {
      final user = await _authService.getCurrentUser();
      if (mounted) {
        setState(() {
          _myDisplayName = user['name']?.toString() ?? 'Bạn';
          _myPhotoUrl =
              user['image']?.toString() ?? user['photoUrl']?.toString();
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    if (widget.viewModel == null) {
      _viewModel.dispose();
    }
    super.dispose();
  }

  String getEmoji(String mood) {
    if (mood.isEmpty) return '😄';
    return mood.split(' ').first;
  }

  String getLabel(String mood) {
    if (mood.isEmpty) return 'Bình thường';
    final parts = mood.split(' ');
    if (parts.length > 1) {
      return parts.sublist(1).join(' ');
    }
    return mood;
  }

  String _initialFor(String? value) {
    final clean = (value ?? '').trim();
    if (clean.isEmpty) return '?';
    return clean.substring(0, 1).toUpperCase();
  }

  String _partnerName(RelationshipDashboard dash) {
    final name = dash.partnerName?.trim();
    if (name == null || name.isEmpty) return 'người ấy';
    return name;
  }

  DateTime _nextReminderAt() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + 1, 9);
  }

  Future<void> _remindDailyAction() async {
    try {
      await _viewModel.setDailyActionState(
        status: RelationshipDailyActionStatus.reminded,
        remindAt: _nextReminderAt(),
      );
      if (!mounted) return;
      BondyFeedback.showSuccess(context, 'Đã lưu lời nhắc');
    } catch (e) {
      if (!mounted) return;
      BondyFeedback.showError(context, e);
    }
  }

  Future<void> _skipDailyAction() async {
    try {
      await _viewModel.setDailyActionState(
        status: RelationshipDailyActionStatus.skipped,
      );
    } catch (e) {
      if (!mounted) return;
      BondyFeedback.showError(context, e);
    }
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
              child: CircularProgressIndicator(
                color: HealingStitchColors.coral,
              ),
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
                    const SizedBox(height: 20),
                    Text(
                      'Của chúng mình',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: HealingStitchColors.textMain,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Mời người yêu tham gia Bondy để cùng check-in cảm xúc, ghi nhận cột mốc kỷ niệm và giải quyết mâu thuẫn một cách lành mạnh.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        color: HealingStitchColors.textSoft,
                        height: 1.6,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: HealingStitchColors.warmGradient,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: HealingStitchColors.coral.withValues(
                              alpha: 0.25,
                            ),
                            blurRadius: 15,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(
                          context,
                        ).pushNamed('/relationship/invite'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Mời người ấy',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: HealingStitchColors.creamBackground,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Bento
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          _buildHeaderAvatars(dash),
                          const SizedBox(width: 12),
                          _buildStreakBadge(dash),
                        ],
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: HealingStitchColors.border),
                          boxShadow: [healingSoftShadow(0.04)],
                        ),
                        child: Stack(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.of(
                                context,
                              ).pushNamed('/relationship/milestones'),
                              icon: const Icon(
                                Icons.notifications_none_outlined,
                                color: HealingStitchColors.textMain,
                              ),
                            ),
                            Positioned(
                              top: 12,
                              right: 12,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Chào buổi sáng
                  Text(
                    'Chào buổi sáng,\n$_myDisplayName & ${_partnerName(dash)} 👋',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: HealingStitchColors.textMain,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Bento Card 1: Hành động nhỏ hôm nay
                  _buildDailyActionCard(context),
                  const SizedBox(height: 24),

                  // Bento Card 2: Cảm xúc của chúng mình
                  _buildEmotionsBento(dash),
                  const SizedBox(height: 24),

                  // Bento Grid Menu (2 nút song song)
                  Row(
                    children: [
                      Expanded(
                        child: _buildMenuButton(
                          title: 'Dòng thời gian',
                          subtitle: 'Kỷ niệm 2 ngày trước',
                          color: const Color(0xFFFFFFF4),
                          accentColor: const Color(0xFFFFF4E6),
                          iconColor: Colors.orange,
                          icon: Icons.photo_library_outlined,
                          bgIcon: Icons.history_edu,
                          buttonKey: const Key('relationship_timeline_button'),
                          onTap: () => Navigator.of(
                            context,
                          ).pushNamed('/relationship/timeline'),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _buildMenuButton(
                          title: 'Gỡ rối',
                          subtitle: 'Cùng lắng nghe nhau',
                          color: const Color(0xFFF0FDFC),
                          accentColor: const Color(0xFFE0F2F1),
                          iconColor: Colors.teal.shade600,
                          icon: Icons.favorite_border,
                          bgIcon: Icons.handshake_outlined,
                          onTap: () => Navigator.of(
                            context,
                          ).pushNamed('/relationship/conflict-tool'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Bento Card 3: Sự kiện tiếp theo
                  _buildNextEventCard(dash),
                  const SizedBox(height: 24),

                  // Bento Card 4: Bondy Coach
                  _buildCoachCard(context),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderAvatars(RelationshipDashboard dash) {
    final myPhoto = _myPhotoUrl;
    final partnerPhoto = dash.partnerPhotoUrl;

    return SizedBox(
      width: 76,
      height: 48,
      child: Stack(
        children: [
          _buildAvatar(
            photoUrl: myPhoto,
            label: _myDisplayName,
            backgroundColor: HealingStitchColors.paleCoral,
          ),
          Positioned(
            left: 24,
            child: _buildAvatar(
              photoUrl: partnerPhoto,
              label: _partnerName(dash),
              backgroundColor: const Color(0xFFFFF4E6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar({
    required String? photoUrl,
    required String label,
    required Color backgroundColor,
  }) {
    final hasRemotePhoto = photoUrl != null && photoUrl.startsWith('http');
    return CircleAvatar(
      radius: 22,
      backgroundColor: Colors.white,
      child: CircleAvatar(
        radius: 20,
        backgroundColor: backgroundColor,
        backgroundImage: hasRemotePhoto ? NetworkImage(photoUrl) : null,
        child: hasRemotePhoto
            ? null
            : Text(
                _initialFor(label),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: HealingStitchColors.textMain,
                ),
              ),
      ),
    );
  }

  Widget _buildStreakBadge(RelationshipDashboard dash) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: HealingStitchColors.border),
        boxShadow: [healingSoftShadow(0.04)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_fire_department,
            color: Colors.orange,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            '${dash.daysTogether} ngày',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: const Color(0xFFE64A19),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyActionCard(BuildContext context) {
    final action = _viewModel.dailyAction;
    if (action?.status == RelationshipDailyActionStatus.skipped) {
      return const SizedBox.shrink();
    }
    final isReminded = action?.status == RelationshipDailyActionStatus.reminded;

    return Container(
      key: const Key('relationship_daily_action_card'),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: HealingStitchColors.border),
        boxShadow: [healingSoftShadow(0.06)],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [HealingStitchColors.coral, Color(0xFFFFB199)],
                  ),
                ),
              ),
              Positioned(
                right: 18,
                top: 18,
                child: Icon(
                  Icons.favorite,
                  size: 84,
                  color: Colors.white.withValues(alpha: 0.18),
                ),
              ),
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.wb_sunny_outlined,
                            color: Colors.white,
                            size: 13,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Hành động nhỏ hôm nay',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      action?.title ?? 'Gửi một lời cảm ơn chân thành',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  action?.description ??
                      'Một lời cảm ơn nhỏ bé có thể thắp sáng cả một ngày dài. Hãy nghĩ về điều gì đó đối phương đã làm gần đây nhé.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: HealingStitchColors.textSoft,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: HealingStitchColors.warmGradient,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: HealingStitchColors.coral.withValues(
                                alpha: 0.2,
                              ),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(
                              context,
                            ).pushNamed('/relationship/checkin');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.check_circle_outline,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Thực hiện',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        key: const Key('relationship_daily_remind_button'),
                        onPressed: isReminded ? null : _remindDailyAction,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          isReminded ? 'Đã hẹn nhắc' : 'Nhắc tôi',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: HealingStitchColors.textMain,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      key: const Key('relationship_daily_skip_button'),
                      onPressed: _skipDailyAction,
                      child: Text(
                        'Để sau',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: HealingStitchColors.textSoft,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmotionsBento(RelationshipDashboard dash) {
    CoupleCheckinEntry? myCheckin;
    CoupleCheckinEntry? partnerCheckin;

    for (final c in dash.recentCheckins) {
      if (c.isMine && myCheckin == null) myCheckin = c;
      if (!c.isMine && partnerCheckin == null) partnerCheckin = c;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Cảm xúc của chúng mình',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: HealingStitchColors.textMain,
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.of(context).pushNamed(
                '/relationship/timeline',
                arguments: {'filter': 'CHECKIN'},
              ),
              child: Row(
                children: [
                  Text(
                    'Lịch sử',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFFF6B6B),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: Color(0xFFFF6B6B),
                    size: 16,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: HealingStitchColors.border),
                  boxShadow: [healingSoftShadow(0.03)],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFF5F5),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        myCheckin != null ? getEmoji(myCheckin.mood) : '😄',
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bạn',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: HealingStitchColors.textMuted,
                            ),
                          ),
                          Text(
                            myCheckin != null
                                ? getLabel(myCheckin.mood)
                                : 'Vui vẻ',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: HealingStitchColors.textMain,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: HealingStitchColors.border),
                  boxShadow: [healingSoftShadow(0.03)],
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFFAF2),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            partnerCheckin != null
                                ? getEmoji(partnerCheckin.mood)
                                : '😌',
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _partnerName(dash),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: HealingStitchColors.textMuted,
                                ),
                              ),
                              Text(
                                partnerCheckin != null
                                    ? getLabel(partnerCheckin.mood)
                                    : 'Bình yên',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: HealingStitchColors.textMain,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF06292),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMenuButton({
    required String title,
    required String subtitle,
    required Color color,
    required Color accentColor,
    required Color iconColor,
    required IconData icon,
    required IconData bgIcon,
    required VoidCallback onTap,
    Key? buttonKey,
  }) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        key: buttonKey,
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: 126,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: HealingStitchColors.border),
            boxShadow: [healingSoftShadow(0.02)],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -24,
                top: -24,
                child: Icon(
                  bgIcon,
                  size: 90,
                  color: iconColor.withValues(alpha: 0.08),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [healingSoftShadow(0.02)],
                    ),
                    alignment: Alignment.center,
                    child: Icon(icon, color: iconColor, size: 20),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: HealingStitchColors.textMain,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: HealingStitchColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _weekdayLabel(DateTime date) {
    switch (date.weekday) {
      case DateTime.monday:
        return 'Thứ 2';
      case DateTime.tuesday:
        return 'Thứ 3';
      case DateTime.wednesday:
        return 'Thứ 4';
      case DateTime.thursday:
        return 'Thứ 5';
      case DateTime.friday:
        return 'Thứ 6';
      case DateTime.saturday:
        return 'Thứ 7';
      case DateTime.sunday:
      default:
        return 'CN';
    }
  }

  String _milestoneSubtitle(DateTime? date) {
    if (date == null) {
      return 'Lưu ngày hẹn, kỷ niệm hoặc dịp đặc biệt';
    }
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute • ${date.day}/${date.month}/${date.year}';
  }

  Widget _buildNextEventCard(RelationshipDashboard dash) {
    final nextDate = dash.nextMilestoneDate;
    final title = dash.nextMilestoneTitle ?? 'Thêm cột mốc tiếp theo';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: HealingStitchColors.border),
        boxShadow: [healingSoftShadow(0.04)],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: HealingStitchColors.border),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  nextDate == null ? '--' : _weekdayLabel(nextDate),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.red,
                  ),
                ),
                Text(
                  nextDate == null ? '+' : nextDate.day.toString(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: HealingStitchColors.textMain,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: HealingStitchColors.textMain,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.schedule,
                      size: 14,
                      color: HealingStitchColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _milestoneSubtitle(nextDate),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: HealingStitchColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () =>
                Navigator.of(context).pushNamed('/relationship/milestones'),
            icon: const Icon(
              Icons.chevron_right,
              color: HealingStitchColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoachCard(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: HealingStitchColors.warmGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: HealingStitchColors.coral.withValues(alpha: 0.2),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.psychology_alt,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Bondy Coach',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Mẹo hay',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Lắng nghe chủ động giúp tăng sự thấu hiểu và giảm mâu thuẫn tới 50%.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.9),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () =>
                          Navigator.of(context).pushNamed('/chatbot'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: HealingStitchColors.coral,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Tìm hiểu thêm',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward, size: 14),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
