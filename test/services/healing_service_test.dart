import 'dart:convert';

import 'package:bondy/services/api_client.dart';
import 'package:bondy/services/auth_service.dart';
import 'package:bondy/services/healing_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    FlutterSecureStorage.setMockInitialValues({});
  });

  Future<ApiClient> authenticatedClient(http.Client client) async {
    const storage = FlutterSecureStorage();
    await storage.write(key: 'accessToken', value: 'access-token');
    final authService = AuthService(baseUrlOverride: 'https://api.example.com/api', storage: storage);
    return ApiClient(baseUrlOverride: 'https://api.example.com/api', authService: authService, client: client);
  }

  test('loads healing home using the shared response shape', () async {
    final apiClient = await authenticatedClient(MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.toString(), 'https://api.example.com/api/healing/home');
      return http.Response(jsonEncode({
        'success': true,
        'data': {
          'flowState': {
            'isFirstTime': false,
            'hasTodayCheckin': true,
            'primaryIntent': 'REFLECT',
          },
          'articles': [
            {
              'id': 'article-1',
              'type': 'ARTICLE',
              'title': 'Article',
              'summary': 'Summary',
              'category': 'reflection',
              'accessLevel': 'FREE',
              'isLocked': false,
            }
          ],
          'exercises': [],
          'courses': [],
        },
      }), 200);
    }));

    final response = await HealingService(apiClient).getHome();

    expect(response.data?.flowState.hasTodayCheckin, isTrue);
    expect(response.data?.articles.single.title, 'Article');
  });

  test('submits the current healing check-in contract', () async {
    final apiClient = await authenticatedClient(MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.toString(), 'https://api.example.com/api/healing/checkin');
      expect(jsonDecode(request.body), {
        'mood': 'anxious',
        'readiness': 'not_ready',
        'needs': ['reassurance'],
        'trigger': 'LONG_NO_REPLY_48H',
        'smallGoal': 'Take one slow breath',
      });
      return http.Response(jsonEncode({'success': true, 'data': {}}), 200);
    }));

    await HealingService(apiClient).submitCheckin(
      HealingCheckinRequest(
        mood: 'anxious',
        readiness: 'not_ready',
        needs: const ['reassurance'],
        trigger: 'LONG_NO_REPLY_48H',
        smallGoal: 'Take one slow breath',
      ),
    );
  });
}
