// lib/services/home_service.dart

import '../models/home/home_widget_model.dart';
import 'api_client.dart';

class HomeService {
  final ApiClient _apiClient;

  HomeService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  static String get baseUrl {
    return ApiClient.resolveBaseUrl();
  }

  Future<List<HomeWidget>> fetchHomeContent() async {
    final body = await _apiClient.get('/home/content', authenticated: true);
    if (body['success'] != true) {
      throw Exception(body['error']?.toString() ?? 'Lỗi không xác định');
    }

    final widgetsJson =
        (body['data']?['widgets'] as List<dynamic>?) ?? [];

    final widgets = widgetsJson
        .map((w) => HomeWidget.fromJson(w as Map<String, dynamic>))
        .toList();

    // Sắp xếp theo priority tăng dần trước khi trả về
    widgets.sort((a, b) => a.priority.compareTo(b.priority));
    return widgets;
  }
}
