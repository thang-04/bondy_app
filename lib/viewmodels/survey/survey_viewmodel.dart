import 'package:flutter/material.dart';

import '../../core/bondy_error_mapper.dart';
import '../../models/survey/survey_question_model.dart';
import '../../services/survey_service.dart';

class SurveyViewModel extends ChangeNotifier {
  List<SurveyQuestion> _questions = [];
  int _currentIndex = 0;
  final SurveyService _surveyService;

  bool _isLoading = true;
  String? _errorMessage;
  bool _isSubmitting = false;
  bool _isAlreadyCompleted = false;
  String? _finalModeCode;

  // Lưu trữ Id của đợt khảo sát để map khi submit
  String _currentSurveyId = '';

  // Lưu trữ câu trả lời của người dùng (ID câu hỏi -> giá trị trả lời)
  final Map<String, dynamic> _answers = {};

  SurveyViewModel({SurveyService? surveyService})
    : _surveyService = surveyService ?? SurveyService() {
    // Không load default, sẽ load khi start
  }

  Future<void> loadSurvey(String surveyType) async {
    _isLoading = true;
    _errorMessage = null;
    _currentIndex = 0;
    _answers.clear();
    notifyListeners();

    try {
      final result = await _surveyService.fetchActiveSurvey(
        surveyType: surveyType,
      );
      final surveyId = result.$1;
      final questions = result.$2;

      if (questions.isEmpty) {
        _errorMessage = 'Không có bài khảo sát nào (hoặc đã lỗi từ Server).';
      } else {
        _currentSurveyId = surveyId;
        _questions = questions;
      }
    } catch (e) {
      _errorMessage = BondyErrorMapper.message(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadSurveyByCode(String code) async {
    _isLoading = true;
    _errorMessage = null;
    _currentIndex = 0;
    _answers.clear();
    notifyListeners();

    try {
      final result = await _surveyService.fetchSurveyByCode(code);
      _currentSurveyId = result.$1;
      _questions = result.$2;
      if (_questions.isEmpty) {
        _errorMessage = 'Khảo sát không có câu hỏi.';
      }
    } catch (e) {
      _errorMessage = BondyErrorMapper.message(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadSurveyWithCompletionCheck(String surveyType) async {
    _isLoading = true;
    _errorMessage = null;
    _isAlreadyCompleted = false;
    _currentIndex = 0;
    _answers.clear();
    notifyListeners();

    try {
      // Lấy survey info trước
      final result = await _surveyService.fetchActiveSurvey(
        surveyType: surveyType,
      );
      final surveyId = result.$1;
      final questions = result.$2;

      if (surveyId.isEmpty || questions.isEmpty) {
        _errorMessage = 'Không có bài khảo sát nào.';
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Check xem đã hoàn thành chưa
      final hasCompleted = await _surveyService.checkSurveyCompletion(surveyId);
      _isAlreadyCompleted = hasCompleted;

      _currentSurveyId = surveyId;
      _questions = questions;
    } catch (e) {
      _errorMessage = BondyErrorMapper.message(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<SurveyQuestion> get questions => _questions;
  int get currentIndex => _currentIndex;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  bool get isAlreadyCompleted => _isAlreadyCompleted;
  String? get errorMessage => _errorMessage;
  String? get finalModeCode => _finalModeCode;

  SurveyQuestion? get currentQuestion =>
      _questions.isNotEmpty ? _questions[_currentIndex] : null;
  bool get isLastQuestion => _currentIndex == _questions.length - 1;

  dynamic get currentAnswer =>
      currentQuestion != null ? _answers[currentQuestion!.id] : null;

  /// Lưu câu trả lời của câu hỏi hiện tại (Dành cho Single Choice, Text, Slider)
  void saveAnswer(dynamic answer) {
    if (currentQuestion != null) {
      _answers[currentQuestion!.id] = answer;
      notifyListeners();
    }
  }

  /// Toggle câu trả lời dành cho Multiple Choice
  void toggleMultipleChoiceAnswer(String optionId) {
    if (currentQuestion != null) {
      final qId = currentQuestion!.id;
      if (!_answers.containsKey(qId) || _answers[qId] is! List) {
        _answers[qId] = <String>[];
      }
      final List<String> currentList = List<String>.from(_answers[qId]);
      if (currentList.contains(optionId)) {
        currentList.remove(optionId);
      } else {
        currentList.add(optionId);
      }
      // Nếu rỗng thì gán null để disable nút Tiếp theo nếu required
      _answers[qId] = currentList.isEmpty ? null : currentList;
      notifyListeners();
    }
  }

  bool isOptionSelected(String optionId) {
    if (currentAnswer == null) return false;
    if (currentAnswer is List) {
      return (currentAnswer as List).contains(optionId);
    }
    return currentAnswer == optionId;
  }

  /// Xử lý khi nhấn nút Tiếp tục
  Future<void> nextQuestion(BuildContext context) async {
    if (isLastQuestion) {
      // Bật loading Submit
      _isSubmitting = true;
      notifyListeners();

      // Submit API
      final result = await _surveyService.submitSurvey(
        _currentSurveyId,
        _answers,
        _questions,
      );
      final bool success = result.$1;
      final String? errorMsg = result.$2;
      _finalModeCode = result.$3;

      _isSubmitting = false;
      notifyListeners();

      if (!context.mounted) return;

      if (success) {
        Navigator.of(context).pushReplacementNamed(
          '/survey/result',
          arguments: {'finalModeCode': _finalModeCode},
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMsg ??
                  'Lỗi gửi kết quả Server. Vui lòng check Terminal Log!',
            ),
          ),
        );
      }
    } else {
      // Chuyển sang câu hỏi tiếp theo
      _currentIndex++;
      notifyListeners();
    }
  }

  /// Quay lại câu hỏi trước đó (tuỳ chọn thêm)
  void previousQuestion() {
    if (_currentIndex > 0) {
      _currentIndex--;
      notifyListeners();
    }
  }

  /// Reset lại khảo sát (nếu cần)
  void resetSurvey() {
    _currentIndex = 0;
    _answers.clear();
    notifyListeners();
  }
}
