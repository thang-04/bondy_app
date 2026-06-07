import 'package:flutter/material.dart';

import '../../core/bondy_error_mapper.dart';
import '../../services/relationship_service.dart';

class RelationshipViewModel extends ChangeNotifier {
  final RelationshipService _service;

  RelationshipViewModel({RelationshipService? service})
    : _service = service ?? RelationshipService();

  RelationshipDashboard? dashboard;
  RelationshipDailyAction? dailyAction;
  bool isLoading = false;
  bool isDailyActionLoading = false;
  String? errorMessage;
  String? inviteCode;
  bool get hasActiveRelationship => dashboard?.hasRelationship == true;

  Future<void> loadDashboard() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      dashboard = await _service.getDashboard();
    } catch (e) {
      errorMessage = BondyErrorMapper.message(e);
      dashboard ??= RelationshipDashboard(hasRelationship: false);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createInvite({String? matchId}) async {
    try {
      final data = await _service.createInvite(matchId: matchId);
      inviteCode = data['inviteCode']?.toString();
      notifyListeners();
    } catch (e) {
      errorMessage = BondyErrorMapper.message(e);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> acceptInvite(String code) async {
    await _service.acceptInvite(code);
    await loadDashboard();
  }

  Future<void> loadDailyAction({String? dateKey}) async {
    if (!hasActiveRelationship) return;
    isDailyActionLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      dailyAction = await _service.fetchDailyAction(
        dateKey: dateKey ?? relationshipDateKey(),
      );
    } catch (e) {
      errorMessage = BondyErrorMapper.message(e);
    } finally {
      isDailyActionLoading = false;
      notifyListeners();
    }
  }

  Future<void> setDailyActionState({
    String? actionKey,
    String? dateKey,
    required RelationshipDailyActionStatus status,
    DateTime? remindAt,
  }) async {
    final current = dailyAction;
    if (current == null && (actionKey == null || dateKey == null)) {
      throw StateError('Chưa có hành động hôm nay để cập nhật');
    }

    try {
      dailyAction = await _service.updateDailyActionState(
        actionKey: actionKey ?? current!.actionKey,
        dateKey: dateKey ?? current!.dateKey,
        status: status,
        remindAt: remindAt,
      );
      notifyListeners();
    } catch (e) {
      errorMessage = BondyErrorMapper.message(e);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> submitCheckin(String mood, {String? note}) async {
    await _service.submitCheckin(mood: mood, note: note);
    await loadDashboard();
  }

  Future<List<Map<String, dynamic>>> loadMilestones() async {
    return _service.listMilestones();
  }

  Future<void> addMilestone({
    required String title,
    required DateTime milestoneDate,
  }) async {
    await _service.addMilestone(title: title, milestoneDate: milestoneDate);
    await loadDashboard();
  }
}
