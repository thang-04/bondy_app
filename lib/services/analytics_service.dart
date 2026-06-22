import 'dart:developer' as dev;
import 'dart:js' as js;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Pluggable analytics service. No-op by default; activate by setting
/// ANALYTICS_ENABLED=true in .env and calling
/// [AnalyticsService.configure] at startup.
///
/// Usage example:
/// ```dart
/// analytics.track('swipe_like', {'targetUserId': id});
/// ```
class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  FirebaseAnalytics? get _firebaseAnalytics {
    if (kIsWeb) return null; // Firebase Analytics not supported on web build
    try {
      return FirebaseAnalytics.instance;
    } catch (e) {
      dev.log('Failed to get FirebaseAnalytics instance: $e', name: 'AnalyticsService');
      return null;
    }
  }

  bool _enabled = false;
  String? _userId;

  String get _webMeasurementId {
    if (dotenv.isInitialized) {
      return dotenv.env['GA_MEASUREMENT_ID'] ?? 'G-XXXXXXXXXX';
    }
    return 'G-XXXXXXXXXX';
  }

  /// Call once after login / at app start.
  void configure({bool enabled = true}) {
    _enabled = enabled;
  }

  /// Identify the user so all subsequent events carry the user context.
  void identify(String userId, {Map<String, dynamic>? properties}) {
    _userId = userId;
    if (!_enabled) return;
    
    if (kIsWeb) {
      try {
        js.context.callMethod('gtag', [
          'config',
          _webMeasurementId,
          js.JsObject.jsify({'user_id': userId})
        ]);
      } catch (e) {
        dev.log('Error identifying user on web: $e', name: 'AnalyticsService');
      }
    } else {
      try {
        _firebaseAnalytics?.setUserId(id: userId);
        if (properties != null) {
          properties.forEach((key, value) {
            _firebaseAnalytics?.setUserProperty(name: key, value: value.toString());
          });
        }
      } catch (e) {
        dev.log('Error in FirebaseAnalytics identify: $e', name: 'AnalyticsService');
      }
    }
    
    _send('\$identify', {'distinct_id': userId, ...?properties});
  }

  /// Reset identity (on logout).
  void reset() {
    _userId = null;
    try {
      _firebaseAnalytics?.setUserId(id: null);
    } catch (e) {
      dev.log('Error in FirebaseAnalytics reset: $e', name: 'AnalyticsService');
    }
  }

  // ─── Core event helpers ───────────────────────────────────────────────────

  void appOpen() => track('app_open');

  void signupStart() => track('signup_start');
  void signupComplete(String userId) =>
      track('signup_complete', {'userId': userId});
  void profileComplete() => track('profile_complete');

  void discoverView() => track('discover_view');
  void swipeLike(String targetUserId) =>
      track('swipe_like', {'targetUserId': targetUserId});
  void swipePass(String targetUserId) =>
      track('swipe_pass', {'targetUserId': targetUserId});
  void matchCreated(String matchId) =>
      track('match_created', {'matchId': matchId});
  void matchConfirmed(String matchId) =>
      track('match_confirmed', {'matchId': matchId});

  void chatOpened(String chatId) => track('chat_opened', {'chatId': chatId});
  void messageSent(String chatId, String messageType) =>
      track('message_sent', {'chatId': chatId, 'messageType': messageType});

  void healingCheckin() => track('healing_checkin');
  void healingCourseStarted(String courseId) =>
      track('healing_course_started', {'courseId': courseId});

  void subscriptionPaywallView() => track('subscription_paywall_view');

  // ─── Low-level ────────────────────────────────────────────────────────────

  /// Generic event tracking. When a real analytics provider is configured,
  /// replace the log statement with the provider SDK call.
  void track(String event, [Map<String, dynamic>? properties]) {
    final props = <String, dynamic>{
      if (_userId != null) 'userId': _userId,
      ...?properties,
    };

    if (!_enabled) {
      // No-op in test/CI environments.
      return;
    }

    if (kIsWeb) {
      try {
        js.context.callMethod('gtag', [
          'event',
          event,
          if (properties != null) js.JsObject.jsify(properties)
        ]);
      } catch (e) {
        dev.log('Error calling gtag on web: $e', name: 'AnalyticsService');
      }
    } else {
      try {
        // Send event to Firebase Analytics
        _firebaseAnalytics?.logEvent(
          name: event,
          parameters: properties == null ? null : Map<String, Object>.from(properties),
        );
      } catch (e) {
        dev.log('Error in FirebaseAnalytics logEvent: $e', name: 'AnalyticsService');
      }
    }

    dev.log('[analytics] $event $props', name: 'AnalyticsService');
  }

  void _send(String event, Map<String, dynamic> props) {
    dev.log('[analytics] $event $props', name: 'AnalyticsService');
  }
}

/// Convenience accessor — use `analytics.track(...)` everywhere.
final analytics = AnalyticsService.instance;
