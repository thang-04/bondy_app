import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class CompatibilityReceiptModal extends StatelessWidget {
  final String otherUserName;
  final String? otherUserPhoto;
  final int compatibilityScore;
  final List<Map<String, dynamic>> factors;
  final VoidCallback onOpenChat;

  const CompatibilityReceiptModal({
    super.key,
    required this.otherUserName,
    this.otherUserPhoto,
    required this.compatibilityScore,
    required this.factors,
    required this.onOpenChat,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: BondyColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHandle(),
          const SizedBox(height: 20),
          _buildHeader(context),
          const SizedBox(height: 28),
          _buildScoreCircle(),
          const SizedBox(height: 24),
          _buildFactors(),
          const SizedBox(height: 28),
          _buildActions(context),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: BondyColors.divider,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.favorite, color: BondyColors.primary, size: 40),
        const SizedBox(height: 12),
        Text(
          'Tại sao 2 bạn match?',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: BondyColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Bạn và $otherUserName có nhiều điểm chung',
          style: TextStyle(
            fontSize: 14,
            color: BondyColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildScoreCircle() {
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: compatibilityScore / 100,
            strokeWidth: 8,
            backgroundColor: BondyColors.primary.withValues(alpha: 0.15),
            valueColor: const AlwaysStoppedAnimation<Color>(BondyColors.primary),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$compatibilityScore%',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: BondyColors.primary,
                ),
              ),
              const Text(
                'match',
                style: TextStyle(
                  fontSize: 12,
                  color: BondyColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFactors() {
    final topFactors = factors.take(3).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Điểm nổi bật',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: BondyColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...topFactors.map((f) => _buildFactorRow(f)),
      ],
    );
  }

  Widget _buildFactorRow(Map<String, dynamic> factor) {
    final type = factor['type']?.toString() ?? '';
    final score = ((factor['score'] as num?)?.toDouble() ?? 0.0);
    final label = _factorLabel(type);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: BondyColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (score / 100).clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: BondyColors.primary.withValues(alpha: 0.12),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(BondyColors.primary),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${score.round()}%',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: BondyColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  String _factorLabel(String type) {
    switch (type) {
      case 'personality':
        return 'Tính cách';
      case 'interests':
        return 'Sở thích chung';
      case 'healing_readiness':
        return 'Sẵn sàng chữa lành';
      case 'location':
        return 'Gần nhau';
      case 'dating_goal':
        return 'Mục tiêu hẹn hò';
      default:
        return type;
    }
  }

  Widget _buildActions(BuildContext context) {
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
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text(
              'Mở chat',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Đóng',
            style: TextStyle(color: BondyColors.textSecondary),
          ),
        ),
      ],
    );
  }
}
