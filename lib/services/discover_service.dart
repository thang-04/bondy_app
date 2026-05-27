import '../models/discover/discover_profile_model.dart';
import 'api_client.dart';

class DiscoverService {
  final ApiClient _apiClient;

  DiscoverService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<List<DiscoverProfile>> fetchProfiles() async {
    final response = await _apiClient.get('/discover/profiles', authenticated: true);
    final data = (response['data'] as List<dynamic>?) ?? [];
    return data.map((item) => DiscoverProfile.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<void> swipe({required String targetUserId, required String action}) async {
    await _apiClient.post(
      '/swipes',
      authenticated: true,
      body: {
        'targetUserId': targetUserId,
        'action': action,
      },
    );
  }
}
