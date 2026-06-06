import 'package:flutter/material.dart';
import '../../services/subscription_service.dart';

class SubscriptionViewModel extends ChangeNotifier {
  final SubscriptionService _service;
  SubscriptionInfo? _currentSubscription;
  bool _isLoading = false;
  String? _errorMessage;

  SubscriptionViewModel({SubscriptionService? service})
      : _service = service ?? SubscriptionService();

  SubscriptionInfo? get currentSubscription => _currentSubscription;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadSubscription() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _currentSubscription = await _service.getMySubscription();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> upgradeSubscription(String tier) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _currentSubscription = await _service.upgrade(tier);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
