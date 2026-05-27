import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/onboarding_router.dart';
import '../healing/healing_stitch_style.dart';

class AuthGateScreen extends StatefulWidget {
  final AuthService? authService;

  const AuthGateScreen({super.key, this.authService});

  @override
  State<AuthGateScreen> createState() => _AuthGateScreenState();
}

class _AuthGateScreenState extends State<AuthGateScreen> {
  late final AuthService _authService;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _restoreSession();
    });
  }

  Future<void> _restoreSession() async {
    final result = await _authService.restoreSession().timeout(
      const Duration(seconds: 30),
      onTimeout: () => const SessionRestoreResult.unauthenticated(),
    );
    if (!mounted) return;

    final route = result.status == SessionRestoreStatus.authenticated
        ? _routeForUser(result.user ?? const {})
        : '/onboarding';
    Navigator.of(context).pushReplacementNamed(route);
  }

  String _routeForUser(Map<String, dynamic> userData) {
    final emailVerified = userData['emailVerified'] != null;
    if (!emailVerified) {
      return '/verify-email';
    }

    if (userData['profileComplete'] == true) {
      if (userData['surveyComplete'] != true) {
        return '/survey/intro';
      }
      return '/home';
    }

    final profileStatus = userData['profileCompletionStatus'];
    if (profileStatus != null && profileStatus is Map<String, dynamic>) {
      final nextAction = profileStatus['nextAction'] as String?;
      return OnboardingRouter.routeForAction(nextAction);
    }
    return '/profile-setup';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HealingStitchColors.warmBackground,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Bondy', style: healingText(size: 36, weight: FontWeight.w800, color: HealingStitchColors.coral)),
            const SizedBox(height: 32),
            const CircularProgressIndicator(color: HealingStitchColors.coral),
            const SizedBox(height: 16),
            Text('Đang khôi phục phiên...', style: healingText(color: HealingStitchColors.textMuted)),
          ],
        ),
      ),
    );
  }
}
