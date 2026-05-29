import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/auth_service.dart';
import '../../services/onboarding_router.dart';
import '../../theme/app_theme.dart';

class AuthGateScreen extends StatefulWidget {
  final AuthService? authService;

  const AuthGateScreen({super.key, this.authService});

  @override
  State<AuthGateScreen> createState() => _AuthGateScreenState();
}

class _AuthGateScreenState extends State<AuthGateScreen> with SingleTickerProviderStateMixin {
  late final AuthService _authService;
  late final AnimationController _animationController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _scaleAnimation = Tween<double>(begin: 0.94, end: 1.04).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _restoreSession();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: BondyColors.signatureGradient,
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FadeTransition(
                      opacity: _opacityAnimation,
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: 240,
                          height: 240,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),
                    const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Đang khôi phục phiên...',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.8),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
