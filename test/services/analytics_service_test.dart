import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:bondy/services/analytics_service.dart';

class RecordingAnalyticsClient implements AnalyticsClient {
  final userIds = <String?>[];
  final userProperties = <({String name, String? value})>[];
  final events = <({String name, Map<String, Object>? parameters})>[];

  @override
  Future<void> setUserId(String? userId) async {
    userIds.add(userId);
  }

  @override
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    userProperties.add((name: name, value: value));
  }

  @override
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    events.add((name: name, parameters: parameters));
  }
}

void main() {
  test('enabled analytics identifies users and logs events through client', () {
    final client = RecordingAnalyticsClient();
    final service = AnalyticsService(client: client);

    service.configure(enabled: true);
    service.identify('user-1', properties: {'tier': 'premium'});
    service.track('swipe_like', {'targetUserId': 'target-1'});

    expect(client.userIds, ['user-1']);
    expect(client.userProperties, [(name: 'tier', value: 'premium')]);
    expect(client.events, hasLength(1));
    expect(client.events.single.name, 'swipe_like');
    expect(client.events.single.parameters, {'targetUserId': 'target-1'});
  });

  test('disabled analytics does not call client', () {
    final client = RecordingAnalyticsClient();
    final service = AnalyticsService(client: client);

    service.configure(enabled: false);
    service.identify('user-1');
    service.track('app_open');
    service.reset();

    expect(client.userIds, isEmpty);
    expect(client.userProperties, isEmpty);
    expect(client.events, isEmpty);
  });

  test('web index does not contain placeholder measurement IDs', () {
    final indexHtml = File('web/index.html').readAsStringSync();

    expect(indexHtml, isNot(contains('G-XXXXXXXXXX')));
  });

  test('main app registers Firebase Analytics screen observer', () {
    final mainDart = File('lib/main.dart').readAsStringSync();

    expect(mainDart, contains('FirebaseAnalyticsObserver'));
    expect(mainDart, contains('navigatorObservers'));
  });
}
