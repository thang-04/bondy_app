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
        name: 'PLUS',
        amount: 39000,
        durationDays: 30,
        period: 'tháng',
        description: 'Thêm lượt AI mỗi ngày và mở khóa các quyền lợi Plus.',
      ),
      SubscriptionPlan(
        tier: 'PREMIUM',
        name: 'PREMIUM',
        amount: 199000,
        durationDays: 365,
        period: 'năm',
        description: 'Gói cân bằng cho dating, healing và AI.',
      ),
      SubscriptionPlan(
        tier: 'ELITE',
        name: 'ELITE',
        amount: 399000,
        durationDays: 365,
        period: 'năm',
        description: 'Mức cao nhất cho người dùng Bondy thường xuyên.',
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
                      _buildSubscriptionTab(quota, gatewayConfigured),
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
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildAiQuotaComparison(summary),
        const SizedBox(height: 16),
        ..._subscriptionPlans.map(_subscriptionTile),
        const SizedBox(height: 18),
        _primaryButton(
          label: 'Nâng cấp ${_selectedSubscription.name}',
          enabled: gatewayConfigured,
          onPressed: _checkoutSubscription,
        ),
      ],
    );
  }

  Widget _buildAiQuotaComparison(AiQuotaSummary? summary) {
    final limits = summary?.dailyLimitsByTier.isNotEmpty == true
        ? summary!.dailyLimitsByTier
        : const {'FREE': 5, 'PLUS': 20, 'PREMIUM': 50, 'ELITE': 100};
    const tiers = ['FREE', 'PLUS', 'PREMIUM', 'ELITE'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HealingStitchColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: HealingStitchColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quota AI mỗi ngày',
            style: healingText(weight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          for (final tier in tiers)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 84,
                    child: Text(
                      tier,
                      style: healingText(weight: FontWeight.w900),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${limits[tier] ?? 0} lượt AI Hub/ngày',
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

  Widget _subscriptionTile(SubscriptionPlan plan) {
    final selected = _selectedTier == plan.tier;
    return GestureDetector(
      onTap: () => setState(() => _selectedTier = plan.tier),
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
                    plan.description,
                    style: healingText(
                      size: 12,
                      color: HealingStitchColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${_formatVnd(plan.amount)} / ${plan.period}',
              textAlign: TextAlign.right,
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
