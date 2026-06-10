import 'api_client.dart';

class SubscriptionInfo {
  final String tier;
  final int dailyLikeLimit;
  final bool unlimitedLikes;
  final bool premiumHealing;
  final bool mockBilling;

  SubscriptionInfo({
    required this.tier,
    required this.dailyLikeLimit,
    required this.unlimitedLikes,
    required this.premiumHealing,
    this.mockBilling = true,
  });

  factory SubscriptionInfo.fromJson(Map<String, dynamic> json) {
    final features = json['features'] as Map<String, dynamic>? ?? {};
    return SubscriptionInfo(
      tier: json['tier']?.toString() ?? 'FREE',
      dailyLikeLimit: (json['dailyLikeLimit'] as num?)?.toInt() ?? 50,
      unlimitedLikes: features['unlimitedLikes'] == true,
      premiumHealing: features['premiumHealing'] == true,
      mockBilling: json['mockBilling'] == true,
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
