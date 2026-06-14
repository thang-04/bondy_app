import '../models/discover/discover_profile_model.dart';
import 'api_client.dart';

class CommunityService {
  final ApiClient _apiClient;

  CommunityService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  Future<List<DiscoverProfile>> fetchFeed({
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _apiClient.get(
      '/community/feed',
      authenticated: true,
      queryParams: {'limit': limit, 'offset': offset},
    );
    final data = (response['data'] as List<dynamic>?) ?? [];
    return data
        .map((item) => DiscoverProfile.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
