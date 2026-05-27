import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../models/survey/survey_question_model.dart';

class SurveyService {
  static String get baseUrl => resolveBaseUrl();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static String resolveBaseUrl({String? baseUrlOverride}) {
    final override = baseUrlOverride?.trim();
    if (override != null && override.isNotEmpty) {
      return override.endsWith('/')
          ? override.substring(0, override.length - 1)
          : override;
    }

    // Priority 1: .env file (for real device and production)
    String? envUrl;
    try {
      envUrl = dotenv.env['API_BASE_URL'];
    } catch (_) {
      // dotenv not initialized, use fallback
    }
    if (envUrl != null && envUrl.trim().isNotEmpty) {
      return envUrl.trim().replaceFirst(RegExp(r'/+$'), '');
    }

    // Priority 2: Platform-specific fallback
    if (kIsWeb) return 'http://localhost:3001/api';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3001/api';  // Android emulator only
    }
    return 'http://localhost:3001/api';
  }

  Future<(String, List<SurveyQuestion>)> fetchActiveSurvey({required String surveyType}) async {
    try {
      // Lấy tất cả surveys cùng type (không dùng limit=1 để tránh bỏ sót survey có đủ câu hỏi)
      final response = await http.get(Uri.parse('$baseUrl/surveys?surveyType=$surveyType&status=active'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null && data['data'].isNotEmpty) {
          final surveys = data['data'] as List;

          // Chọn survey có nhiều questions nhất (totalQuestions từ API)
          surveys.sort((a, b) => ((b['totalQuestions'] ?? 0) as int).compareTo((a['totalQuestions'] ?? 0) as int));
          final surveyData = surveys.first;
          final String surveyId = surveyData['id'];

          // Gọi API detail để lấy chi tiết questions
          final detailResponse = await http.get(Uri.parse('$baseUrl/surveys/$surveyId?includeQuestions=true'));
          
          if (detailResponse.statusCode == 200) {
            final detailData = json.decode(detailResponse.body);
            if (detailData['success'] == true) {
              final questions = detailData['data']['questions'] as List? ?? [];
              return (surveyId, questions.map((q) => SurveyQuestion.fromJson(q)).toList());
            }
          }
        }
      }
      
      debugPrint('Fetch survey failed. Status: ${response.statusCode}, Body: ${response.body}');
      return ('', <SurveyQuestion>[]); // Return empty tuple instead of mock data so UI can show message
    } catch (e) {
      debugPrint('Fetch survey error: $e');
      throw Exception('Không thể kết nối đến server. Vui lòng kiểm tra lại mạng $e');
    }
  }
  Future<(String, List<SurveyQuestion>)> fetchSurveyByCode(String code) async {
    final trimmedCode = code.trim();
    if (trimmedCode.isEmpty) {
      return ('', <SurveyQuestion>[]);
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/surveys/code/$trimmedCode?includeQuestions=true'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final surveyData = data['data'] as Map<String, dynamic>;
          final questions = surveyData['questions'] as List? ?? [];
          return (
            surveyData['id']?.toString() ?? '',
            questions.map((q) => SurveyQuestion.fromJson(q)).toList(),
          );
        }
      }

      debugPrint(
        'Fetch survey by code failed. Status: ${response.statusCode}, Body: ${response.body}',
      );
      return ('', <SurveyQuestion>[]);
    } catch (e) {
      debugPrint('Fetch survey by code error: $e');
      throw Exception('Không thể kết nối đến server. Vui lòng kiểm tra lại mạng $e');
    }
  }

  Future<String?> _getAccessToken() async {
    return await _storage.read(key: 'accessToken');
  }

  Future<(bool, String?)> submitSurvey(String surveyId, Map<String, dynamic> answersMap, List<SurveyQuestion> questions) async {
    try {
      final List<Map<String, dynamic>> payloadAnswers = [];

      answersMap.forEach((questionId, value) {
        final q = questions.firstWhere((q) => q.id == questionId);
        
        Map<String, dynamic> answerItem = {
          'questionId': questionId,
        };
        
        if (q.type == 'SLIDER' || value is double || value is int) {
          answerItem['answerNumber'] = (value as num).toDouble();
        } else if (value is String) {
          answerItem['answerText'] = value;
          // Nếu backend yêu cầu optionId, thì value thực tế là optionId, 
          // có thể check xem nó có match với option list không.
          final opt = q.options.where((o) => o.id == value).firstOrNull;
          if (opt != null) {
            answerItem['answerText'] = opt.title; 
          }
        } else if (value is List) {
          answerItem['answerJson'] = value;
        }

        payloadAnswers.add(answerItem);
      });

      final response = await http.post(
        Uri.parse('$baseUrl/surveys/$surveyId/submissions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _getAccessToken()}',
        },
        body: json.encode({'answers': payloadAnswers}),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        debugPrint('Gửi đáp án thất bại. Body: ${response.body}');
        try {
          final errorData = json.decode(response.body);
          return (false, errorData['message']?.toString() ?? errorData['error']?.toString() ?? 'Lỗi từ server');
        } catch (_) {
          return (false, 'Lỗi server: ${response.statusCode}');
        }
      }

      return (true, null);
    } catch (e) {
      debugPrint('Submit survey error: $e');
      return (false, 'Không thể kết nối đến server'); 
    }
  }
}

