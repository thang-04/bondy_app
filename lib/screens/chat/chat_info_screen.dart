import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/api_client.dart';
import '../../services/relationship_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/bondy_feedback.dart';
import '../healing/healing_stitch_style.dart';

/// Trạng thái nút "Mời Tri kỷ" trên màn hình thông tin chat.
enum TriKyButtonState {
  /// Chưa ai mời — hiển thị nút "Mời Tri kỷ"
  idle,

  /// Người dùng hiện tại đã gửi lời mời — hiển thị "Đã gửi lời mời"
  waitingForPartner,

  /// Đối phương đã gửi lời mời cho mình — hiển thị "Chấp nhận / Từ chối"
  receivedInvite,

  /// Đã là Tri kỷ — hiển thị "Tri kỷ ❤️"
  active,
}

/// Màn hình thông tin chat: Hiển thị avatar, tên, nút mời Tri kỷ, v.v.
class ChatInfoScreen extends StatefulWidget {
  const ChatInfoScreen({super.key});

  @override
  State<ChatInfoScreen> createState() => _ChatInfoScreenState();
}

class _ChatInfoScreenState extends State<ChatInfoScreen>
    with SingleTickerProviderStateMixin {
  late final ApiClient _apiClient = ApiClient();
  late final RelationshipService _relationshipService =
      RelationshipService(apiClient: _apiClient);

  bool _isLoading = true;
  bool _isSubmitting = false;
  TriKyButtonState _triKyState = TriKyButtonState.idle;
  String? _errorMessage;

  // Dữ liệu profile đối phương
  String? _otherUserBio;
  int? _otherUserAge;
  String? _otherUserCity;
  String? _otherUserDatingGoal;
  double? _otherUserDistanceKm;

  // Dữ liệu route
  String? _matchId;
  String? _otherUserId;
  String _displayName = 'Bondy user';
  String? _photo;

  // Animation cho hiệu ứng shimmer
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _shimmerAnimation = CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _readRouteArgs();
    _fetchInviteStatus();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  void _readRouteArgs() {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      _matchId = args['matchId'] as String?;
      _otherUserId = args['otherUserId'] as String?;
      _displayName = (args['name'] as String?)?.trim().isNotEmpty == true
          ? args['name'] as String
          : _displayName;
      _photo = args['photo'] as String?;
    }
  }

  Future<void> _fetchInviteStatus() async {
    final matchId = _matchId;
    if (matchId == null) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _relationshipService.checkPendingInvite(matchId);

      if (!mounted) return;

      final relationship = result['relationship'] as Map<String, dynamic>?;
      final invitation = result['invitation'] as Map<String, dynamic>?;
      final profile = result['otherUserProfile'] as Map<String, dynamic>?;

      if (profile != null) {
        _otherUserBio = profile['bio'] as String?;
        _otherUserAge = (profile['age'] as num?)?.toInt();
        _otherUserCity = profile['city'] as String?;
        _otherUserDatingGoal = profile['datingGoal'] as String?;
        _otherUserDistanceKm = (profile['distanceKm'] as num?)?.toDouble();
      }

      if (relationship != null && relationship['status'] == 'ACTIVE') {
        _triKyState = TriKyButtonState.active;
      } else if (invitation != null) {
        final inviterId = invitation['inviterId']?.toString();
        if (inviterId == _otherUserId) {
          // Đối phương gửi lời mời cho mình
          _triKyState = TriKyButtonState.receivedInvite;
        } else {
          // Mình đã gửi lời mời
          _triKyState = TriKyButtonState.waitingForPartner;
        }
      } else {
        _triKyState = TriKyButtonState.idle;
      }
    } catch (e) {
      _errorMessage = 'Không thể tải trạng thái lời mời';
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendInvite() async {
    final matchId = _matchId;
    if (matchId == null || _isSubmitting) return;

    // Hiển thị dialog xác nhận trước khi gửi
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Text('💕', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Text(
              'Mời Tri kỷ',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Text(
          'Bạn muốn mời $_displayName trở thành Tri kỷ?\n\nĐây là mối quan hệ đặc biệt nhất trên Bondy.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            height: 1.5,
            color: BondyColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Huỷ',
              style: GoogleFonts.plusJakartaSans(
                color: BondyColors.textSecondary,
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: HealingStitchColors.coral,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Gửi lời mời',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isSubmitting = true);
    try {
      await _relationshipService.createInvite(matchId: matchId);
      if (!mounted) return;
      setState(() => _triKyState = TriKyButtonState.waitingForPartner);
      BondyFeedback.showSuccess(context, 'Đã gửi lời mời Tri kỷ! 💕');
    } catch (e) {
      if (!mounted) return;
      BondyFeedback.showError(context, e, fallback: 'Không gửi được lời mời');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _acceptInvite() async {
    final matchId = _matchId;
    if (matchId == null || _isSubmitting) return;

    setState(() => _isSubmitting = true);
    try {
      await _relationshipService.acceptByMatchId(matchId);
      if (!mounted) return;
      setState(() => _triKyState = TriKyButtonState.active);
      BondyFeedback.showSuccess(
        context,
        'Chúc mừng! Hai bạn đã trở thành Tri kỷ! 🎉',
      );
    } catch (e) {
      if (!mounted) return;
      BondyFeedback.showError(context, e, fallback: 'Không thể chấp nhận lời mời');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _declineInvite() async {
    final matchId = _matchId;
    if (matchId == null || _isSubmitting) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Từ chối lời mời?',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        content: Text(
          '$_displayName đã mời bạn trở thành Tri kỷ. Bạn chắc chắn muốn từ chối?',
          style: GoogleFonts.plusJakartaSans(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Huỷ'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Từ chối'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isSubmitting = true);
    try {
      await _relationshipService.declineInvite(matchId);
      if (!mounted) return;
      setState(() => _triKyState = TriKyButtonState.idle);
    } catch (e) {
      if (!mounted) return;
      BondyFeedback.showError(context, e, fallback: 'Không thể từ chối');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HealingStitchColors.warmBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const SizedBox(height: 12),
                          _buildAvatarSection(),
                          _buildProfileInfo(),
                          const SizedBox(height: 32),
                          _buildTriKyCard(),
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage!,
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.red,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              'Thông tin',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: HealingStitchColors.textMain,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: _triKyState == TriKyButtonState.active
                ? HealingStitchColors.warmGradient
                : null,
            border: _triKyState != TriKyButtonState.active
                ? Border.all(color: HealingStitchColors.border, width: 3)
                : null,
          ),
          padding: const EdgeInsets.all(3),
          child: CircleAvatar(
            radius: 46,
            backgroundColor: Colors.white,
            backgroundImage:
                (_photo != null && _photo!.startsWith('http'))
                    ? NetworkImage(_photo!)
                    : null,
            child: (_photo == null || !_photo!.startsWith('http'))
                ? Text(
                    _displayName.isEmpty
                        ? 'B'
                        : _displayName[0].toUpperCase(),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: HealingStitchColors.coral,
                    ),
                  )
                : null,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _displayName,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: HealingStitchColors.textMain,
          ),
        ),
        if (_triKyState == TriKyButtonState.active) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              gradient: HealingStitchColors.warmGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '💕 Tri kỷ',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTriKyCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [healingSoftShadow(0.06)],
        border: Border.all(color: HealingStitchColors.border),
      ),
      child: Column(
        children: [
          // Header icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: HealingStitchColors.paleCoral,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.favorite_rounded,
              color: HealingStitchColors.coral,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),

          // Tiêu đề
          Text(
            'Tri kỷ',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: HealingStitchColors.textMain,
            ),
          ),
          const SizedBox(height: 8),

          // Mô tả
          Text(
            _getDescription(),
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              height: 1.6,
              color: HealingStitchColors.textMuted,
            ),
          ),
          const SizedBox(height: 24),

          // Nút hành động theo trạng thái
          _buildActionButton(),
        ],
      ),
    );
  }

  String _getDescription() {
    switch (_triKyState) {
      case TriKyButtonState.idle:
        return 'Mối quan hệ đặc biệt nhất trên Bondy.\nCùng theo dõi hành trình yêu thương.';
      case TriKyButtonState.waitingForPartner:
        return 'Bạn đã gửi lời mời cho $_displayName.\nĐang chờ phản hồi...';
      case TriKyButtonState.receivedInvite:
        return '$_displayName muốn trở thành Tri kỷ của bạn!\nHãy phản hồi ngay nhé.';
      case TriKyButtonState.active:
        return 'Hai bạn đã chính thức là Tri kỷ! 🎉\nHãy cùng viết nên câu chuyện đẹp.';
    }
  }

  Widget _buildActionButton() {
    if (_isSubmitting) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: HealingStitchColors.coral,
        ),
      );
    }

    switch (_triKyState) {
      case TriKyButtonState.idle:
        return _buildGradientButton(
          label: 'Mời Tri kỷ 💕',
          onTap: _sendInvite,
        );

      case TriKyButtonState.waitingForPartner:
        return AnimatedBuilder(
          animation: _shimmerAnimation,
          builder: (context, child) {
            return Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: HealingStitchColors.paleCoral.withValues(
                  alpha: 0.6 + 0.4 * _shimmerAnimation.value,
                ),
                border: Border.all(
                  color: HealingStitchColors.coral.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: HealingStitchColors.coral.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Đã gửi lời mời',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: HealingStitchColors.coral,
                    ),
                  ),
                ],
              ),
            );
          },
        );

      case TriKyButtonState.receivedInvite:
        return Column(
          children: [
            _buildGradientButton(
              label: 'Chấp nhận 🎉',
              onTap: _acceptInvite,
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: _declineInvite,
                style: OutlinedButton.styleFrom(
                  foregroundColor: HealingStitchColors.textMuted,
                  side: const BorderSide(color: HealingStitchColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Từ chối',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        );

      case TriKyButtonState.active:
        return Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            gradient: HealingStitchColors.warmGradient,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [healingGlowShadow()],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.favorite, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                'Tri kỷ',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildGradientButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            gradient: HealingStitchColors.warmGradient,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [healingGlowShadow(HealingStitchColors.orange)],
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
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

  Widget _buildProfileInfo() {
    final String distanceLabel = _otherUserDistanceKm != null
        ? (_otherUserDistanceKm! % 1 == 0
            ? 'Cách bạn ${_otherUserDistanceKm!.toInt()} km'
            : 'Cách bạn ${_otherUserDistanceKm!.toStringAsFixed(1)} km')
        : '';

    final String locationText = [
      if (_otherUserAge != null && _otherUserAge! > 0) '$_otherUserAge tuổi',
      if (distanceLabel.isNotEmpty) distanceLabel,
      if (_otherUserCity != null && _otherUserCity!.isNotEmpty) _otherUserCity,
    ].join(' • ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (locationText.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            locationText,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: HealingStitchColors.textMuted,
            ),
          ),
        ],
        if (_otherUserDatingGoal != null && _otherUserDatingGoal!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F3FF), // Tím pastel
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.favorite_border_rounded,
                  color: Color(0xFF8B5CF6),
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  _getDatingGoalText(_otherUserDatingGoal),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF6D28D9),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (_otherUserBio != null && _otherUserBio!.trim().isNotEmpty) ...[
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [healingSoftShadow(0.04)],
              border: Border.all(color: HealingStitchColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.menu_book_rounded,
                      color: HealingStitchColors.coral,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Giới thiệu',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: HealingStitchColors.textMain,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _otherUserBio!,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: HealingStitchColors.textMuted,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
