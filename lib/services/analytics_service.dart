import 'dart:developer' as dev;

/// Pluggable analytics service. No-op by default; activate by setting
/// POSTHOG_API_KEY / MIXPANEL_TOKEN in .env and calling
/// [AnalyticsService.configure] at startup.
///
/// Usage example:
/// ```dart
/// analytics.track('swipe_like', {'targetUserId': id});
/// ```
class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  bool _enabled = false;
  String? _userId;

  /// Call once after login / at app start.
  void configure({bool enabled = true}) {
    _enabled = enabled;
  }

  /// Identify the user so all subsequent events carry the user context.
  void identify(String userId, {Map<String, dynamic>? properties}) {
    _userId = userId;
    if (!_enabled) return;
    _send('\$identify', {'distinct_id': userId, ...?properties});
  }

  /// Reset identity (on logout).
  void reset() {
    _userId = null;
  }

  // ─── Core event helpers ───────────────────────────────────────────────────

  void appOpen() => track('app_open');

  void signupStart() => track('signup_start');
  void signupComplete(String userId) => track('signup_complete', {'userId': userId});
  void profileComplete() => track('profile_complete');

  void discoverView() => track('discover_view');
  void swipeLike(String targetUserId) => track('swipe_like', {'targetUserId': targetUserId});
  void swipePass(String targetUserId) => track('swipe_pass', {'targetUserId': targetUserId});
  void matchCreated(String matchId) => track('match_created', {'matchId': matchId});
  void matchConfirmed(String matchId) => track('match_confirmed', {'matchId': matchId});

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

    // TODO(analytics): replace with PostHog / Mixpanel / Amplitude SDK call.
    // Example (PostHog):
    //   Posthog.capture(eventName: event, properties: props);
    dev.log('[analytics] $event $props', name: 'AnalyticsService');
  }

  void _send(String event, Map<String, dynamic> props) {
    dev.log('[analytics] $event $props', name: 'AnalyticsService');
  }
}

/// Convenience accessor — use `analytics.track(...)` everywhere.
final analytics = AnalyticsService.instance;
