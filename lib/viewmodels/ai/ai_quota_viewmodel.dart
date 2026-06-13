import 'package:flutter/foundation.dart';

import '../../core/bondy_error_mapper.dart';
import '../../services/ai_service.dart';
import '../../services/api_client.dart';

class AiQuotaViewModel extends ChangeNotifier {
  final AiService _aiService;

  AiQuotaViewModel({AiService? aiService})
    : _aiService = aiService ?? AiService(ApiClient());

  AiQuotaSummary? summary;
  bool isLoading = false;
  String? errorMessage;

  AiModeQuota? quotaFor(AiChatMode mode) => summary?.quotaFor(mode);

  bool isExhausted(AiChatMode mode) {
    final quota = quotaFor(mode);
    return quota != null && quota.remaining <= 0;
  }

  Future<void> loadQuota() async {
    if (isLoading) return;
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      summary = await _aiService.getQuota();
    } catch (error) {
      errorMessage = BondyErrorMapper.message(error);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void applyQuota(AiModeQuota quota) {
    final current = summary;
    if (current == null) {
      summary = AiQuotaSummary(
        tier: quota.tier,
        resetsAt: quota.resetsAt,
        quotas: {quota.mode: quota},
        dailyLimitsByTier: const {},
      );
    } else {
      summary = current.copyWithQuota(quota);
    }
    notifyListeners();
  }
}
