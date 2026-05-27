import 'package:flutter/material.dart';

import '../../core/bondy_error_mapper.dart';
import '../../models/discover/discover_profile_model.dart';
import '../../services/community_service.dart';

class CommunityViewModel extends ChangeNotifier {
  final CommunityService _service;

  CommunityViewModel({CommunityService? service})
    : _service = service ?? CommunityService();

  List<DiscoverProfile> profiles = [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> loadFeed() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      profiles = await _service.fetchFeed();
    } catch (e) {
      errorMessage = BondyErrorMapper.message(e);
      profiles = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
