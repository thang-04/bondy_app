import 'dart:convert';

import 'package:bondy/services/survey_service.dart';
import 'package:bondy/models/survey/survey_question_model.dart';
import 'package:bondy/services/api_client.dart';
import 'package:bondy/services/auth_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('uses configured server when running without override', () {
    expect(SurveyService.baseUrl, 'http://103.149.86.25:3000/api');
  });

  test('uses configured API base URL before platform defaults', () {
    expect(
      SurveyService.resolveBaseUrl(
        baseUrlOverride: 'https://api.example.com/api/',
      ),
      'https://api.example.com/api',
    );
  });

  test('maps backend SCALE questions to slider UI questions', () {
    final question = SurveyQuestion.fromJson({
      'id': 'question-id',
      'questionText': 'Bạn đã sẵn sàng chưa?',
      'questionType': 'SCALE',
      'minValue': 1,
      'maxValue': 10,
    });

    expect(question.type, 'SCALE');
    expect(question.isSlider, true);
    expect(question.minValue, 1);
    expect(question.maxValue, 10);
  });

  test('builds survey submit payload with stable option ids', () {
    const question = SurveyQuestion(
      id: 'question-id',
      title: 'Goal',
      subtitle: '',
      type: 'SINGLE_CHOICE',
      options: [SurveyOption(id: 'option-id', title: 'A serious relationship')],
    );

    final payload = SurveyService.buildSubmitAnswers(
      {'question-id': 'option-id'},
      [question],
    );

    expect(payload, [
      {'questionId': 'question-id', 'answerText': 'option-id'},
    ]);
  });

  test('submits survey answers with bearer token', () async {
    const storage = FlutterSecureStorage();
    await storage.write(key: 'accessToken', value: 'access-token');
    final authService = AuthService(
      baseUrlOverride: 'https://api.example.com/api',
      storage: storage,
    );
    final apiClient = ApiClient(
      baseUrlOverride: 'https://api.example.com/api',
      authService: authService,
      client: MockClient((request) async {
        expect(request.method, 'POST');
        expect(
          request.url.toString(),
          'https://api.example.com/api/surveys/survey-id/submissions',
        );
        expect(request.headers['authorization'], 'Bearer access-token');
        expect(jsonDecode(request.body), {
          'answers': [
            {'questionId': 'question-id', 'answerText': 'option-id'},
          ],
        });
        return http.Response(jsonEncode({'success': true}), 200);
      }),
    );
    final service = SurveyService(apiClient: apiClient);

    final result = await service.submitSurvey(
      'survey-id',
      {'question-id': 'option-id'},
      const [
        SurveyQuestion(
          id: 'question-id',
          title: 'Goal',
          subtitle: '',
          type: 'SINGLE_CHOICE',
          options: [
            SurveyOption(id: 'option-id', title: 'A serious relationship'),
          ],
        ),
      ],
    );

    expect(result, (true, null, null));
  });

  test('survey submission reports auth error when token is missing', () async {
    const storage = FlutterSecureStorage();
    final authService = AuthService(
      baseUrlOverride: 'https://api.example.com/api',
      storage: storage,
    );
    final apiClient = ApiClient(
      baseUrlOverride: 'https://api.example.com/api',
      authService: authService,
      client: MockClient((request) async => http.Response('{}', 500)),
    );
    final service = SurveyService(apiClient: apiClient);

    final result = await service.submitSurvey(
      'survey-id',
      {'question-id': 'option-id'},
      const [
        SurveyQuestion(
          id: 'question-id',
          title: 'Goal',
          subtitle: '',
          type: 'SINGLE_CHOICE',
          options: [
            SurveyOption(id: 'option-id', title: 'A serious relationship'),
          ],
        ),
      ],
    );

    expect(result.$1, false);
    expect(result.$2, contains('đăng nhập'));
  });
}
