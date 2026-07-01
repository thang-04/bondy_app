import 'package:bondy/models/discover/discover_profile_model.dart';
import 'package:bondy/models/user_profile_model.dart';
import 'package:bondy/screens/discover/discover_matching_screen.dart';
import 'package:bondy/services/discover_service.dart';
import 'package:bondy/services/profile_service.dart';
import 'package:bondy/services/subscription_service.dart';
import 'package:bondy/viewmodels/subscription/subscription_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  test('maps physical swipe directions to Tinder actions', () {
    expect(discoverSwipeActionForDirection(AxisDirection.left), 'PASS');
    expect(discoverSwipeActionForDirection(AxisDirection.right), 'LIKE');
    expect(discoverSwipeActionForDirection(AxisDirection.up), 'SUPER_LIKE');
    expect(discoverSwipeActionForDirection(AxisDirection.down), 'PASS');
  });

  test('does not auto-start the discover swipe tutorial', () {
    expect(discoverSwipeTutorialAutoStartEnabled, isFalse);
  });

  testWidgets('back arrow goes home when discover is the root route', (
    tester,
  ) async {
    await _pumpDiscoverApp(tester, initialRoute: '/discover');

    await tester.tap(find.byIcon(Icons.arrow_back_ios));
    await tester.pumpAndSettle();

    expect(find.text('home screen'), findsOneWidget);
    expect(find.byType(DiscoverMatchingScreen), findsNothing);
  });

  testWidgets('back arrow pops when discover has a previous route', (
    tester,
  ) async {
    await _pumpDiscoverApp(
      tester,
      initialRoute: '/',
      includePreviousRoute: true,
    );

    await tester.tap(find.text('open discover'));
    await tester.pumpAndSettle();
    expect(find.byType(DiscoverMatchingScreen), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_ios));
    await tester.pumpAndSettle();

    expect(find.text('previous screen'), findsOneWidget);
    expect(find.byType(DiscoverMatchingScreen), findsNothing);
  });
}

Future<void> _pumpDiscoverApp(
  WidgetTester tester, {
  required String initialRoute,
  bool includePreviousRoute = false,
}) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SubscriptionViewModel>(
          create: (_) =>
              SubscriptionViewModel(service: _FakeSubscriptionService()),
        ),
      ],
      child: MaterialApp(
        initialRoute: initialRoute,
        routes: {
          if (includePreviousRoute)
            '/': (context) => Scaffold(
              body: Column(
                children: [
                  const Text('previous screen'),
                  TextButton(
                    onPressed: () =>
                        Navigator.of(context).pushNamed('/discover'),
                    child: const Text('open discover'),
                  ),
                ],
              ),
            ),
          '/discover': (_) => DiscoverMatchingScreen(
            discoverService: _FakeDiscoverService(),
            profileService: _FakeProfileService(),
          ),
          '/home': (_) => const Scaffold(body: Text('home screen')),
        },
      ),
    ),
  );
  await tester.pump();
}

class _FakeDiscoverService implements DiscoverService {
  @override
  Future<DiscoverFilters> getFilters() async => const DiscoverFilters();

  @override
  Future<LikeQuotaInfo> fetchLikeQuota() async {
    return const LikeQuotaInfo(remaining: 20, limit: 20, tier: 'FREE');
  }

  @override
  Future<DiscoverFetchResult> fetchProfilesFull({
    Map<String, dynamic>? filters,
    int limit = DiscoverService.defaultDiscoverLimit,
  }) async {
    return const DiscoverFetchResult(profiles: []);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeProfileService implements ProfileService {
  @override
  Future<UserProfileModel> getProfile() async {
    return const UserProfileModel(
      id: 'user-id',
      email: 'user@example.com',
      name: 'User',
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSubscriptionService implements SubscriptionService {
  @override
  Future<SubscriptionInfo> getMySubscription() async {
    return SubscriptionInfo(
      tier: 'FREE',
      dailyLikeLimit: 20,
      unlimitedLikes: false,
      premiumHealing: false,
    );
  }

  @override
  Future<SubscriptionInfo> upgrade(String tier) async {
    return SubscriptionInfo(
      tier: tier,
      dailyLikeLimit: 20,
      unlimitedLikes: false,
      premiumHealing: false,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
