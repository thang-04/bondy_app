import 'package:flutter/foundation.dart';

import '../models/survey/survey_question_model.dart';
import 'api_client.dart';
import 'auth_service.dart';

class SurveyService {
  final ApiClient _apiClient;

  SurveyService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  static String get baseUrl => resolveBaseUrl();

  static String resolveBaseUrl({String? baseUrlOverride}) {
    return ApiClient.resolveBaseUrl(baseUrlOverride: baseUrlOverride);
  }

  Future<(String, List<SurveyQuestion>)> fetchActiveSurvey({
    required String surveyType,
  }) async {
    try {
      final response = await _apiClient.get(
        '/surveys',
        queryParams: {
          'surveyType': surveyType,
          'status': 'ACTIVE',
          'limit': 100,
        },
      );

      if (response['success'] == true) {
        final surveys = List<Map<String, dynamic>>.from(
          (response['data'] as List? ?? const []).map(
            (item) => (item as Map).cast<String, dynamic>(),
          ),
        );
        if (surveys.isEmpty) return ('', <SurveyQuestion>[]);

        surveys.sort(
          (a, b) => ((b['totalQuestions'] ?? 0) as int).compareTo(
            (a['totalQuestions'] ?? 0) as int,
          ),
        );
        return _fetchSurveyDetail(surveys.first['id']?.toString() ?? '');
      }

      debugPrint('Fetch survey failed. Body: $response');
      return ('', <SurveyQuestion>[]);
    } catch (error) {
      debugPrint('Fetch survey error: $error');
      throw Exception(
        'Không thể kết nối đến server. Vui lòng kiểm tra lại mạng $error',
      );
    }
  }

  Future<(String, List<SurveyQuestion>)> fetchSurveyByCode(String code) async {
    final trimmedCode = code.trim();
    if (trimmedCode.isEmpty) {
      return ('', <SurveyQuestion>[]);
    }

    try {
      final response = await _apiClient.get(
        '/surveys/code/$trimmedCode',
        queryParams: {'includeQuestions': true},
      );

      if (response['success'] == true && response['data'] != null) {
        return _surveyTupleFromData(
          (response['data'] as Map).cast<String, dynamic>(),
        );
      }

      debugPrint('Fetch survey by code failed. Body: $response');
      return ('', <SurveyQuestion>[]);
    } catch (error) {
      debugPrint('Fetch survey by code error: $error');
      throw Exception(
        'Không thể kết nối đến server. Vui lòng kiểm tra lại mạng $error',
      );
    }
  }

  Future<bool> checkSurveyCompletion(String surveyId) async {
    if (surveyId.trim().isEmpty) return false;

    try {
      final response = await _apiClient.get(
        '/surveys/$surveyId/has-completed',
        authenticated: true,
      );

      return response['success'] == true &&
          response['data']?['hasCompleted'] == true;
    } catch (error) {
      debugPrint('Check survey completion error: $error');
      return false;
    }
  }

  // Returns (success, errorMsg, finalModeCode)
  Future<(bool, String?, String?)> submitSurvey(
    String surveyId,
    Map<String, dynamic> answersMap,
    List<SurveyQuestion> questions,
  ) async {
    if (surveyId.trim().isEmpty) {
      return (false, 'Không có khảo sát hợp lệ để gửi.', null);
    }

    try {
      final response = await _apiClient.post(
        '/surveys/$surveyId/submissions',
        authenticated: true,
        body: {'answers': buildSubmitAnswers(answersMap, questions)},
      );

      if (response['success'] == true) {
        final modeCode = response['data']?['finalModeCode']?.toString();
        return (true, null, modeCode);
      }

      return (
        false,
        response['message']?.toString() ??
            response['error']?.toString() ??
            'Lỗi từ server',
        null,
      );
    } on AuthRequiredException catch (error) {
      return (false, error.toString(), null);
    } on ApiClientException catch (error) {
      return (false, error.message, null);
    } catch (error) {
      debugPrint('Submit survey error: $error');
      return (false, 'Không thể kết nối đến server', null);
    }
  }

  static List<Map<String, dynamic>> buildSubmitAnswers(
    Map<String, dynamic> answersMap,
    List<SurveyQuestion> questions,
  ) {
    final payloadAnswers = <Map<String, dynamic>>[];

    answersMap.forEach((questionId, value) {
      final question = _questionById(questions, questionId);
      if (question == null || value == null) return;

      final answerItem = <String, dynamic>{'questionId': questionId};
      final type = question.type.toUpperCase();

      if (question.isSlider ||
          type == 'SLIDER' ||
          type == 'SCALE' ||
          value is num) {
        if (value is num) {
          answerItem['answerNumber'] = value.toDouble();
        } else {
          answerItem['answerText'] = value.toString();
        }
      } else if (value is List) {
        answerItem['answerJson'] = value;
      } else if (value is bool) {
        answerItem['answerBoolean'] = value;
      } else {
        answerItem['answerText'] = value.toString();
      }

      payloadAnswers.add(answerItem);
    });

    return payloadAnswers;
  }

  Future<(String, List<SurveyQuestion>)> _fetchSurveyDetail(
    String surveyId,
  ) async {
    if (surveyId.isEmpty) return ('', <SurveyQuestion>[]);

    final detailResponse = await _apiClient.get(
      '/surveys/$surveyId',
      queryParams: {'includeQuestions': true},
    );

    if (detailResponse['success'] == true && detailResponse['data'] != null) {
      return _surveyTupleFromData(
        (detailResponse['data'] as Map).cast<String, dynamic>(),
      );
    }

    return ('', <SurveyQuestion>[]);
  }

  (String, List<SurveyQuestion>) _surveyTupleFromData(
    Map<String, dynamic> surveyData,
  ) {
    final questions = surveyData['questions'] as List? ?? const [];
    return (
      surveyData['id']?.toString() ?? '',
      questions
          .map(
            (question) => SurveyQuestion.fromJson(
              (question as Map).cast<String, dynamic>(),
            ),
          )
          .toList(),
    );
  }

  static SurveyQuestion? _questionById(
    List<SurveyQuestion> questions,
    String questionId,
  ) {
    for (final question in questions) {
      if (question.id == questionId) return question;
    }
    return null;
  }
}
