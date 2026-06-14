import '../core/bondy_exceptions.dart';
import '../core/media_url.dart';
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
  final SwipeMatchPreview? matchPreview;

  const SwipeResult({
    required this.matched,
    this.matchId,
    this.conversationId,
    this.matchPreview,
  });
}

class SwipeMatchUser {
  final String id;
  final String name;
  final String? photo;

  const SwipeMatchUser({required this.id, required this.name, this.photo});

  factory SwipeMatchUser.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const SwipeMatchUser(id: '', name: '');
    }
    return SwipeMatchUser(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      photo: rewriteMediaUrl(json['photo']?.toString()),
    );
  }
}

class SwipeMatchPreview {
  final String? matchId;
  final String? conversationId;
  final SwipeMatchUser current;
  final SwipeMatchUser other;

  const SwipeMatchPreview({
    this.matchId,
    this.conversationId,
    required this.current,
    required this.other,
  });

  factory SwipeMatchPreview.fromJson(Map<String, dynamic>? json) {
    final users = json?['users'] as Map<String, dynamic>?;
    return SwipeMatchPreview(
      matchId: json?['matchId']?.toString(),
      conversationId: json?['conversationId']?.toString(),
      current: SwipeMatchUser.fromJson(
        users?['current'] as Map<String, dynamic>?,
      ),
      other: SwipeMatchUser.fromJson(users?['other'] as Map<String, dynamic>?),
    );
  }
}

class DiscoverFetchResult {
  final List<DiscoverProfile> profiles;
  final Map<String, dynamic>? healingGate;

  const DiscoverFetchResult({required this.profiles, this.healingGate});
}

class DiscoverService {
  static const int defaultDiscoverLimit = 50;

  final ApiClient _apiClient;

  DiscoverService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  List<String>? _stringList(dynamic raw) {
    if (raw == null) return null;
    if (raw is List) {
      final values = raw
          .map((item) => item.toString())
          .where((item) => item.trim().isNotEmpty)
          .toList();
      return values.isEmpty ? null : values;
    }
    if (raw is String && raw.trim().isNotEmpty) {
      final values = raw
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
      return values.isEmpty ? null : values;
    }
    return null;
  }

  Future<DiscoverFetchResult> fetchProfilesFull({
    Map<String, dynamic>? filters,
    int limit = defaultDiscoverLimit,
  }) async {
    final queryParams = <String, dynamic>{
      if (filters != null) ...filters,
      'limit': limit,
    };
    final response = await _apiClient.get(
      '/discover/profiles',
      authenticated: true,
      queryParams: queryParams,
    );
    final data = (response['data'] as List<dynamic>?) ?? [];
    final profiles = data
        .map((item) => DiscoverProfile.fromJson(item as Map<String, dynamic>))
        .toList();
    final meta = response['meta'] as Map<String, dynamic>?;
    final healingGate = meta?['healingGate'] as Map<String, dynamic>?;
    return DiscoverFetchResult(profiles: profiles, healingGate: healingGate);
  }

  Future<List<DiscoverProfile>> fetchProfiles({
    Map<String, dynamic>? filters,
    int limit = defaultDiscoverLimit,
  }) async {
    final result = await fetchProfilesFull(filters: filters, limit: limit);
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
        body: {'targetUserId': targetUserId, 'action': action},
      );
      final data = response['data'] as Map<String, dynamic>? ?? {};
      return SwipeResult(
        matched: data['matched'] == true,
        matchId: data['matchId']?.toString(),
        conversationId: data['conversationId']?.toString(),
        matchPreview: data['matchPreview'] is Map<String, dynamic>
            ? SwipeMatchPreview.fromJson(
                data['matchPreview'] as Map<String, dynamic>,
              )
            : null,
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
      minAge: ((data['ageMin'] ?? data['minAge']) as num?)?.toInt(),
      maxAge: ((data['ageMax'] ?? data['maxAge']) as num?)?.toInt(),
      maxDistance: ((data['distanceKm'] ?? data['maxDistance']) as num?)
          ?.toInt(),
      genders: _stringList(data['genders'] ?? data['gender']),
      orientations: _stringList(data['orientations'] ?? data['orientation']),
      goals: _stringList(data['goals'] ?? data['datingGoal']),
      interests: _stringList(data['interestIds'] ?? data['interests']),
      minCompatibility: (data['minCompatibility'] as num?)?.toInt(),
      vibes: _stringList(data['vibes']),
    );
  }

  Future<void> saveFilters(DiscoverFilters filters) async {
    await _apiClient.post(
      '/discover/filters',
      authenticated: true,
      body: {
        if (filters.minAge != null) 'minAge': filters.minAge,
        if (filters.maxAge != null) 'maxAge': filters.maxAge,
        if (filters.maxDistance != null) 'distanceKm': filters.maxDistance,
        if (filters.genders != null && filters.genders!.isNotEmpty)
          'genders': filters.genders,
        if (filters.orientations != null && filters.orientations!.isNotEmpty)
          'orientations': filters.orientations,
        if (filters.goals != null && filters.goals!.isNotEmpty)
          'goals': filters.goals,
        if (filters.interests != null && filters.interests!.isNotEmpty)
          'interestIds': filters.interests,
        if (filters.minCompatibility != null)
          'minCompatibility': filters.minCompatibility,
        if (filters.vibes != null && filters.vibes!.isNotEmpty)
          'vibes': filters.vibes,
      },
    );
  }

  Future<LikeQuotaInfo> fetchLikeQuota() async {
    final response = await _apiClient.get('/swipes/quota', authenticated: true);
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
