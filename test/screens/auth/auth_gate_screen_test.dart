import 'dart:async';

import 'package:bondy/screens/auth/auth_gate_screen.dart';
import 'package:bondy/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthService extends AuthService {
  final Future<SessionRestoreResult> Function() _restore;

  _FakeAuthService(this._restore)
    : super(baseUrlOverride: 'https://api.example.com/api');

  @override
  Future<SessionRestoreResult> restoreSession() => _restore();
}

Widget _testApp(AuthService authService) {
  return MaterialApp(
    initialRoute: '/',
    routes: {
      '/': (context) => AuthGateScreen(authService: authService),
      '/onboarding': (context) => const Text('onboarding'),
      '/home': (context) => const Text('home'),
      '/profile-setup': (context) => const Text('profile setup'),
    },
  );
}

void main() {
  testWidgets('shows loading while bootstrapping session', (tester) async {
    final completer = Completer<SessionRestoreResult>();
    await tester.pumpWidget(_testApp(_FakeAuthService(() => completer.future)));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('onboarding'), findsNothing);
    expect(find.text('home'), findsNothing);
    expect(find.text('profile setup'), findsNothing);

    completer.complete(const SessionRestoreResult.unauthenticated());
  });

  testWidgets('navigates to home when restored profile is complete', (
    tester,
  ) async {
    final authService = _FakeAuthService(
      () async => const SessionRestoreResult.authenticated({
        'id': 'user-id',
        'profile': {
          'fullName': 'User',
          'gender': 'MALE',
          'birthDate': '2000-01-01',
        },
      }),
    );

    await tester.pumpWidget(_testApp(authService));
    await tester.pumpAndSettle();

    expect(find.text('home'), findsOneWidget);
    expect(find.text('onboarding'), findsNothing);
  });

  testWidgets(
    'navigates to profile setup when restored profile is incomplete',
    (tester) async {
      final authService = _FakeAuthService(
        () async => const SessionRestoreResult.authenticated({
          'id': 'user-id',
          'profile': {'fullName': 'User'},
        }),
      );

      await tester.pumpWidget(_testApp(authService));
      await tester.pumpAndSettle();

      expect(find.text('profile setup'), findsOneWidget);
      expect(find.text('onboarding'), findsNothing);
    },
  );
}
