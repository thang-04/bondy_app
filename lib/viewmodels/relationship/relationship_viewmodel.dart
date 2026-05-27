import 'package:flutter/material.dart';

import '../../core/bondy_error_mapper.dart';
import '../../services/relationship_service.dart';

class RelationshipViewModel extends ChangeNotifier {
  final RelationshipService _service;

  RelationshipViewModel({RelationshipService? service})
    : _service = service ?? RelationshipService();

  RelationshipDashboard? dashboard;
  bool isLoading = false;
  String? errorMessage;
  String? inviteCode;

  Future<void> loadDashboard() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      dashboard = await _service.getDashboard();
    } catch (e) {
      errorMessage = BondyErrorMapper.message(e);
      dashboard = RelationshipDashboard(hasRelationship: false);
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
