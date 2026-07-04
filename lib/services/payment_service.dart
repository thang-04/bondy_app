import 'api_client.dart';

/// A SePay VietQR payment order returned by the backend.
class PaymentOrder {
  final String id;
  final String code;
  final String? productType;
  final String? productCode;
  final String? tier;
  final int amount;
  final int durationDays;
  final String status; // PENDING | PAID | EXPIRED | CANCELLED | FAILED
  final String qrUrl;
  final String bankCode;
  final String accountNumber;
  final String? accountHolder;
  final String transferContent;
  final String? planName;
  final String? period;
  final int? totalTurns;
  final DateTime? paidAt;
  final DateTime expiresAt;

  PaymentOrder({
    required this.id,
    required this.code,
    required this.productType,
    required this.productCode,
    required this.tier,
    required this.amount,
    required this.durationDays,
    required this.status,
    required this.qrUrl,
    required this.bankCode,
    required this.accountNumber,
    required this.accountHolder,
    required this.transferContent,
    required this.planName,
    required this.period,
    required this.totalTurns,
    required this.paidAt,
    required this.expiresAt,
  });

  bool get isPaid => status == 'PAID';
  bool get isPending => status == 'PENDING';
  bool get isExpired => status == 'EXPIRED';
  bool get isFinished => isPaid || status == 'CANCELLED' || status == 'FAILED';

  factory PaymentOrder.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) =>
        v == null ? null : DateTime.tryParse(v.toString())?.toLocal();
    return PaymentOrder(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      productType: json['productType']?.toString(),
      productCode: json['productCode']?.toString(),
      tier: json['tier']?.toString(),
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      durationDays: (json['durationDays'] as num?)?.toInt() ?? 0,
      status: json['status']?.toString() ?? 'PENDING',
      qrUrl: json['qrUrl']?.toString() ?? '',
      bankCode: json['bankCode']?.toString() ?? '',
      accountNumber: json['accountNumber']?.toString() ?? '',
      accountHolder: json['accountHolder']?.toString(),
      transferContent: json['transferContent']?.toString() ?? '',
      planName:
          json['planName']?.toString() ??
          json['productCode']?.toString() ??
          json['tier']?.toString(),
      period: json['period']?.toString(),
      totalTurns: (json['totalTurns'] as num?)?.toInt(),
      paidAt: parseDate(json['paidAt']),
      expiresAt:
          parseDate(json['expiresAt']) ??
          DateTime.now().add(const Duration(minutes: 15)),
    );
  }
}

/// A purchasable subscription plan (price + duration).
class SubscriptionPlan {
  final String tier;
  final String name;
  final int amount;
  final int durationDays;
  final String period;
  final String description;

  SubscriptionPlan({
    required this.tier,
    required this.name,
    required this.amount,
    required this.durationDays,
    required this.period,
    required this.description,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      tier: json['tier']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      durationDays: (json['durationDays'] as num?)?.toInt() ?? 0,
      period: json['period']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
    );
  }
}

/// A finite AI Hub chat pass bundle.
class AIChatPassPlan {
  final String code;
  final String name;
  final int amount;
  final int durationDays;
  final int totalTurns;
  final String period;
  final String description;

  AIChatPassPlan({
    required this.code,
    required this.name,
    required this.amount,
    required this.durationDays,
    required this.totalTurns,
    required this.period,
    required this.description,
  });

  factory AIChatPassPlan.fromJson(Map<String, dynamic> json) {
    return AIChatPassPlan(
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      durationDays: (json['durationDays'] as num?)?.toInt() ?? 0,
      totalTurns: (json['totalTurns'] as num?)?.toInt() ?? 0,
      period: json['period']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
    );
  }
}

class PlanCatalog {
  final bool gatewayConfigured;
  final List<SubscriptionPlan> subscriptions;
  final List<SubscriptionPlan> plans;
  final List<AIChatPassPlan> aiChatPasses;

  PlanCatalog({
    required this.gatewayConfigured,
    required this.subscriptions,
    required this.aiChatPasses,
    List<SubscriptionPlan>? plans,
  }) : plans = plans ?? subscriptions;
}

class PaymentService {
  final ApiClient _apiClient;

  PaymentService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  /// Create a SePay VietQR order for [tier] (PLUS | PREMIUM | ELITE).
  Future<PaymentOrder> createSubscriptionOrder(String tier) async {
    final response = await _apiClient.post(
      '/payments/subscription',
      authenticated: true,
      body: {'tier': tier},
    );
    return PaymentOrder.fromJson(
      (response['data'] as Map<String, dynamic>?) ?? {},
    );
  }

  /// Create a SePay VietQR order for a finite AI chat pass package.
  Future<PaymentOrder> createAIChatPassOrder(String packageCode) async {
    final response = await _apiClient.post(
      '/payments/ai-chat-pass',
      authenticated: true,
      body: {'packageCode': packageCode},
    );
    return PaymentOrder.fromJson(
      (response['data'] as Map<String, dynamic>?) ?? {},
    );
  }

  /// Poll the latest status of an order.
  Future<PaymentOrder> getOrder(String id) async {
    final response = await _apiClient.get('/payments/$id', authenticated: true);
    return PaymentOrder.fromJson(
      (response['data'] as Map<String, dynamic>?) ?? {},
    );
  }

  /// Fetch the plan catalog + whether the gateway is configured.
  Future<PlanCatalog> getPlans() async {
    final response = await _apiClient.get(
      '/payments/plans',
      authenticated: true,
    );
    final data = (response['data'] as Map<String, dynamic>?) ?? {};
    final subscriptionList =
        (data['subscriptions'] as List<dynamic>?) ??
        (data['plans'] as List<dynamic>?) ??
        const [];
    final subscriptions = subscriptionList
        .map((e) => SubscriptionPlan.fromJson(e as Map<String, dynamic>))
        .toList();
    final aiChatPasses = (data['aiChatPasses'] as List<dynamic>? ?? [])
        .map((e) => AIChatPassPlan.fromJson(e as Map<String, dynamic>))
        .toList();
    return PlanCatalog(
      gatewayConfigured: data['gatewayConfigured'] == true,
      subscriptions: subscriptions,
      aiChatPasses: aiChatPasses,
    );
  }
}
