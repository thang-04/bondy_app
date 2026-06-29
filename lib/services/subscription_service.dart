import 'api_client.dart';

class SubscriptionInfo {
  final String tier;
  final int dailyLikeLimit;
  final bool unlimitedLikes;
  final bool premiumHealing;
  final bool mockBilling;
  final bool isPaid;
  final bool isTrial;
  final DateTime? expiresAt;
  final int? daysRemaining;

  SubscriptionInfo({
    required this.tier,
    required this.dailyLikeLimit,
    required this.unlimitedLikes,
    required this.premiumHealing,
    this.mockBilling = false,
    this.isPaid = false,
    this.isTrial = false,
    this.expiresAt,
    this.daysRemaining,
  });

  bool get isFree => tier == 'FREE';

  factory SubscriptionInfo.fromJson(Map<String, dynamic> json) {
    final features = json['features'] as Map<String, dynamic>? ?? {};
    final tier = json['tier']?.toString() ?? 'FREE';
    return SubscriptionInfo(
      tier: tier,
      dailyLikeLimit: (json['dailyLikeLimit'] as num?)?.toInt() ?? 50,
      unlimitedLikes: features['unlimitedLikes'] == true,
      premiumHealing: features['premiumHealing'] == true,
      mockBilling: json['mockBilling'] == true,
      isPaid: json['isPaid'] == true || (tier != 'FREE'),
      isTrial: json['isTrial'] == true,
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt'].toString())?.toLocal()
          : null,
      daysRemaining: (json['daysRemaining'] as num?)?.toInt(),
    );
  }
}

class SubscriptionService {
  final ApiClient _apiClient;

  SubscriptionService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  Future<SubscriptionInfo> getMySubscription() async {
    final response = await _apiClient.get(
      '/subscription/me',
      authenticated: true,
    );
    return SubscriptionInfo.fromJson(
      (response['data'] as Map<String, dynamic>?) ?? {},
    );
  }

  Future<SubscriptionInfo> upgrade(String tier) async {
    final response = await _apiClient.post(
      '/subscription/me',
      authenticated: true,
      body: {'tier': tier},
    );
    return SubscriptionInfo.fromJson(
      (response['data'] as Map<String, dynamic>?) ?? {'tier': tier},
    );
  }
}
