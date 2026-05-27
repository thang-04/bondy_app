import 'package:flutter/material.dart';

import '../../models/discover/discover_profile_model.dart';
import '../../services/discover_service.dart';

class DiscoverViewModel extends ChangeNotifier {
  final DiscoverService _service;

  DiscoverViewModel({DiscoverService? service}) : _service = service ?? DiscoverService();

  List<DiscoverProfile> profiles = [];
  bool isLoading = false;
  String? errorMessage;

  bool get isEmpty => !isLoading && profiles.isEmpty && errorMessage == null;

  Future<void> loadProfiles() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      profiles = await _service.fetchProfiles();
    } catch (error) {
      errorMessage = error.toString();
      profiles = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> swipe(String targetUserId, String action) async {
    try {
      await _service.swipe(targetUserId: targetUserId, action: action);
      errorMessage = null;
    } catch (error) {
      errorMessage = error.toString();
    }
    notifyListeners();
  }
}
