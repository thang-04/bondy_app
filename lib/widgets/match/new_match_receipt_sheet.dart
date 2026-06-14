import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';

class NewMatchReceiptFactor {
  final String label;
  final int score;

  const NewMatchReceiptFactor({required this.label, required this.score});
}

class NewMatchReceiptSheet extends StatelessWidget {
  final String? currentUserPhoto;
  final String otherUserName;
  final String? otherUserPhoto;
  final int compatibilityScore;
  final List<NewMatchReceiptFactor> factors;
  final VoidCallback onOpenChat;
  final VoidCallback onDismiss;

  const NewMatchReceiptSheet({
    super.key,
    this.currentUserPhoto,
    required this.otherUserName,
    this.otherUserPhoto,
    required this.compatibilityScore,
    required this.factors,
    required this.onOpenChat,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final safeScore = compatibilityScore.clamp(0, 100);

    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHandle(),
                const SizedBox(height: 20),
                _buildAvatarPair(),
                const SizedBox(height: 18),
                _buildHeader(),
                const SizedBox(height: 18),
                _buildScoreRow(safeScore),
                const SizedBox(height: 20),
                _buildActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      width: 42,
      height: 4,
      decoration: BoxDecoration(
        color: BondyColors.divider,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }

  Widget _buildAvatarPair() {
    return SizedBox(
      height: 94,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 52,
            child: _buildUserAvatar(
              photo: currentUserPhoto,
              initial: 'B',
              color: BondyColors.primary,
            ),
          ),
          Positioned(
            right: 52,
            child: _buildUserAvatar(
              photo: otherUserPhoto,
              initial: _initialFor(otherUserName),
              color: BondyColors.purple,
            ),
          ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: BondyColors.primaryGradient,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color: BondyColors.primary.withValues(alpha: 0.28),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.favorite, color: Colors.white, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildUserAvatar({
    required String? photo,
    required String initial,
    required Color color,
  }) {
    if (photo != null && photo.startsWith('http')) {
      return Container(
        width: 78,
        height: 78,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipOval(
          child: Image.network(
            photo,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                _buildInitialAvatar(initial, color),
          ),
        ),
      );
    }

    return _buildInitialAvatar(initial, color);
  }

  Widget _buildInitialAvatar(String initial, Color color) {
    return Container(
      width: 78,
      height: 78,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [color, Color.lerp(color, Colors.white, 0.25) ?? color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: Text(
          initial,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: BondyColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            'New match',
            style: GoogleFonts.plusJakartaSans(
              color: BondyColors.primary,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Vì sao hai bạn match?',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            color: BondyColors.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Bạn và $otherUserName có nhiều điểm đồng điệu',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            color: BondyColors.textSecondary,
            fontSize: 14,
            height: 1.45,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildScoreRow(int safeScore) {
    final visibleFactors = factors.take(3).toList();

    return Column(
      children: [
        _buildMainScore(safeScore),
        const SizedBox(height: 12),
        Row(
          children: visibleFactors
              .map(
                (factor) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _buildFactorPill(factor),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildMainScore(int score) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: BondyColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: BondyColors.primary.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.favorite, color: BondyColors.primary, size: 20),
          const SizedBox(width: 8),
          Text(
            '$score%',
            style: GoogleFonts.plusJakartaSans(
              color: BondyColors.primary,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'đồng điệu',
            style: GoogleFonts.plusJakartaSans(
              color: BondyColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFactorPill(NewMatchReceiptFactor factor) {
    final score = factor.score.clamp(0, 100);

    return Container(
      constraints: const BoxConstraints(minHeight: 76),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: BondyColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BondyColors.cardBorder),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$score%',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              color: BondyColors.primary,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            factor.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              color: BondyColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onOpenChat,
            style: ElevatedButton.styleFrom(
              backgroundColor: BondyColors.primary,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              elevation: 0,
            ),
            child: Text(
              'Xem & nhắn tin',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: onDismiss,
          child: Text(
            'Đóng',
            style: GoogleFonts.plusJakartaSans(
              color: BondyColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  String _initialFor(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'B';
    return trimmed.characters.first.toUpperCase();
  }
}
