import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

abstract class AnalyticsClient {
  Future<void> setAnalyticsCollectionEnabled(bool enabled);

  Future<void> setUserId(String? userId);

  Future<void> setUserProperty({required String name, required String? value});

  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  });

  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  });
}

class FirebaseAnalyticsClient implements AnalyticsClient {
  FirebaseAnalyticsClient({FirebaseAnalytics? analytics})
    : _analytics = analytics ?? FirebaseAnalytics.instance;

  final FirebaseAnalytics _analytics;

  @override
  Future<void> setAnalyticsCollectionEnabled(bool enabled) {
    return _analytics.setAnalyticsCollectionEnabled(enabled);
  }

  @override
  Future<void> setUserId(String? userId) {
    return _analytics.setUserId(id: userId);
  }

  @override
  Future<void> setUserProperty({required String name, required String? value}) {
    return _analytics.setUserProperty(name: name, value: value);
  }

  @override
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) {
    return _analytics.logEvent(name: name, parameters: parameters);
  }

  @override
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) {
    return _analytics.logScreenView(
      screenName: screenName,
      screenClass: screenClass ?? screenName,
    );
  }
}

bool resolveAnalyticsEnabled({
  String dartDefineValue = const String.fromEnvironment('ANALYTICS_ENABLED'),
  Map<String, String> environment = const <String, String>{},
  bool environmentLoaded = false,
  bool isWeb = kIsWeb,
  bool isRelease = kReleaseMode,
}) {
  final dartDefineEnabled = _parseAnalyticsBool(dartDefineValue);
  if (dartDefineEnabled != null) return dartDefineEnabled;

  if (environmentLoaded) {
    final environmentEnabled = _parseAnalyticsBool(
      environment['ANALYTICS_ENABLED'],
    );
    if (environmentEnabled != null) return environmentEnabled;
  }

  return isWeb && isRelease;
}

bool? _parseAnalyticsBool(String? value) {
  final normalized = value?.trim().toLowerCase();
  if (normalized == null || normalized.isEmpty) return null;
  if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
    return true;
  }
  if (normalized == 'false' || normalized == '0' || normalized == 'no') {
    return false;
  }
  return null;
}

/// Pluggable analytics service. Activate by setting ANALYTICS_ENABLED=true
/// through --dart-define, runtime env, or the web release fallback.
///
/// Usage example:
/// ```dart
/// analytics.track('swipe_like', {'targetUserId': id});
/// ```
class AnalyticsService {
  AnalyticsService({AnalyticsClient? client}) : _client = client;

  static final AnalyticsService instance = AnalyticsService();

  AnalyticsClient? _client;

  AnalyticsClient get _analyticsClient => _client ??= FirebaseAnalyticsClient();

  void _call(String action, Future<void> Function() operation) {
    try {
      unawaited(
        operation().catchError((Object error) {
          dev.log(
            'Error in analytics $action: $error',
            name: 'AnalyticsService',
          );
        }),
      );
    } catch (error) {
      dev.log('Error in analytics $action: $error', name: 'AnalyticsService');
    }
  }

  bool _enabled = false;
  String? _userId;

  /// Call once after login / at app start.
  void configure({bool enabled = true}) {
    _enabled = enabled;
    _call(
      'set analytics collection enabled',
      () => _analyticsClient.setAnalyticsCollectionEnabled(enabled),
    );
  }

  /// Identify the user so all subsequent events carry the user context.
  void identify(String userId, {Map<String, dynamic>? properties}) {
    _userId = userId;
    if (!_enabled) return;

    _call('set user id', () => _analyticsClient.setUserId(userId));
    if (properties != null) {
      for (final entry in properties.entries) {
        _call(
          'set user property ${entry.key}',
          () => _analyticsClient.setUserProperty(
            name: entry.key,
            value: entry.value?.toString(),
          ),
        );
      }
    }

    _send('\$identify', {'distinct_id': userId, ...?properties});
  }

  /// Reset identity (on logout).
  void reset() {
    _userId = null;
    if (!_enabled) return;

    _call('reset user id', () => _analyticsClient.setUserId(null));
  }

  // ─── Core event helpers ───────────────────────────────────────────────────

  void screenView(String screenName, [String? screenClass]) {
    if (!_enabled) return;
    _call(
      'log screen view $screenName',
      () => _analyticsClient.logScreenView(
        screenName: screenName,
        screenClass: screenClass,
      ),
    );
  }

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

  /// Generic event tracking through Firebase Analytics.
  void track(String event, [Map<String, dynamic>? properties]) {
    final props = <String, dynamic>{
      if (_userId != null) 'userId': _userId,
      ...?properties,
    };

    if (!_enabled) {
      // No-op in test/CI environments.
      return;
    }

    _call(
      'log event $event',
      () => _analyticsClient.logEvent(
        name: event,
        parameters: _analyticsParameters(properties),
      ),
    );

    dev.log('[analytics] $event $props', name: 'AnalyticsService');
  }

  void _send(String event, Map<String, dynamic> props) {
    dev.log('[analytics] $event $props', name: 'AnalyticsService');
  }

  Map<String, Object>? _analyticsParameters(Map<String, dynamic>? properties) {
    if (properties == null || properties.isEmpty) return null;

    final parameters = <String, Object>{};
    for (final entry in properties.entries) {
      final value = entry.value;
      if (value == null) continue;
      if (value is String || value is num || value is bool) {
        parameters[entry.key] = value;
      } else {
        parameters[entry.key] = value.toString();
      }
    }

    return parameters.isEmpty ? null : parameters;
  }
}

/// Convenience accessor — use `analytics.track(...)` everywhere.
final analytics = AnalyticsService.instance;
