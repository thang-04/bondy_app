import 'package:bondy/services/onboarding_router.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('routes match preference onboarding action to setup screen', () {
    expect(
      OnboardingRouter.routeForAction('SET_MATCH_PREFERENCES'),
      '/match-preferences/setup',
    );
  });
}
