import 'package:bondy/screens/auth/login_screen.dart';
import 'package:bondy/services/auth_service.dart';
import 'package:bondy/viewmodels/auth/auth_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('submits password login instead of requesting login OTP', (
    tester,
  ) async {
    final authService = _FakeAuthService();

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthViewModel(authService: authService),
        child: MaterialApp(
          routes: {
            '/': (context) => const LoginScreen(),
            '/home': (context) => const Scaffold(body: Text('home')),
            '/profile-setup': (context) =>
                const Scaffold(body: Text('profile setup')),
            '/otp': (context) => const Scaffold(body: Text('otp')),
            '/forgot-password': (context) =>
                const Scaffold(body: Text('forgot password')),
          },
        ),
      ),
    );

    expect(find.text('Đăng nhập'), findsWidgets);
    expect(find.text('Gửi OTP xác nhận'), findsNothing);

    await tester.enterText(
      find.byKey(const Key('login_email_field')),
      'user@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('login_password_field')),
      'Password123',
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('login_submit_button')));
    await tester.pumpAndSettle();

    expect(authService.loginCalls, 1);
    expect(authService.requestLoginOtpCalls, 0);
    expect(authService.lastEmail, 'user@example.com');
    expect(authService.lastPassword, 'Password123');
    expect(find.text('home'), findsOneWidget);
    expect(find.text('otp'), findsNothing);
  });
}

class _FakeAuthService extends AuthService {
  _FakeAuthService() : super(baseUrlOverride: 'https://api.example.com/api');

  int loginCalls = 0;
  int requestLoginOtpCalls = 0;
  String? lastEmail;
  String? lastPassword;

  @override
  Future<LoginResult> login({
    required String email,
    required String password,
  }) async {
    loginCalls++;
    lastEmail = email;
    lastPassword = password;
    return const LoginResult(
      userId: 'user-id',
      email: 'user@example.com',
      name: 'User',
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
    );
  }

  @override
  Future<SendOtpResult> requestLoginOtp({
    required String email,
    required String password,
  }) async {
    requestLoginOtpCalls++;
    lastEmail = email;
    lastPassword = password;
    return const SendOtpResult(message: 'Đã gửi mã OTP');
  }

  @override
  Future<Map<String, dynamic>> getCurrentUser() async {
    return const {
      'id': 'user-id',
      'email': 'user@example.com',
      'profile': {
        'fullName': 'User',
        'gender': 'MALE',
        'birthDate': '2000-01-01',
      },
    };
  }
}
