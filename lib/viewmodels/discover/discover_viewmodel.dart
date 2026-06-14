import 'package:flutter/material.dart';

import '../../core/bondy_error_mapper.dart';
import '../../core/bondy_exceptions.dart';
import '../../models/discover/discover_profile_model.dart';
import '../../services/api_client.dart';
import '../../services/discover_service.dart';

class DiscoverViewModel extends ChangeNotifier {
  final DiscoverService _service;

  DiscoverViewModel({DiscoverService? service})
    : _service = service ?? DiscoverService();

  List<DiscoverProfile> profiles = [];
  bool isLoading = false;
  String? errorMessage;
  bool _quotaExceeded = false;
  bool _profileIncomplete = false;
  String? _profileIncompleteNextAction;
  String? _lastMatchId;
  String? _lastConversationId;
  SwipeMatchPreview? _lastMatchPreview;
  // BUG-05: expose whether the last swipe API call failed so the screen can
  // restore the card instead of silently discarding it.
  bool _lastSwipeFailed = false;
  LikeQuotaInfo? quota;
  DiscoverFilters? activeFilters;

  bool get isEmpty => !isLoading && profiles.isEmpty && errorMessage == null;
  bool get quotaExceeded => _quotaExceeded;
  bool get profileIncomplete => _profileIncomplete;
  String? get profileIncompleteNextAction => _profileIncompleteNextAction;
  String? get lastMatchId => _lastMatchId;
  String? get lastConversationId => _lastConversationId;
  SwipeMatchPreview? get lastMatchPreview => _lastMatchPreview;
  bool get lastSwipeFailed => _lastSwipeFailed;

  Future<void> loadQuota() async {
    try {
      quota = await _service.fetchLikeQuota();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadFilters() async {
    try {
      activeFilters = await _service.getFilters();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> applyFilters(DiscoverFilters filters) async {
    activeFilters = filters;
    await loadProfiles(filters: filters);
  }

  void removeProfileAt(int index) {
    if (index < 0 || index >= profiles.length) return;
    profiles = List.of(profiles)..removeAt(index);
    notifyListeners();
  }

  void removeProfileById(String profileId) {
    final nextProfiles = profiles
        .where((profile) => profile.id != profileId)
        .toList();
    if (nextProfiles.length == profiles.length) return;
    profiles = nextProfiles;
    notifyListeners();
  }

  /// Thêm lại profile vào đầu deck — dùng khi server từ chối swipe (quota,
  /// mạng lỗi…) và cần hiển thị lại card cho user.
  void restoreProfile(DiscoverProfile profile) {
    // Tránh duplicate nếu profile đã có trong list.
    if (profiles.any((p) => p.id == profile.id)) return;
    profiles = [profile, ...profiles];
    notifyListeners();
  }

  Future<void> loadProfiles({DiscoverFilters? filters}) async {
    isLoading = true;
    errorMessage = null;
    _quotaExceeded = false;
    _profileIncomplete = false;
    notifyListeners();

    try {
      await loadQuota();
      final result = await _service.fetchProfilesFull(
        filters: (filters ?? activeFilters)?.toQueryParams(),
      );
      profiles = result.profiles;
    } on ApiClientException catch (e) {
      if (e.code == 'PROFILE_INCOMPLETE') {
        _profileIncomplete = true;
        final status = e.data?['profileCompletionStatus'];
        _profileIncompleteNextAction = status is Map<String, dynamic>
            ? status['nextAction'] as String?
            : null;
        errorMessage =
            e.data?['profileCompletionStatus']?['missingFields'] != null
            ? 'Vui lòng hoàn thành hồ sơ để tiếp tục.'
            : 'Vui lòng hoàn thành hồ sơ (ảnh, vị trí) để tiếp tục.';
      } else {
        errorMessage = BondyErrorMapper.message(e);
      }
      profiles = [];
    } catch (error) {
      errorMessage = BondyErrorMapper.message(error);
      profiles = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Returns true when a new mutual match was created (navigate to confirm).
  ///
  /// BUG-05: sets [lastSwipeFailed] = true when the API call fails so the
  /// caller screen can restore the swiped card rather than silently losing it.
  Future<bool> swipe(String targetUserId, String action) async {
    _lastMatchId = null;
    _lastConversationId = null;
    _lastMatchPreview = null;
    _lastSwipeFailed = false;
    _quotaExceeded = false;
    final normalized = action.trim().toUpperCase();

    // Pre-check trên quota cache hiện có: nếu remaining đã = 0 thì khỏi gọi
    // server. Pre-check qua /swipes/quota gây thêm 1 round-trip không cần thiết
    // và còn làm quota chip cũ bị overwrite trước khi swipe được tính.
    if ((normalized == 'LIKE' || normalized == 'SUPER_LIKE') &&
        quota != null &&
        quota!.remaining <= 0) {
      _quotaExceeded = true;
      errorMessage =
          'Bạn đã hết lượt like hôm nay. Hãy nâng cấp Premium để tiếp tục.';
      notifyListeners();
      return false;
    }

    try {
      final result = await _service.swipe(
        targetUserId: targetUserId,
        action: normalized,
      );
      errorMessage = null;
      if (result.matched && result.matchId != null) {
        _lastMatchId = result.matchId;
        _lastConversationId = result.conversationId;
        _lastMatchPreview = result.matchPreview;
      }
      await loadQuota();
    } on QuotaExceededException catch (e) {
      _quotaExceeded = true;
      _lastSwipeFailed = true;
      errorMessage = e.message;
      // Sync lại quota để chip hiển thị 0/limit chứ không bị dính giá trị cũ.
      await loadQuota();
    } catch (error) {
      _lastSwipeFailed = true;
      errorMessage = BondyErrorMapper.message(error);
    }
    notifyListeners();
    return _lastMatchId != null;
  }

  void clearLastMatch() {
    _lastMatchId = null;
    _lastConversationId = null;
    _lastMatchPreview = null;
    notifyListeners();
  }

  void clearProfileIncomplete() {
    _profileIncomplete = false;
    _profileIncompleteNextAction = null;
    errorMessage = null;
    notifyListeners();
  }

  /// Hoàn tác thao tác swipe gần nhất. Trả về true nếu rewind thành công và
  /// đẩy lại profile của user đó lên đầu deck. Trả về false (kèm
  /// [errorMessage] đã set) khi server từ chối (hết quota, match đã
  /// CONFIRMED, không có swipe nào…).
  Future<bool> rewindLastSwipe() async {
    errorMessage = null;
    try {
      await _service.rewindLastSwipe();
      // Reload feed so the rewound profile re-appears (server already cleared
      // the swipe row, so it stops being in the exclusion set).
      await loadProfiles();
      await loadQuota();
      return true;
    } catch (error) {
      errorMessage = BondyErrorMapper.message(error);
      notifyListeners();
      return false;
    }
  }
}
