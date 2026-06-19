import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../healing/healing_stitch_style.dart';
import '../../services/ai_service.dart';
import '../../viewmodels/ai/ai_quota_viewmodel.dart';
import '../../viewmodels/subscription/subscription_viewmodel.dart';

class PaywallFeature {
  final String title;
  final Map<String, String> tierStatus; // 'unlocked', 'limited', 'locked'
  final Map<String, String> tierSubtitle;

  const PaywallFeature({
    required this.title,
    required this.tierStatus,
    required this.tierSubtitle,
  });
}

const List<PaywallFeature> _paywallFeatures = [
  PaywallFeature(
    title: 'Lượt thích mỗi ngày',
    tierStatus: {'FREE': 'limited', 'PLUS': 'unlocked', 'PREMIUM': 'unlocked'},
    tierSubtitle: {
      'FREE': 'Tối đa 50 lượt thích/ngày',
      'PLUS': 'Không giới hạn lượt thích',
      'PREMIUM': 'Không giới hạn lượt thích',
    },
  ),
  PaywallFeature(
    title: 'Gợi ý hội thoại từ AI',
    tierStatus: {'FREE': 'limited', 'PLUS': 'limited', 'PREMIUM': 'unlocked'},
    tierSubtitle: {
      'FREE': 'Tối đa 5 gợi ý/ngày',
      'PLUS': 'Tối đa 50 gợi ý/ngày',
      'PREMIUM': 'Gợi ý không giới hạn',
    },
  ),
  PaywallFeature(
    title: 'Kho nội dung chữa lành',
    tierStatus: {'FREE': 'limited', 'PLUS': 'limited', 'PREMIUM': 'unlocked'},
    tierSubtitle: {
      'FREE': 'Chỉ nghe nội dung miễn phí',
      'PLUS': 'Nghe nội dung miễn phí & nổi bật',
      'PREMIUM': 'Mở khóa toàn bộ kho Premium',
    },
  ),
  PaywallFeature(
    title: 'Báo cáo cảm xúc cặp đôi',
    tierStatus: {'FREE': 'locked', 'PLUS': 'locked', 'PREMIUM': 'unlocked'},
    tierSubtitle: {
      'FREE': 'Chưa mở khóa',
      'PLUS': 'Chưa mở khóa',
      'PREMIUM': 'Phân tích chi tiết hàng tuần',
    },
  ),
];

class PremiumPaywallScreen extends StatefulWidget {
  const PremiumPaywallScreen({super.key});

  @override
  State<PremiumPaywallScreen> createState() => _PremiumPaywallScreenState();
}

class _PremiumPaywallScreenState extends State<PremiumPaywallScreen> {
  String _selectedTier = 'PREMIUM';

  @override
  void initState() {
    super.initState();
    // Ensure we have latest subscription data when entering the paywall screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SubscriptionViewModel>().loadSubscription();
      try {
        context.read<AiQuotaViewModel>().loadQuota();
      } catch (_) {}
    });
  }

  Future<void> _upgrade() async {
    final viewModel = context.read<SubscriptionViewModel>();
    final success = await viewModel.upgradeSubscription(_selectedTier);
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Nâng cấp thành công (beta — chưa thu phí). Cảm ơn bạn đã thử Bondy Premium!',
          ),
        ),
      );
      Navigator.pop(context);
    } else {
      if (viewModel.errorMessage != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(viewModel.errorMessage!)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SubscriptionViewModel>();
    AiQuotaViewModel? aiQuotaViewModel;
    try {
      aiQuotaViewModel = context.watch<AiQuotaViewModel>();
    } catch (_) {}
    final currentTier = viewModel.currentSubscription?.tier;
    final loading = viewModel.isLoading;

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
                          currentTier != null
                              ? 'Gói hiện tại: $currentTier'
                              : 'Thấu hiểu tri kỷ, gắn kết bền lâu.',
                          style: healingText(
                            color: HealingStitchColors.textMuted,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: HealingStitchColors.coral.withValues(
                              alpha: 0.12,
                            ),
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
                        _buildAiQuotaComparison(aiQuotaViewModel?.summary),
                        const SizedBox(height: 24),
                        ..._paywallFeatures.map(
                          (feature) =>
                              _buildDynamicFeatureRow(feature, _selectedTier),
                        ),
                        const SizedBox(height: 24),
                        _planTile('PLUS', '39.000đ / tháng', tag: 'Sale 75%'),
                        const SizedBox(height: 10),
                        _planTile('PREMIUM', '199.000đ / năm', tag: 'Sale 80%'),
                        const SizedBox(height: 10),
                        _planTile('ELITE', '399.000đ / năm', tag: 'Siêu tiết kiệm'),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: HealingStitchColors.warmGradient,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ElevatedButton(
                              onPressed: loading ? null : _upgrade,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                minimumSize: const Size(double.infinity, 52),
                              ),
                              child: Text(
                                loading ? 'Đang xử lý...' : 'Nâng cấp ngay',
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

  Widget _buildAiQuotaComparison(AiQuotaSummary? summary) {
    final limits = summary?.dailyLimitsByTier.isNotEmpty == true
        ? summary!.dailyLimitsByTier
        : const {
            'FREE': {'healing': 3, 'coach': 3},
            'PLUS': {'healing': 20, 'coach': 20},
            'PREMIUM': {'healing': 50, 'coach': 50},
            'ELITE': {'healing': 100, 'coach': 100},
          };
    const tiers = ['FREE', 'PLUS', 'PREMIUM', 'ELITE'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HealingStitchColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: HealingStitchColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quota AI mỗi ngày',
            style: healingText(size: 16, weight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          for (final tier in tiers)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 76,
                    child: Text(
                      tier,
                      style: healingText(size: 12, weight: FontWeight.w900),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Chữa lành ${limits[tier]?['healing'] ?? 0} lượt',
                      style: healingText(
                        size: 12,
                        color: HealingStitchColors.textMuted,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Gợi ý ${limits[tier]?['coach'] ?? 0} lượt',
                      textAlign: TextAlign.right,
                      style: healingText(
                        size: 12,
                        color: HealingStitchColors.textMuted,
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

  Widget _buildDynamicFeatureRow(PaywallFeature feature, String selectedTier) {
    final status =
        feature.tierStatus[selectedTier] ??
        feature.tierStatus['PREMIUM'] ??
        'locked';
    final subtitle =
        feature.tierSubtitle[selectedTier] ??
        feature.tierSubtitle['PREMIUM'] ??
        '';

    IconData icon;
    Color iconColor;
    Color textColor;
    Color subtitleColor;

    switch (status) {
      case 'unlocked':
        icon = Icons.check_circle;
        iconColor = HealingStitchColors.coral;
        textColor = HealingStitchColors.textMain;
        subtitleColor = HealingStitchColors.textMuted;
        break;
      case 'limited':
        icon = Icons.info_outline;
        iconColor = HealingStitchColors.orange;
        textColor = HealingStitchColors.textMain;
        subtitleColor = HealingStitchColors.orange.withValues(alpha: 0.8);
        break;
      case 'locked':
      default:
        icon = Icons.lock_outline;
        iconColor = HealingStitchColors.textMuted.withValues(alpha: 0.5);
        textColor = HealingStitchColors.textMuted.withValues(alpha: 0.6);
        subtitleColor = HealingStitchColors.textMuted.withValues(alpha: 0.5);
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature.title,
                  style: healingText(
                    size: 14,
                    weight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: healingText(
                      size: 12,
                      weight: FontWeight.w500,
                      color: subtitleColor,
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

  Widget _planTile(String tier, String price, {String? tag}) {
    final selected = _selectedTier == tier;
    return GestureDetector(
      onTap: () => setState(() => _selectedTier = tier),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected
              ? HealingStitchColors.paleCoral
              : HealingStitchColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? HealingStitchColors.coral
                : HealingStitchColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tier,
                    style: healingText(size: 16, weight: FontWeight.w800),
                  ),
                  Text(
                    price,
                    style: healingText(color: HealingStitchColors.textMuted),
                  ),
                ],
              ),
            ),
            if (tag != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: HealingStitchColors.coral.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  tag,
                  style: healingText(
                    size: 11,
                    weight: FontWeight.w700,
                    color: HealingStitchColors.coral,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
