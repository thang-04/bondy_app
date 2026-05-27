import 'package:flutter/foundation.dart';
import '../../services/ai_service.dart';
import '../../services/api_client.dart';

enum AiIntent { opener, continueChat, deepen, humor, lightFlirt }

extension AiIntentExtension on AiIntent {
  String get value {
    switch (this) {
      case AiIntent.opener:
        return 'OPENER';
      case AiIntent.continueChat:
        return 'CONTINUE';
      case AiIntent.deepen:
        return 'DEEPEN';
      case AiIntent.humor:
        return 'HUMOR';
      case AiIntent.lightFlirt:
        return 'FLIRT';
    }
  }

  String get label {
    switch (this) {
      case AiIntent.opener:
        return 'Bắt chuyện';
      case AiIntent.continueChat:
        return 'Tiếp tục';
      case AiIntent.deepen:
        return 'Hỏi sâu';
      case AiIntent.humor:
        return 'Hài hước';
      case AiIntent.lightFlirt:
        return 'Flirt nhẹ';
    }
  }
}

class AiCoachViewModel extends ChangeNotifier {
  final AiService _aiService;

  AiCoachViewModel({AiService? aiService})
      : _aiService = aiService ?? AiService(ApiClient());

  // State
  bool isLoading = false;
  List<String> suggestions = [];
  String? errorMessage;
  AiIntent selectedIntent = AiIntent.opener;
  String selectedTone = 'casual';
  bool isLimitReached = false;
  String? limitType;
  int? remaining;

  // For bottom sheet
  bool showBottomSheet = false;

  void selectIntent(AiIntent intent) {
    selectedIntent = intent;
    notifyListeners();
  }

  void selectTone(String tone) {
    selectedTone = tone;
    notifyListeners();
  }

  Future<void> getSuggestions({
    required String conversationId,
    required String userId,
  }) async {
    isLoading = true;
    errorMessage = null;
    suggestions = [];
    isLimitReached = false;
    notifyListeners();

    try {
      final request = AiSuggestRequest(
        conversationId: conversationId,
        userId: userId,
        intent: selectedIntent.value,
        tone: selectedTone,
        language: 'vi',
      );

      final response = await _aiService.suggest(request);

      if (response.success && response.data != null) {
        suggestions = response.data!.suggestions;
        errorMessage = null;
      } else if (response.error != null && response.error!.contains('LIMIT_REACHED')) {
        // Parse limit info from error
        isLimitReached = true;
        _parseLimitError(response.error!);
        errorMessage = null;
      } else {
        errorMessage = response.error ?? 'Có lỗi xảy ra';
      }
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void _parseLimitError(String error) {
    // Error format: LIMIT_REACHED:type:remaining
    final parts = error.split(':');
    if (parts.length >= 3) {
      limitType = parts[1];
      remaining = int.tryParse(parts[2]);
    }
  }

  void showPaywall() {
    showBottomSheet = true;
    notifyListeners();
  }

  void dismissPaywall() {
    showBottomSheet = false;
    notifyListeners();
  }

  void reset() {
    suggestions = [];
    errorMessage = null;
    isLimitReached = false;
    limitType = null;
    remaining = null;
    showBottomSheet = false;
    notifyListeners();
  }
}