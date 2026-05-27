// lib/viewmodels/home/home_viewmodel.dart

import 'package:flutter/material.dart';
import '../../models/home/home_widget_model.dart';
import '../../services/auth_service.dart';
import '../../services/home_service.dart';

/// States của màn hình Home
sealed class HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final List<HomeWidget> widgets;
  HomeLoaded(this.widgets);
}

class HomeError extends HomeState {
  final String message;
  HomeError(this.message);
}

class HomeViewModel extends ChangeNotifier {
  HomeState state = HomeLoading();

  final HomeService _service = HomeService();

  Future<void> loadContent(String userId) async {
    state = HomeLoading();
    notifyListeners();

    try {
      final widgets = await _service.fetchHomeContent(userId);
      state = HomeLoaded(widgets);
    } catch (e) {
      state = HomeError(e.toString());
    }

    notifyListeners();
  }

  Future<void> loadAuthenticatedContent({AuthService? authService}) async {
    state = HomeLoading();
    notifyListeners();

    final service = authService ?? AuthService();
    final userId = await service.getCurrentUserId();
    if (userId == null || userId.isEmpty) {
      state = HomeError('Vui lòng đăng nhập để xem nội dung dành cho bạn.');
      notifyListeners();
      return;
    }

    await loadContent(userId);
  }

  /// Pull-to-refresh: load lại nội dung
  Future<void> refresh(String userId) => loadContent(userId);

  Future<void> refreshAuthenticated({AuthService? authService}) => loadAuthenticatedContent(authService: authService);
}
