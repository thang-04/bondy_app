import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';
import '../../viewmodels/match/match_confirmation_viewmodel.dart';
import '../../widgets/match/compatibility_receipt_modal.dart';

class MatchConfirmationScreen extends StatefulWidget {
  final String matchId;

  const MatchConfirmationScreen({super.key, required this.matchId});

  @override
  State<MatchConfirmationScreen> createState() =>
      _MatchConfirmationScreenState();
}

class _MatchConfirmationScreenState extends State<MatchConfirmationScreen> {
  late final MatchConfirmationViewModel _viewModel;
  bool _receiptShown = false;

  @override
  void initState() {
    super.initState();
    _viewModel = MatchConfirmationViewModel(matchId: widget.matchId);
    _viewModel.addListener(_onViewModelChange);
    _viewModel.loadMatchStatus();
  }

  void _onViewModelChange() {
    if (_viewModel.status == MatchConfirmationStatus.confirmed && !_receiptShown) {
      _receiptShown = true;
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
      backgroundColor: BondyColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Xac nhan ket noi'),
      ),
      body: SafeArea(
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

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const Spacer(),
                  _buildAvatarPair(),
                  const SizedBox(height: 32),
                  _buildStatusContent(),
                  const Spacer(),
                  _buildBottomAction(),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
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
              style: GoogleFonts.plusJakartaSans(color: BondyColors.error),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _viewModel.loadMatchStatus,
              child: const Text('Thu lai'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarPair() {
    return SizedBox(
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(left: 0, child: _buildInitialAvatar('B', 'Ban')),
          Positioned(right: 0, child: _buildOtherUserAvatar()),
          Center(
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: BondyColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: const Icon(Icons.favorite, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtherUserAvatar() {
    final name = _viewModel.otherUserName ?? 'Nguoi kia';
    final photo = _viewModel.otherUserPhoto;
    if (photo != null && photo.startsWith('http')) {
      return Column(
        children: [
          CircleAvatar(radius: 40, backgroundImage: NetworkImage(photo)),
          const SizedBox(height: 8),
          _buildAvatarLabel(name),
        ],
      );
    }

    final initial = name.trim().isEmpty ? 'B' : name.trim()[0].toUpperCase();
    return _buildInitialAvatar(initial, name);
  }

  Widget _buildInitialAvatar(String initial, String label) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: BondyColors.surface,
            shape: BoxShape.circle,
            border: Border.all(
              color: BondyColors.primary.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              initial,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: BondyColors.primary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        _buildAvatarLabel(label),
      ],
    );
  }

  Widget _buildAvatarLabel(String label) {
    return SizedBox(
      width: 96,
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          color: BondyColors.textSecondary,
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
    final otherName = _viewModel.otherUserName ?? 'Nguoi kia';
    return Column(
      children: [
        Text(
          'Cho xac nhan',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: BondyColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Dang cho $otherName xac nhan ket noi',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: BondyColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        _buildCountdownTimer(),
        const SizedBox(height: 8),
        Text(
          'Con lai: ${_viewModel.formattedRemainingTime}',
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
    final otherName = _viewModel.otherUserName ?? 'Nguoi kia';
    return Column(
      children: [
        Text(
          'Ket noi thanh cong!',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: BondyColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Ban va $otherName da xac nhan ket noi',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: BondyColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
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
          'Ket noi da dong',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: BondyColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Ket noi nay da het han hoac khong con kha dung',
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
            ? const CircularProgressIndicator(color: BondyColors.primary)
            : ElevatedButton(
                onPressed: _viewModel.confirmMatch,
                child: const Text('Xac nhan ket noi'),
              );
      case MatchConfirmationStatus.confirmed:
        return ElevatedButton(
          onPressed: () {
            final chatId = _viewModel.chatId;
            if (chatId != null) _navigateToChat(chatId);
          },
          child: const Text('Bat dau tro chuyen'),
        );
      case MatchConfirmationStatus.expired:
        return OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Tiep tuc kham pha'),
        );
    }
  }
}
