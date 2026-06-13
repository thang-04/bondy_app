import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/bondy_error_mapper.dart';
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

  String get chatValue {
    switch (this) {
      case AiIntent.opener:
        return 'opener';
      case AiIntent.continueChat:
        return 'continue';
      case AiIntent.deepen:
        return 'deepen';
      case AiIntent.humor:
        return 'humor';
      case AiIntent.lightFlirt:
        return 'flirt';
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

  String get prompt {
    switch (this) {
      case AiIntent.opener:
        return 'Gợi ý 3 tin nhắn mở lời cho match này.';
      case AiIntent.continueChat:
        return 'Gợi ý 3 tin nhắn tiếp theo cho match này dựa trên lịch sử chat gần đây.';
      case AiIntent.deepen:
        return 'Gợi ý 3 câu hỏi sâu sắc để hiểu match này hơn.';
      case AiIntent.humor:
        return 'Gợi ý 3 tin nhắn hài hước, duyên dáng cho match này.';
      case AiIntent.lightFlirt:
        return 'Gợi ý 3 tin nhắn flirt nhẹ, tinh tế cho match này.';
    }
  }
}

class AiCoachViewModel extends ChangeNotifier {
  final AiService _aiService;

  AiCoachViewModel({AiService? aiService})
    : _aiService = aiService ?? AiService(ApiClient());

  // State
  bool isLoading = false;
  String loadingMessage = 'Đang đọc cuộc trò chuyện...';
  List<String> suggestions = [];
  String? errorMessage;
  AiIntent selectedIntent = AiIntent.continueChat;
  String selectedTone = 'casual';
  bool isLimitReached = false;
  String? limitType;
  int? remaining;
  AiModeQuota? quota;
  AiQuotaExceededData? quotaExceededData;
  AiQuotaUpgradeModal? upgradeModal;

  // For bottom sheet
  bool showBottomSheet = false;
  Timer? _loadingTimer;
  int _requestVersion = 0;

  void selectIntent(AiIntent intent) {
    selectedIntent = intent;
    notifyListeners();
  }

  void selectTone(String tone) {
    selectedTone = tone;
    notifyListeners();
  }

  void setQuota(AiModeQuota? value) {
    quota = value;
    remaining = value?.remaining;
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
      } else if (response.error != null &&
          response.error!.contains('LIMIT_REACHED')) {
        // Parse limit info from error
        isLimitReached = true;
        _parseLimitError(response.error!);
        errorMessage = null;
      } else {
        errorMessage = response.error ?? 'Có lỗi xảy ra';
      }
    } on ApiClientException catch (e) {
      if (e.code == 'AI_DAILY_QUOTA_EXCEEDED' && e.data != null) {
        quotaExceededData = AiQuotaExceededData.fromJson(e.data!);
        quota = quotaExceededData?.quota ?? quota;
        upgradeModal = quotaExceededData?.upgradeModal;
        remaining = quota?.remaining;
        isLimitReached = true;
        errorMessage = null;
      } else {
        errorMessage = BondyErrorMapper.message(e);
      }
    } catch (e) {
      errorMessage = BondyErrorMapper.message(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> getPersonalizedSuggestions({
    required String chatId,
    required String matchId,
    String? expectedPartnerId,
    String? message,
  }) async {
    final requestVersion = ++_requestVersion;
    _loadingTimer?.cancel();
    isLoading = true;
    loadingMessage = 'Đang đọc cuộc trò chuyện...';
    errorMessage = null;
    suggestions = [];
    isLimitReached = false;
    notifyListeners();
    _loadingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (requestVersion != _requestVersion || !isLoading) {
        timer.cancel();
        return;
      }

      final seconds = timer.tick;
      final nextMessage = switch (seconds) {
        < 15 => 'Đang đọc cuộc trò chuyện...',
        < 45 => 'Đang cá nhân hóa gợi ý...',
        < 90 => 'AI đang suy nghĩ kỹ hơn...',
        _ => 'Vẫn đang xử lý, bạn chờ thêm một chút nhé...',
      };
      if (nextMessage != loadingMessage) {
        loadingMessage = nextMessage;
        notifyListeners();
      }
    });

    try {
      final prompt = message ?? selectedIntent.prompt;
      final response = await _aiService.chatCoach(
        AiChatRequest(
          chatId: chatId,
          message: prompt,
          matchId: matchId,
          intent: selectedIntent.chatValue,
          tone: selectedTone,
          count: 3,
          language: 'vi',
        ),
      );

      if (requestVersion != _requestVersion) return;

      if (response.success &&
          response.data != null &&
          !response.data!.meta.failed) {
        final data = response.data!;
        final responseMatchesRequest =
            data.flowVersion == 'coach-v2' &&
            data.chatId == chatId &&
            data.matchId == matchId &&
            (expectedPartnerId == null ||
                expectedPartnerId.isEmpty ||
                data.partnerId == expectedPartnerId);
        if (!responseMatchesRequest) {
          errorMessage =
              'Kết quả AI không khớp với cuộc trò chuyện hiện tại. Vui lòng thử lại.';
          return;
        }

        quota = data.meta.quota ?? quota;
        remaining = quota?.remaining;
        final metaSuggestions = response.data!.meta.suggestions;
        suggestions = metaSuggestions.isNotEmpty
            ? metaSuggestions
            : _extractSuggestions(response.data!.response);
        if (suggestions.isEmpty ||
            suggestions.every((suggestion) => suggestion.trim().isEmpty)) {
          suggestions = [];
          errorMessage = 'AI chưa tạo được gợi ý phù hợp. Vui lòng thử lại.';
        } else {
          errorMessage = null;
        }
      } else if (response.data?.meta.failed == true) {
        errorMessage = 'AI tạm thời chưa thể tạo gợi ý. Vui lòng thử lại.';
      } else if (response.error != null &&
          response.error!.contains('LIMIT_REACHED')) {
        isLimitReached = true;
        _parseLimitError(response.error!);
        errorMessage = null;
      } else {
        errorMessage = response.error ?? 'Có lỗi xảy ra';
      }
    } on TimeoutException {
      if (requestVersion == _requestVersion) {
        errorMessage =
            'AI cần nhiều thời gian hơn dự kiến. Vui lòng nhấn Thử lại.';
      }
    } on ApiClientException catch (e) {
      if (requestVersion == _requestVersion) {
        if (e.code == 'AI_DAILY_QUOTA_EXCEEDED' && e.data != null) {
          quotaExceededData = AiQuotaExceededData.fromJson(e.data!);
          quota = quotaExceededData?.quota ?? quota;
          upgradeModal = quotaExceededData?.upgradeModal;
          remaining = quota?.remaining;
          isLimitReached = true;
          errorMessage = null;
        } else {
          errorMessage = BondyErrorMapper.message(e);
        }
      }
    } catch (e) {
      if (requestVersion == _requestVersion) {
        errorMessage = BondyErrorMapper.message(e);
      }
    } finally {
      if (requestVersion == _requestVersion) {
        _loadingTimer?.cancel();
        isLoading = false;
        notifyListeners();
      }
    }
  }

  void cancelPendingRequest() {
    _requestVersion++;
    _loadingTimer?.cancel();
    isLoading = false;
  }

  List<String> _extractSuggestions(String response) {
    final lines = response
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    final numbered = lines
        .where((line) => RegExp(r'^(\d+[\).]|[-•])\s+').hasMatch(line))
        .map((line) => line.replaceFirst(RegExp(r'^(\d+[\).]|[-•])\s+'), ''))
        .toList();
    return numbered.isNotEmpty ? numbered : [response];
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
    cancelPendingRequest();
    suggestions = [];
    errorMessage = null;
    isLimitReached = false;
    limitType = null;
    remaining = null;
    quota = null;
    quotaExceededData = null;
    upgradeModal = null;
    showBottomSheet = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _loadingTimer?.cancel();
    super.dispose();
  }
}
