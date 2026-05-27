import 'package:flutter/foundation.dart';

import '../../core/bondy_error_mapper.dart';
import '../../models/healing/healing_models.dart';
import '../../services/profile_service.dart';
import '../../services/healing/healing_progress_store.dart';
import '../../services/healing/healing_service.dart';

typedef HealingDisplayNameLoader = Future<String?> Function();

class HealingHomeViewModel extends ChangeNotifier {
  final HealingDataSource _service;
  final HealingProgressStore _progressStore;
  final HealingDisplayNameLoader _displayNameLoader;

  HealingHomeData? home;
  HealingCheckinResult? lastCheckin;
  bool isLoading = false;
  bool isSubmittingCheckin = false;
  String? errorMessage;
  String displayName = 'bạn';

  HealingHomeViewModel({
    HealingDataSource? service,
    HealingProgressStore? progressStore,
    HealingDisplayNameLoader? displayNameLoader,
  }) : _service = service ?? HealingService(),
       _progressStore = progressStore ?? HealingProgressStore.instance,
       _displayNameLoader =
           displayNameLoader ?? HealingHomeViewModel._loadProfileDisplayName;

  String? get fallbackNotice => home?.fallbackNotice;
  HealingLogSnapshot? get localTodayMood => _progressStore.todayMood;
  bool get hasLocalTodayCheckin => _progressStore.hasTodayCheckin;

  static Future<String?> _loadProfileDisplayName() async {
    final profile = await ProfileService().getProfile();
    return profile.displayName;
  }

  Future<void> loadHome({bool includeDisplayName = false}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      home = await _service.fetchHome();
      if (home?.todayMood != null) {
        _progressStore.rememberTodayCheckin(home!.todayMood!);
      }
      if (includeDisplayName) {
        await _loadDisplayName();
      }
    } catch (error) {
      errorMessage = BondyErrorMapper.message(error);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadDisplayName() async {
    try {
      final loadedName = (await _displayNameLoader())?.trim();
      if (loadedName != null && loadedName.isNotEmpty) {
        displayName = loadedName;
      }
    } catch (_) {
      // Profile loading is non-blocking for the Healing home content.
    }
  }

  Future<HealingCheckinResult?> submitCheckin({
    required String mood,
    required int intensity,
    String? context,
    String source = 'VOLUNTARY',
    String? note,
  }) async {
    // Chặn double-submit khi user bấm nhanh hai lần trước khi setState rerender
    // làm disable nút — nếu không, hai request chạy song song và server tạo 2
    // emotional log cùng ngày.
    if (isSubmittingCheckin) return null;
    if (home?.flowState.hasTodayCheckin == true || hasLocalTodayCheckin) {
      errorMessage = 'Bạn đã check-in hôm nay rồi.';
      notifyListeners();
      return null;
    }

    isSubmittingCheckin = true;
    errorMessage = null;
    notifyListeners();

    try {
      lastCheckin = await _service.checkIn(
        mood: mood,
        intensity: intensity,
        context: context,
        source: source,
        note: note,
      );
      _progressStore.rememberTodayCheckin(
        HealingLogSnapshot(
          mood: mood,
          intensity: intensity,
          context: context,
          readiness: _readinessFromIntensity(intensity),
          needs: _needsFromMood(mood),
          smallGoal: note,
          source: source,
          createdAt: DateTime.now().toIso8601String(),
        ),
      );
      home = await _service.fetchHome();
      if (home?.todayMood != null) {
        _progressStore.rememberTodayCheckin(home!.todayMood!);
      }
      return lastCheckin;
    } catch (error) {
      errorMessage = BondyErrorMapper.message(error);
      return null;
    } finally {
      isSubmittingCheckin = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => loadHome();

  Future<void> completePlanItem(String contentId, String type) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _service.completePlanItem(contentId, completionType: type);
      home = await _service.fetchHome();
    } catch (error) {
      errorMessage = BondyErrorMapper.message(error);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}

String _readinessFromIntensity(int intensity) {
  if (intensity >= 7) return 'NOT_READY';
  if (intensity >= 4) return 'EXPLORING';
  return 'READY';
}

List<String> _needsFromMood(String mood) {
  return switch (mood.toUpperCase()) {
    'ANXIOUS' || 'STRESSED' => const ['CALM_DOWN'],
    'SAD' => const ['SELF_COMPASSION'],
    'ANGRY' => const ['COOL_OFF'],
    _ => const ['REFLECTION'],
  };
}
