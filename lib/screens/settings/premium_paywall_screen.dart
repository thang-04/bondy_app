import 'package:flutter/material.dart';

import '../healing/healing_stitch_style.dart';
import '../../widgets/common/bondy_feedback.dart';
import '../../services/subscription_service.dart';

class PremiumPaywallScreen extends StatefulWidget {
  const PremiumPaywallScreen({super.key});

  @override
  State<PremiumPaywallScreen> createState() => _PremiumPaywallScreenState();
}

class _PremiumPaywallScreenState extends State<PremiumPaywallScreen> {
  final SubscriptionService _service = SubscriptionService();
  String _selectedTier = 'PREMIUM';
  bool _loading = false;
  String? _currentTier;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final info = await _service.getMySubscription();
      setState(() => _currentTier = info.tier);
    } catch (_) {}
  }

  Future<void> _upgrade() async {
    setState(() => _loading = true);
    try {
      await _service.upgrade(_selectedTier);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Nâng cấp thành công (beta — chưa thu phí). Cảm ơn bạn đã thử Bondy Premium!',
          ),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      BondyFeedback.showError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HealingStitchColors.warmBackground,
      body: Stack(
        children: [
          Container(
            height: 320,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFE5E5), HealingStitchColors.warmBackground],
              ),
            ),
            child: const Center(
              child: Text('💎', style: TextStyle(fontSize: 88)),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: HealingIconButton(
                    icon: Icons.close,
                    onTap: () => Navigator.pop(context),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 180),
                        Text(
                          'Mở khóa Bondy Premium',
                          style: healingText(size: 26, weight: FontWeight.w800),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _currentTier != null
                              ? 'Gói hiện tại: $_currentTier'
                              : 'Thấu hiểu tri kỷ, gắn kết bền lâu.',
                          style: healingText(color: HealingStitchColors.textMuted),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: HealingStitchColors.coral.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Beta: nâng cấp miễn phí để dùng thử — chưa thu phí. '
                            'Hãy gửi feedback cho Bondy sau khi trải nghiệm.',
                            style: healingText(
                              size: 13,
                              color: HealingStitchColors.textMuted,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildFeatureRow('Like không giới hạn'),
                        _buildFeatureRow('Kho chữa lành Premium'),
                        _buildFeatureRow('Báo cáo cảm xúc cặp đôi'),
                        const SizedBox(height: 24),
                        _planTile('PLUS', '159.000đ / tháng'),
                        const SizedBox(height: 10),
                        _planTile('PREMIUM', '999.000đ / năm', tag: 'Phổ biến'),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: HealingStitchColors.warmGradient,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ElevatedButton(
                              onPressed: _loading ? null : _upgrade,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                minimumSize: const Size(double.infinity, 52),
                              ),
                              child: Text(
                                _loading ? 'Đang xử lý...' : 'Nâng cấp ngay',
                                style: healingText(
                                  weight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: HealingStitchColors.coral),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: healingText(weight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _planTile(String tier, String price, {String? tag}) {
    final selected = _selectedTier == tier;
    return GestureDetector(
      onTap: () => setState(() => _selectedTier = tier),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected ? HealingStitchColors.paleCoral : HealingStitchColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? HealingStitchColors.coral : HealingStitchColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tier, style: healingText(size: 16, weight: FontWeight.w800)),
                  Text(price, style: healingText(color: HealingStitchColors.textMuted)),
                ],
              ),
            ),
            if (tag != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: HealingStitchColors.coral.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  tag,
                  style: healingText(size: 11, weight: FontWeight.w700, color: HealingStitchColors.coral),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
