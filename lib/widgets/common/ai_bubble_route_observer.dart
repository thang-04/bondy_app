import 'package:flutter/material.dart';
import '../../screens/home/main_shell_screen.dart';
import '../../widgets/common/ai_chat_bubble.dart';

/// NavigatorObserver để theo dõi route hiện tại.
/// Đảm bảo AI Bubble chỉ hiển thị tại các màn hình chính (Home, Healing, Matches)
/// và tự động ẩn khi chuyển tab hoặc vào màn hình con chi tiết.
class AiBubbleRouteObserver extends NavigatorObserver {
  /// Danh sách các route được phép hiển thị bubble (Whitelist)
  static const _allowedRoutes = <String>{
    '/home',
    '/home/healing',
    '/home/matches',
  };

  void _updateBubbleVisibility(Route<dynamic>? route) {
    final routeName = route?.settings.name ?? '';
    
    // Chỉ hiển thị tại các màn hình trong Whitelist
    final isAllowedRoute = _allowedRoutes.contains(routeName);
    
    // Nếu là home route nhưng đang ở tab Profile (index == 3) thì ẩn đi
    final shouldShow = isAllowedRoute && !MainShellScreen.isShowingProfile;

    aiBubbleKey.currentState?.setVisible(shouldShow);
    aiBubbleKey.currentState?.setHasBottomNav(isAllowedRoute);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _updateBubbleVisibility(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _updateBubbleVisibility(previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _updateBubbleVisibility(newRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _updateBubbleVisibility(previousRoute);
  }
}
