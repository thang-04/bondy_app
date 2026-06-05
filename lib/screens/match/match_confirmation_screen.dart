import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';

import '../../theme/app_theme.dart';
import '../../viewmodels/match/match_confirmation_viewmodel.dart';
import '../../widgets/match/compatibility_receipt_modal.dart';
import '../../services/auth_service.dart';

class MatchConfirmationScreen extends StatefulWidget {
  final String matchId;

  const MatchConfirmationScreen({super.key, required this.matchId});

  @override
  State<MatchConfirmationScreen> createState() =>
      _MatchConfirmationScreenState();
}

class _MatchConfirmationScreenState extends State<MatchConfirmationScreen>
    with SingleTickerProviderStateMixin {
  late final MatchConfirmationViewModel _viewModel;
  bool _receiptShown = false;
  late final ConfettiController _confettiController;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  String? _currentUserPhoto;
  String? _currentUserName;

  @override
  void initState() {
    super.initState();
    _viewModel = MatchConfirmationViewModel(matchId: widget.matchId);
    _viewModel.addListener(_onViewModelChange);
    _viewModel.loadMatchStatus();

    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.2, end: 0.6).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Fetch current user photo
    AuthService().getCurrentUser().then((user) {
      if (mounted) {
        setState(() {
          _currentUserName = user['name'] ?? 'Bạn';
          _currentUserPhoto = user['profile']?['photos']?[0] ?? user['image'];
        });
      }
    }).catchError((_) {});
  }

  void _onViewModelChange() {
    if (_viewModel.status == MatchConfirmationStatus.confirmed &&
        !_receiptShown) {
      _receiptShown = true;
      _confettiController.play();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showReceiptModal();
      });
    }
  }

  void _showReceiptModal() {
    final chatId = _viewModel.chatId;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: CompatibilityReceiptModal(
          otherUserName: _viewModel.otherUserName ?? 'Người kia',
          otherUserPhoto: _viewModel.otherUserPhoto,
          compatibilityScore: 75,
          factors: const [
            {'type': 'personality', 'score': 80},
            {'type': 'interests', 'score': 70},
            {'type': 'healing_readiness', 'score': 75},
          ],
          onOpenChat: () {
            Navigator.of(context).pop();
            if (chatId != null) _navigateToChat(chatId);
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _pulseController.dispose();
    _viewModel.removeListener(_onViewModelChange);
    _viewModel.dispose();
    super.dispose();
  }

  void _navigateToChat(String chatId) {
    Navigator.of(context).pushNamed(
      '/chat',
      arguments: {
        'chatId': chatId,
        'matchId': widget.matchId,
        'otherUserId': _viewModel.otherUserId,
        'name': _viewModel.otherUserName,
        'photo': _viewModel.otherUserPhoto,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFF9F5), Color(0xFFFFE8F0)],
          ),
        ),
        child: SafeArea(
          child: ListenableBuilder(
            listenable: _viewModel,
            builder: (context, _) {
              if (_viewModel.isLoading &&
                  _viewModel.status == MatchConfirmationStatus.pending) {
                return const Center(
                  child: CircularProgressIndicator(color: BondyColors.primary),
                );
              }

              if (_viewModel.errorMessage != null &&
                  _viewModel.status == MatchConfirmationStatus.pending) {
                return _buildErrorState();
              }

              return Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const Spacer(),
                        _buildAvatarPair(),
                        const SizedBox(height: 40),
                        _buildStatusContent(),
                        const Spacer(),
                        _buildBottomAction(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                  Align(
                    alignment: Alignment.topCenter,
                    child: ConfettiWidget(
                      confettiController: _confettiController,
                      blastDirectionality: BlastDirectionality.explosive,
                      shouldLoop: false,
                      colors: const [
                        Color(0xFFFF4B8B),
                        Color(0xFFFF8A6C),
                        Color(0xFFFFD700),
                        Color(0xFF20DF60),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new,
                          color: BondyColors.textPrimary),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _viewModel.errorMessage!,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                color: BondyColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _viewModel.loadMatchStatus,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(160, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarPair() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        final shadowAlpha = _pulseAnimation.value;
        return SizedBox(
          height: 120,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: BondyColors.primary.withValues(alpha: shadowAlpha),
                          blurRadius: 20,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: _buildAvatarCircle(
                      _currentUserPhoto,
                      _currentUserName ?? 'Bạn',
                    ),
                  ),
                  const SizedBox(width: -20),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: BondyColors.primary.withValues(alpha: shadowAlpha),
                          blurRadius: 20,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: _buildAvatarCircle(
                      _viewModel.otherUserPhoto,
                      _viewModel.otherUserName ?? 'Người kia',
                    ),
                  ),
                ],
              ),
              Positioned(
                bottom: 8,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: BondyColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.favorite, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAvatarCircle(String? photoUrl, String name) {
    final imageProvider = (photoUrl != null && photoUrl.startsWith('http'))
        ? NetworkImage(photoUrl)
        : null;

    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        color: BondyColors.surface,
      ),
      child: ClipOval(
        child: imageProvider != null
            ? Image(image: imageProvider, fit: BoxFit.cover)
            : Center(
                child: Text(
                  name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: BondyColors.primary,
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildStatusContent() {
    switch (_viewModel.status) {
      case MatchConfirmationStatus.pending:
        return _buildPendingContent();
      case MatchConfirmationStatus.confirmed:
        return _buildConfirmedContent();
      case MatchConfirmationStatus.expired:
        return _buildExpiredContent();
    }
  }

  Widget _buildPendingContent() {
    final otherName = _viewModel.otherUserName ?? 'Người kia';
    return Column(
      children: [
        Text(
          'Chờ xác nhận',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: BondyColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Đang chờ $otherName xác nhận kết nối',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: BondyColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        _buildCountdownTimer(),
        const SizedBox(height: 12),
        Text(
          'Còn lại: ${_viewModel.formattedRemainingTime}',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: BondyColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmedContent() {
    final otherName = _viewModel.otherUserName ?? 'Người kia';
    return Column(
      children: [
        Text(
          '✨ Tương hợp thành công! ✨',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: BondyColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Bạn và $otherName đã kết nối!\nHãy bắt đầu trò chuyện để hiểu nhau hơn nhé 💫',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            height: 1.5,
            color: BondyColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        _buildCompatibilityChips(),
      ],
    );
  }

  Widget _buildCompatibilityChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        _buildChip('75% Phù hợp', Icons.favorite_border),
        _buildChip('Cùng sở thích', Icons.bubble_chart_outlined),
        _buildChip('Tâm hồn đồng điệu', Icons.auto_awesome),
      ],
    );
  }

  Widget _buildChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: BondyColors.primary.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: BondyColors.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: BondyColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownTimer() {
    final progress = _viewModel.expiresAt != null
        ? _viewModel.remainingTime.inSeconds / (60 * 60 * 24)
        : 0.0;
    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            strokeWidth: 6,
            backgroundColor: BondyColors.primary.withValues(alpha: 0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(
              BondyColors.primary,
            ),
          ),
          const Icon(Icons.timer, color: BondyColors.primary, size: 32),
        ],
      ),
    );
  }

  Widget _buildExpiredContent() {
    return Column(
      children: [
        Text(
          'Kết nối đã đóng',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: BondyColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Kết nối này đã hết hạn hoặc không còn khả dụng',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: BondyColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildBottomAction() {
    switch (_viewModel.status) {
      case MatchConfirmationStatus.pending:
        return _viewModel.isLoading
            ? const Center(
                child: CircularProgressIndicator(color: BondyColors.primary),
              )
            : Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  gradient: BondyColors.primaryGradient,
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: [
                    BoxShadow(
                      color: BondyColors.primary.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _viewModel.confirmMatch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                  child: Text(
                    'Xác nhận kết nối ❤️',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              );
      case MatchConfirmationStatus.confirmed:
        return Column(
          children: [
            Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                gradient: BondyColors.primaryGradient,
                borderRadius: BorderRadius.circular(100),
                boxShadow: [
                  BoxShadow(
                    color: BondyColors.primary.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () {
                  final chatId = _viewModel.chatId;
                  if (chatId != null) _navigateToChat(chatId);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
                child: Text(
                  'Trò chuyện ngay 💬',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Tiếp tục khám phá',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: BondyColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: BondyColors.textSecondary,
                  ),
                ],
              ),
            ),
          ],
        );
      case MatchConfirmationStatus.expired:
        return OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(100),
            ),
          ),
          child: const Text('Quay lại'),
        );
    }
  }
}
