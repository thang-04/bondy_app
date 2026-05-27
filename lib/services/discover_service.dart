import '../core/bondy_exceptions.dart';
import '../models/discover/discover_profile_model.dart';
import 'api_client.dart';

class LikeQuotaInfo {
  final int remaining;
  final int limit;
  final String tier;

  const LikeQuotaInfo({
    required this.remaining,
    required this.limit,
    required this.tier,
  });

  factory LikeQuotaInfo.fromJson(Map<String, dynamic> json) {
    return LikeQuotaInfo(
      remaining: (json['remaining'] as num?)?.toInt() ?? 0,
      limit: (json['limit'] as num?)?.toInt() ?? 20,
      tier: json['tier']?.toString() ?? 'FREE',
    );
  }
}

class SwipeResult {
  final bool matched;
  final String? matchId;
  final String? conversationId;

  const SwipeResult({
    required this.matched,
    this.matchId,
    this.conversationId,
  });
}

class DiscoverFetchResult {
  final List<DiscoverProfile> profiles;
  final Map<String, dynamic>? healingGate;

  const DiscoverFetchResult({required this.profiles, this.healingGate});
}

class DiscoverService {
  final ApiClient _apiClient;

  DiscoverService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<DiscoverFetchResult> fetchProfilesFull({Map<String, dynamic>? filters}) async {
    final response = await _apiClient.get(
      '/discover/profiles',
      authenticated: true,
      queryParams: filters,
    );
    final data = (response['data'] as List<dynamic>?) ?? [];
    final profiles = data.map((item) => DiscoverProfile.fromJson(item as Map<String, dynamic>)).toList();
    final meta = response['meta'] as Map<String, dynamic>?;
    final healingGate = meta?['healingGate'] as Map<String, dynamic>?;
    return DiscoverFetchResult(profiles: profiles, healingGate: healingGate);
  }

  Future<List<DiscoverProfile>> fetchProfiles({Map<String, dynamic>? filters}) async {
    final result = await fetchProfilesFull(filters: filters);
    return result.profiles;
  }

  Future<SwipeResult> swipe({
    required String targetUserId,
    required String action,
  }) async {
    try {
      final response = await _apiClient.post(
        '/swipes',
        authenticated: true,
        body: {
          'targetUserId': targetUserId,
          'action': action,
        },
      );
      final data = response['data'] as Map<String, dynamic>? ?? {};
      return SwipeResult(
        matched: data['matched'] == true,
        matchId: data['matchId']?.toString(),
        conversationId: data['conversationId']?.toString(),
      );
    } on ApiClientException catch (e) {
      if (e.code == 'QUOTA_EXCEEDED') {
        throw QuotaExceededException(e.message);
      }
      rethrow;
    }
  }

  Future<DiscoverFilters> getFilters() async {
    final response = await _apiClient.get(
      '/discover/filters',
      authenticated: true,
    );
    final data = response['data'] as Map<String, dynamic>? ?? {};
    return DiscoverFilters(
      minAge: (data['minAge'] as num?)?.toInt(),
      maxAge: (data['maxAge'] as num?)?.toInt(),
      maxDistance: (data['maxDistance'] as num?)?.toInt(),
      gender: data['gender']?.toString(),
      orientation: data['orientation']?.toString(),
      datingGoal: data['datingGoal']?.toString(),
      interests: (data['interests'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      minCompatibility: (data['minCompatibility'] as num?)?.toInt(),
    );
  }

  Future<void> saveFilters(DiscoverFilters filters) async {
    await _apiClient.post(
      '/discover/filters',
      authenticated: true,
      body: {
        if (filters.minAge != null) 'minAge': filters.minAge,
        if (filters.maxAge != null) 'maxAge': filters.maxAge,
        if (filters.maxDistance != null) 'maxDistance': filters.maxDistance,
        if (filters.gender != null) 'gender': filters.gender,
        if (filters.orientation != null) 'orientation': filters.orientation,
        if (filters.datingGoal != null) 'datingGoal': filters.datingGoal,
        if (filters.interests != null) 'interests': filters.interests,
        if (filters.minCompatibility != null)
          'minCompatibility': filters.minCompatibility,
      },
    );
  }

  Future<LikeQuotaInfo> fetchLikeQuota() async {
    final response = await _apiClient.get(
      '/swipes/quota',
      authenticated: true,
    );
    return LikeQuotaInfo.fromJson(
      (response['data'] as Map<String, dynamic>?) ?? {},
    );
  }

  Future<void> checkLikeQuota() async {
    final quota = await fetchLikeQuota();
    if (quota.remaining <= 0) {
      throw const QuotaExceededException();
    }
  }

  /// Rewind the caller's most recent swipe.
  /// Throws on quota exhaustion / confirmed-match / no-prior-swipe.
  Future<String?> rewindLastSwipe() async {
    final response = await _apiClient.post(
      '/swipes/rewind',
      authenticated: true,
      body: const {},
    );
    final data = response['data'] as Map<String, dynamic>? ?? {};
    return data['rewoundTargetUserId']?.toString();
  }
}

