import 'api_client.dart';

/// A SePay VietQR payment order returned by the backend.
class PaymentOrder {
  final String id;
  final String code;
  final String tier;
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
  final DateTime? paidAt;
  final DateTime expiresAt;

  PaymentOrder({
    required this.id,
    required this.code,
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
      tier: json['tier']?.toString() ?? 'FREE',
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      durationDays: (json['durationDays'] as num?)?.toInt() ?? 0,
      status: json['status']?.toString() ?? 'PENDING',
      qrUrl: json['qrUrl']?.toString() ?? '',
      bankCode: json['bankCode']?.toString() ?? '',
      accountNumber: json['accountNumber']?.toString() ?? '',
      accountHolder: json['accountHolder']?.toString(),
      transferContent: json['transferContent']?.toString() ?? '',
      planName: json['planName']?.toString(),
      period: json['period']?.toString(),
      paidAt: parseDate(json['paidAt']),
      expiresAt: parseDate(json['expiresAt']) ??
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

class PlanCatalog {
  final bool gatewayConfigured;
  final List<SubscriptionPlan> plans;
  PlanCatalog({required this.gatewayConfigured, required this.plans});
}

class PaymentService {
  final ApiClient _apiClient;

  PaymentService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

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

  /// Poll the latest status of an order.
  Future<PaymentOrder> getOrder(String id) async {
    final response = await _apiClient.get(
      '/payments/$id',
      authenticated: true,
    );
    return PaymentOrder.fromJson(
      (response['data'] as Map<String, dynamic>?) ?? {},
    );
  }

  /// Fetch the plan catalog + whether the gateway is configured.
  Future<PlanCatalog> getPlans() async {
    final response = await _apiClient.get('/payments/plans', authenticated: true);
    final data = (response['data'] as Map<String, dynamic>?) ?? {};
    final plans = (data['plans'] as List<dynamic>? ?? [])
        .map((e) => SubscriptionPlan.fromJson(e as Map<String, dynamic>))
        .toList();
    return PlanCatalog(
      gatewayConfigured: data['gatewayConfigured'] == true,
      plans: plans,
    );
  }
}
