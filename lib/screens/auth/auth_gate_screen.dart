import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

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
    final result = await _authService.restoreSession();
    if (!mounted) return;

    final route = result.status == SessionRestoreStatus.authenticated
        ? _routeForUser(result.user ?? const {})
        : '/onboarding';
    Navigator.of(context).pushReplacementNamed(route);
  }

  String _routeForUser(Map<String, dynamic> userData) {
    final profile = userData['profile'];
    final hasCompletedProfile =
        profile is Map<String, dynamic> &&
        profile['fullName'] != null &&
        profile['gender'] != null &&
        profile['birthDate'] != null;
    return hasCompletedProfile ? '/home' : '/profile-setup';
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: BondyColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Bondy',
              style: TextStyle(
                color: BondyColors.primary,
                fontSize: 36,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 32),
            CircularProgressIndicator(color: BondyColors.primary),
          ],
        ),
      ),
    );
  }
}
