import 'package:bondy/screens/settings/premium_paywall_screen.dart';
import 'package:bondy/services/ai_service.dart';
import 'package:bondy/services/api_client.dart';
import 'package:bondy/services/payment_service.dart';
import 'package:bondy/services/subscription_service.dart';
import 'package:bondy/viewmodels/ai/ai_quota_viewmodel.dart';
import 'package:bondy/viewmodels/subscription/subscription_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class _StaticPaymentService extends PaymentService {
  _StaticPaymentService() : super(apiClient: ApiClient());

  @override
  Future<PlanCatalog> getPlans() async {
    return PlanCatalog(
      gatewayConfigured: true,
      subscriptions: [
        SubscriptionPlan(
          tier: 'PLUS',
          name: 'PLUS',
          amount: 39000,
          durationDays: 30,
          period: 'thang',
          description: 'Plus subscription',
        ),
      ],
      aiChatPasses: [
        AIChatPassPlan(
          code: 'AI_CHAT_PASS_3D',
          name: 'AI Pack 3D',
          amount: 19000,
          durationDays: 3,
          totalTurns: 60,
          period: '3 ngay',
          description: '60 AI turns',
        ),
      ],
    );
  }
}

class _StaticSubscriptionService extends SubscriptionService {
  _StaticSubscriptionService() : super(apiClient: ApiClient());

  @override
  Future<SubscriptionInfo> getMySubscription() async {
    return SubscriptionInfo(
      tier: 'FREE',
      dailyLikeLimit: 50,
      unlimitedLikes: false,
      premiumHealing: false,
    );
  }
}

class _StaticAiService extends AiService {
  _StaticAiService() : super(ApiClient());

  @override
  Future<AiQuotaSummary> getQuota() async {
    return AiQuotaSummary.fromJson({
      'tier': 'FREE',
      'resetsAt': '2026-06-13T17:00:00.000Z',
      'daily': {
        'mode': 'default',
        'feature': 'daily_ai_chat',
        'label': 'AI Hub chat',
        'tier': 'FREE',
        'limit': 5,
        'used': 5,
        'remaining': 0,
        'resetsAt': '2026-06-13T17:00:00.000Z',
      },
      'passes': {'active': [], 'totalRemaining': 0},
      'dailyLimitsByTier': {'FREE': 5, 'PLUS': 20, 'PREMIUM': 50, 'ELITE': 100},
    });
  }
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('opens AI pass tab and can switch to subscription tab', (
    tester,
  ) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) =>
                SubscriptionViewModel(service: _StaticSubscriptionService()),
          ),
          ChangeNotifierProvider(
            create: (_) => AiQuotaViewModel(aiService: _StaticAiService()),
          ),
        ],
        child: MaterialApp(
          home: PremiumPaywallScreen(
            initialTab: 'aiChatPasses',
            paymentService: _StaticPaymentService(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('AI Pack 3D'), findsOneWidget);
    expect(find.textContaining('60 lượt'), findsOneWidget);
    expect(find.text('PLUS'), findsNothing);

    await tester.tap(find.text('Subscription'));
    await tester.pumpAndSettle();

    expect(find.text('Plus subscription'), findsOneWidget);
    expect(find.text('AI Pack 3D'), findsNothing);
  });
}
