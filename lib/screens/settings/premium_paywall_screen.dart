import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/ai_service.dart';
import '../../services/analytics_service.dart';
import '../../services/payment_service.dart';
import '../../viewmodels/ai/ai_quota_viewmodel.dart';
import '../../viewmodels/subscription/subscription_viewmodel.dart';
import '../healing/healing_stitch_style.dart';
import 'payment_checkout_screen.dart';

class PremiumPaywallScreen extends StatefulWidget {
  final String? initialTab;
  final PaymentService? paymentService;

  const PremiumPaywallScreen({super.key, this.initialTab, this.paymentService});

  @override
  State<PremiumPaywallScreen> createState() => _PremiumPaywallScreenState();
}

class _PremiumPaywallScreenState extends State<PremiumPaywallScreen> {
  static const _tabAiPasses = 'aiChatPasses';
  static const _tabSubscriptions = 'subscriptions';

  late final PaymentService _paymentService =
      widget.paymentService ?? PaymentService();

  late String _selectedTab = widget.initialTab == _tabSubscriptions
      ? _tabSubscriptions
      : _tabAiPasses;
  String _selectedTier = 'PREMIUM';
  String _selectedAiPassCode = 'AI_CHAT_PASS_3D';
  PlanCatalog? _catalog;
  bool _loadingPlans = false;
  String? _plansError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SubscriptionViewModel>().loadSubscription();
      context.read<AiQuotaViewModel>().loadQuota();
      _loadPlans();
      analytics.subscriptionPaywallView();
    });
  }

  Future<void> _loadPlans() async {
    setState(() {
      _loadingPlans = true;
      _plansError = null;
    });
    try {
      final catalog = await _paymentService.getPlans();
      if (!mounted) return;
      setState(() {
        _catalog = catalog;
        if (catalog.aiChatPasses.isNotEmpty &&
            !catalog.aiChatPasses.any((p) => p.code == _selectedAiPassCode)) {
          _selectedAiPassCode = catalog.aiChatPasses.first.code;
        }
        if (catalog.subscriptions.isNotEmpty &&
            !catalog.subscriptions.any((p) => p.tier == _selectedTier)) {
          _selectedTier = catalog.subscriptions.first.tier;
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _plansError = error.toString());
    } finally {
      if (mounted) setState(() => _loadingPlans = false);
    }
  }

  List<SubscriptionPlan> get _subscriptionPlans {
    final plans = _catalog?.subscriptions ?? const <SubscriptionPlan>[];
    if (plans.isNotEmpty) return plans;
    return [
      SubscriptionPlan(
        tier: 'PLUS',
        name: 'Bondy Plus',
        amount: 39000,
        durationDays: 30,
        period: '1 tháng',
        description:
            'Gấp 4 lần lượt trò chuyện AI, hoàn tác vuốt không giới hạn và mở khóa kho chữa lành.',
      ),
      SubscriptionPlan(
        tier: 'PREMIUM',
        name: 'Bondy Premium',
        amount: 199000,
        durationDays: 365,
        period: '1 năm',
        description:
            'Thích không giới hạn, 50 lượt AI mỗi ngày và báo cáo cảm xúc cặp đôi.',
      ),
      SubscriptionPlan(
        tier: 'ELITE',
        name: 'Bondy Elite',
        amount: 399000,
        durationDays: 365,
        period: '1 năm',
        description:
            'Toàn bộ quyền lợi Premium cùng quota AI cao nhất và ưu tiên hỗ trợ.',
      ),
    ];
  }

  List<AIChatPassPlan> get _aiPassPlans {
    final plans = _catalog?.aiChatPasses ?? const <AIChatPassPlan>[];
    if (plans.isNotEmpty) return plans;
    return [
      AIChatPassPlan(
        code: 'AI_CHAT_PASS_1D',
        name: 'Gói AI 1 ngày',
        amount: 9000,
        durationDays: 1,
        totalTurns: 20,
        period: '1 ngày',
        description: 'Thêm 20 lượt chat AI dùng trong 1 ngày.',
      ),
      AIChatPassPlan(
        code: 'AI_CHAT_PASS_3D',
        name: 'Gói AI 3 ngày',
        amount: 19000,
        durationDays: 3,
        totalTurns: 60,
        period: '3 ngày',
        description: 'Thêm 60 lượt chat AI dùng trong 3 ngày.',
      ),
      AIChatPassPlan(
        code: 'AI_CHAT_PASS_5D',
        name: 'Gói AI 5 ngày',
        amount: 29000,
        durationDays: 5,
        totalTurns: 100,
        period: '5 ngày',
        description: 'Thêm 100 lượt chat AI dùng trong 5 ngày.',
      ),
      AIChatPassPlan(
        code: 'AI_CHAT_PASS_7D',
        name: 'Gói AI 1 tuần',
        amount: 39000,
        durationDays: 7,
        totalTurns: 150,
        period: '1 tuần',
        description: 'Thêm 150 lượt chat AI dùng trong 1 tuần.',
      ),
    ];
  }

  AIChatPassPlan get _selectedAiPass => _aiPassPlans.firstWhere(
    (plan) => plan.code == _selectedAiPassCode,
    orElse: () => _aiPassPlans.first,
  );

  SubscriptionPlan get _selectedSubscription => _subscriptionPlans.firstWhere(
    (plan) => plan.tier == _selectedTier,
    orElse: () => _subscriptionPlans.first,
  );

  String _formatVnd(int amount) {
    final s = amount.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return '$bufđ';
  }

  Future<bool?> _confirmPurchase({
    required String title,
    required String price,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Xác nhận thanh toán',
          style: healingText(size: 18, weight: FontWeight.w800),
        ),
        content: Text(
          'Bạn sắp thanh toán $title - $price.\n\nTiếp tục để hiện mã QR?',
          style: healingText(color: HealingStitchColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Hủy',
              style: healingText(color: HealingStitchColors.textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: HealingStitchColors.coral,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Xác nhận',
              style: healingText(weight: FontWeight.w700, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _checkoutAiPass() async {
    final plan = _selectedAiPass;
    final confirmed = await _confirmPurchase(
      title: plan.name,
      price: _formatVnd(plan.amount),
    );
    if (confirmed != true || !mounted) return;

    analytics.track('ai_chat_pass_checkout_start', {'packageCode': plan.code});
    final paid = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentCheckoutScreen(
          productType: PaymentCheckoutProductType.aiChatPass,
          packageCode: plan.code,
        ),
      ),
    );
    if (!mounted) return;

    if (paid == true) {
      analytics.track('ai_chat_pass_purchase_success', {
        'packageCode': plan.code,
      });
      await context.read<AiQuotaViewModel>().loadQuota();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${plan.name} đã được kích hoạt.')),
      );
      Navigator.pop(context, true);
    }
  }

  Future<void> _checkoutSubscription() async {
    final plan = _selectedSubscription;
    final confirmed = await _confirmPurchase(
      title: 'gói ${plan.name}',
      price: '${_formatVnd(plan.amount)} / ${plan.period}',
    );
    if (confirmed != true || !mounted) return;

    analytics.track('subscription_checkout_start', {'tier': plan.tier});
    final paid = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => PaymentCheckoutScreen(tier: plan.tier)),
    );
    if (!mounted) return;

    if (paid == true) {
      analytics.track('subscription_purchase_success', {'tier': plan.tier});
      await Future.wait([
        context.read<SubscriptionViewModel>().loadSubscription(),
        context.read<AiQuotaViewModel>().loadQuota(),
      ]);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gói của bạn đã được kích hoạt.')),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final subscription = context.watch<SubscriptionViewModel>();
    final quota = context.watch<AiQuotaViewModel>().summary;
    final currentTier = subscription.currentSubscription?.tier ?? 'FREE';
    final gatewayConfigured = _catalog?.gatewayConfigured ?? true;

    return Scaffold(
      backgroundColor: HealingStitchColors.warmBackground,
      body: SafeArea(
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
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      size: 56,
                      color: HealingStitchColors.coral,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _selectedTab == _tabAiPasses
                          ? 'Thêm lượt chat AI'
                          : 'Mở khóa Bondy Premium',
                      style: healingText(size: 26, weight: FontWeight.w800),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Gói hiện tại: $currentTier',
                      style: healingText(color: HealingStitchColors.textMuted),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    _buildGatewayNote(gatewayConfigured),
                    const SizedBox(height: 16),
                    _buildTabSwitch(),
                    if (_loadingPlans) ...[
                      const SizedBox(height: 16),
                      const LinearProgressIndicator(minHeight: 2),
                    ],
                    if (_plansError != null) ...[
                      const SizedBox(height: 12),
                      _buildInlineWarning(_plansError!),
                    ],
                    const SizedBox(height: 20),
                    if (_selectedTab == _tabAiPasses)
                      _buildAiPassTab(quota, gatewayConfigured)
                    else
                      _buildSubscriptionTab(
                        quota,
                        gatewayConfigured,
                        currentTier,
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

  Widget _buildGatewayNote(bool gatewayConfigured) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: gatewayConfigured
            ? HealingStitchColors.coral.withValues(alpha: 0.12)
            : HealingStitchColors.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        gatewayConfigured
            ? 'Thanh toán an toàn qua chuyển khoản QR. Gói tự kích hoạt sau khi nhận tiền.'
            : 'Cổng thanh toán chưa sẵn sàng. Bạn có thể xem gói nhưng chưa thể tạo QR.',
        style: healingText(size: 13, color: HealingStitchColors.textMuted),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildInlineWarning(String message) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: HealingStitchColors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        message,
        style: healingText(size: 12, color: HealingStitchColors.textMuted),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTabSwitch() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: HealingStitchColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: HealingStitchColors.border),
      ),
      child: Row(
        children: [
          _tabButton(_tabAiPasses, 'Gói AI'),
          _tabButton(_tabSubscriptions, 'Subscription'),
        ],
      ),
    );
  }

  Widget _tabButton(String value, String label) {
    final selected = _selectedTab == value;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => setState(() => _selectedTab = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? HealingStitchColors.coral : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: healingText(
              size: 13,
              weight: FontWeight.w800,
              color: selected ? Colors.white : HealingStitchColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAiPassTab(AiQuotaSummary? summary, bool gatewayConfigured) {
    final daily = summary?.quotaFor(AiChatMode.defaultMode);
    final passRemaining = summary?.passes.totalRemaining ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildQuotaStatus(
          dailyText: daily == null
              ? 'Daily quota: --/--'
              : 'Daily quota: ${daily.remaining}/${daily.limit}',
          passText: 'Lượt gói AI còn lại: $passRemaining',
        ),
        const SizedBox(height: 16),
        ..._aiPassPlans.map(_aiPassTile),
        const SizedBox(height: 18),
        _primaryButton(
          label: 'Mua ${_selectedAiPass.name}',
          enabled: gatewayConfigured,
          onPressed: _checkoutAiPass,
        ),
      ],
    );
  }

  Widget _buildQuotaStatus({
    required String dailyText,
    required String passText,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: HealingStitchColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: HealingStitchColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.bolt, color: HealingStitchColors.coral),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dailyText, style: healingText(weight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(
                  passText,
                  style: healingText(
                    size: 12,
                    color: HealingStitchColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _aiPassTile(AIChatPassPlan plan) {
    final selected = _selectedAiPassCode == plan.code;
    return GestureDetector(
      onTap: () => setState(() => _selectedAiPassCode = plan.code),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? HealingStitchColors.paleCoral
              : HealingStitchColors.surface,
          borderRadius: BorderRadius.circular(12),
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
                  Text(plan.name, style: healingText(weight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(
                    '${plan.totalTurns} lượt - dùng trong ${plan.period}',
                    style: healingText(
                      size: 12,
                      color: HealingStitchColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              _formatVnd(plan.amount),
              style: healingText(
                weight: FontWeight.w900,
                color: HealingStitchColors.coral,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionTab(
    AiQuotaSummary? summary,
    bool gatewayConfigured,
    String currentTier,
  ) {
    final selected = _selectedSubscription;
    final isRenew = currentTier == selected.tier;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildCurrentPlanBanner(currentTier, summary),
        const SizedBox(height: 16),
        for (final plan in _subscriptionPlans) _subscriptionTile(plan, currentTier),
        const SizedBox(height: 8),
        _primaryButton(
          label: isRenew
              ? 'Gia hạn ${selected.name}'
              : 'Nâng cấp ${selected.name}',
          enabled: gatewayConfigured,
          onPressed: _checkoutSubscription,
        ),
      ],
    );
  }

  /// Reference card showing what the user has today, so the paid tiers below
  /// read as clear upgrades.
  Widget _buildCurrentPlanBanner(String currentTier, AiQuotaSummary? summary) {
    final isFree = currentTier == 'FREE';
    final freeAi = summary?.dailyLimitsByTier['FREE'] ?? 5;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: HealingStitchColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: HealingStitchColors.border),
      ),
      child: Row(
        children: [
          Icon(
            isFree ? Icons.lock_open_outlined : Icons.verified,
            color: HealingStitchColors.coral,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isFree
                      ? 'Bạn đang dùng gói Free'
                      : 'Bạn đang dùng gói $currentTier',
                  style: healingText(weight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  isFree
                      ? 'Miễn phí: $freeAi lượt AI · 1 Super Like · 50 lượt thích mỗi ngày. Nâng cấp để mở khóa thêm.'
                      : 'Chọn gia hạn hoặc đổi sang gói khác bên dưới.',
                  style: healingText(
                    size: 12,
                    color: HealingStitchColors.textMuted,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Perks for a plan: prefer server-provided highlights, else a per-tier
  /// default kept in sync with the backend limits.
  List<String> _highlightsFor(SubscriptionPlan plan) {
    if (plan.highlights.isNotEmpty) return plan.highlights;
    switch (plan.tier) {
      case 'PLUS':
        return const [
          '20 lượt trò chuyện AI mỗi ngày (gấp 4 lần Free)',
          '5 Super Like mỗi ngày',
          'Hoàn tác vuốt nhầm không giới hạn',
          'Mở khóa kho nội dung chữa lành',
        ];
      case 'PREMIUM':
        return const [
          'Lượt thích không giới hạn mỗi ngày',
          '50 lượt trò chuyện AI mỗi ngày',
          '10 Super Like mỗi ngày',
          'Báo cáo cảm xúc cặp đôi',
          'Toàn bộ kho chữa lành cao cấp',
        ];
      case 'ELITE':
        return const [
          'Tất cả quyền lợi của Premium',
          '100 lượt trò chuyện AI mỗi ngày — cao nhất',
          '20 Super Like mỗi ngày',
          'Ưu tiên hỗ trợ 24/7',
        ];
      default:
        return plan.description.isEmpty ? const [] : [plan.description];
    }
  }

  /// For multi-month plans, the equivalent monthly price (rounded to 1.000đ)
  /// so a yearly plan reads as better value at a glance.
  String? _perMonthLabel(SubscriptionPlan plan) {
    if (plan.durationDays <= 31) return null;
    final months = plan.durationDays / 30.0;
    if (months <= 1) return null;
    final perMonth = ((plan.amount / months) / 1000).round() * 1000;
    return '≈ ${_formatVnd(perMonth)}/tháng';
  }

  Widget _subscriptionTile(SubscriptionPlan plan, String currentTier) {
    final selected = _selectedTier == plan.tier;
    final isCurrent = currentTier == plan.tier;
    final isPopular = plan.tier == 'PREMIUM';
    final highlights = _highlightsFor(plan);
    final perMonth = _perMonthLabel(plan);

    return GestureDetector(
      onTap: () => setState(() => _selectedTier = plan.tier),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? HealingStitchColors.paleCoral
              : HealingStitchColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? HealingStitchColors.coral
                : HealingStitchColors.border,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected ? [healingSoftShadow(0.05)] : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row — always visible. Collapsed = name + price only, so
            // the list stays short; tapping a plan expands its perks below.
            Row(
              children: [
                _radioDot(selected),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              plan.name,
                              style: healingText(
                                size: 16,
                                weight: FontWeight.w800,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (isCurrent)
                            _tierBadge('ĐANG DÙNG', gradient: false)
                          else if (isPopular)
                            _tierBadge('PHỔ BIẾN NHẤT', gradient: true),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: _formatVnd(plan.amount),
                              style: healingText(
                                size: 16,
                                weight: FontWeight.w900,
                                color: HealingStitchColors.coral,
                              ),
                            ),
                            TextSpan(
                              text: ' / ${plan.period}',
                              style: healingText(
                                size: 12,
                                color: HealingStitchColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedRotation(
                  turns: selected ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(
                    Icons.keyboard_arrow_down,
                    color: HealingStitchColors.textMuted,
                  ),
                ),
              ],
            ),
            // Perks — only the selected plan shows them, animated open/closed.
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: selected
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        if (perMonth != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: HealingStitchColors.coral.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Chỉ $perMonth',
                              style: healingText(
                                size: 11,
                                weight: FontWeight.w700,
                                color: HealingStitchColors.coral,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        Container(height: 1, color: HealingStitchColors.border),
                        const SizedBox(height: 12),
                        for (final perk in highlights)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  size: 18,
                                  color: HealingStitchColors.coral,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    perk,
                                    style: healingText(size: 13, height: 1.3),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    )
                  : const SizedBox(width: double.infinity, height: 0),
            ),
          ],
        ),
      ),
    );
  }

  Widget _radioDot(bool selected) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? HealingStitchColors.coral : Colors.transparent,
        border: Border.all(
          color: selected
              ? HealingStitchColors.coral
              : HealingStitchColors.border,
          width: 2,
        ),
      ),
      child: selected
          ? const Icon(Icons.check, size: 13, color: Colors.white)
          : null,
    );
  }

  Widget _tierBadge(String text, {required bool gradient}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        gradient: gradient ? HealingStitchColors.warmGradient : null,
        color: gradient
            ? null
            : HealingStitchColors.purple.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: healingText(
          size: 10,
          weight: FontWeight.w900,
          color: gradient ? Colors.white : HealingStitchColors.purple,
        ),
      ),
    );
  }

  Widget _primaryButton({
    required String label,
    required bool enabled,
    required VoidCallback onPressed,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: enabled ? HealingStitchColors.warmGradient : null,
        color: enabled ? null : HealingStitchColors.border,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          minimumSize: const Size(double.infinity, 52),
        ),
        child: Text(
          label,
          style: healingText(weight: FontWeight.w800, color: Colors.white),
        ),
      ),
    );
  }
}
