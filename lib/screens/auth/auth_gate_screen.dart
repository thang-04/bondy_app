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

class _AuthGateScreenState extends State<AuthGateScreen>
    with SingleTickerProviderStateMixin {
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

  bool _networkError = false;

  Future<void> _restoreSession() async {
    if (_networkError && mounted) {
      setState(() => _networkError = false);
    }
    final result = await _authService.restoreSession().timeout(
      const Duration(seconds: 30),
      onTimeout: () => const SessionRestoreResult.networkError(),
    );
    if (!mounted) return;

    // Lỗi mạng/máy chủ tạm thời: token vẫn còn, KHÔNG đẩy user về onboarding —
    // hiển thị nút thử lại để tránh "tự đăng xuất" khi mạng chập chờn.
    if (result.status == SessionRestoreStatus.networkError) {
      setState(() => _networkError = true);
      return;
    }

    if (result.status == SessionRestoreStatus.authenticated) {
      final user = result.user ?? const {};
      final emailVerified = user['emailVerified'] != null;
      if (!emailVerified) {
        Navigator.of(context).pushReplacementNamed('/verify-email');
        return;
      }

      final profile = user['profile'];
      bool isDeepMatchComplete = false;
      if (profile is Map<String, dynamic>) {
        final zodiacSign = profile['zodiacSign'];
        final desiredPartnerType = profile['desiredPartnerType'];
        final freeTimeSlots = profile['freeTimeSlots'];
        if (zodiacSign != null &&
            desiredPartnerType != null &&
            freeTimeSlots is List &&
            freeTimeSlots.isNotEmpty) {
          isDeepMatchComplete = true;
        }
      }

      if (user['profileComplete'] == true) {
        if (user['surveyComplete'] != true) {
          if (!isDeepMatchComplete) {
            Navigator.of(context).pushReplacementNamed(
              '/deep-match/setup',
              arguments: const {'targetRoute': '/survey/intro'},
            );
            return;
          }
          Navigator.of(context).pushReplacementNamed('/survey/intro');
          return;
        }
        Navigator.of(context).pushReplacementNamed('/home');
        return;
      }

      final profileStatus = user['profileCompletionStatus'];
      if (profileStatus != null && profileStatus is Map<String, dynamic>) {
        final nextAction = profileStatus['nextAction'] as String?;
        if (nextAction == 'COMPLETE_SURVEY' && !isDeepMatchComplete) {
          Navigator.of(context).pushReplacementNamed(
            '/deep-match/setup',
            arguments: const {'targetRoute': '/survey/intro'},
          );
          return;
        }
        final route = OnboardingRouter.routeForAction(nextAction);
        Navigator.of(context).pushReplacementNamed(route);
        return;
      }
      Navigator.of(context).pushReplacementNamed('/profile-setup');
    } else {
      Navigator.of(context).pushReplacementNamed('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BondyColors.background,
      body: SafeArea(
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
                  if (_networkError) ...[
                    Icon(
                      Icons.wifi_off_rounded,
                      size: 32,
                      color: BondyColors.textSecondary.withValues(alpha: 0.7),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Không kết nối được máy chủ.',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: BondyColors.textSecondary,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _restoreSession,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Thử lại'),
                    ),
                  ] else ...[
                    const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        color: BondyColors.primary,
                        strokeWidth: 2,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Đang khôi phục phiên...',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: BondyColors.textSecondary,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
