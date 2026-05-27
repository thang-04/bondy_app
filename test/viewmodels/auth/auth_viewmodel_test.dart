import 'package:bondy/services/auth_service.dart';
import 'package:bondy/viewmodels/auth/auth_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('signup resend calls sendOtp and keeps production devOtp null', (
    tester,
  ) async {
    final authService = _FakeAuthService(
      sendOtpResult: const SendOtpResult(message: 'Đã gửi mã OTP'),
    );
    final viewModel = AuthViewModel(authService: authService);
    late BuildContext context;

    await tester.pumpWidget(
      _ContextHarness(onContext: (value) => context = value),
    );

    final result = await viewModel.resendOtp(
      context,
      email: 'user@example.com',
      flow: 'signup',
    );

    expect(result, isTrue);
    expect(authService.sendOtpCalls, 1);
    expect(authService.requestLoginOtpCalls, 0);
    expect(authService.lastEmail, 'user@example.com');
    expect(viewModel.devOtp, isNull);
    expect(viewModel.errorMessage, isNull);
  });

  testWidgets('login resend calls requestLoginOtp with email and password', (
    tester,
  ) async {
    final authService = _FakeAuthService(
      requestLoginOtpResult: const SendOtpResult(
        message: 'Đã gửi mã OTP đăng nhập',
        devOtp: '123456',
      ),
    );
    final viewModel = AuthViewModel(authService: authService);
    late BuildContext context;

    await tester.pumpWidget(
      _ContextHarness(onContext: (value) => context = value),
    );

    final result = await viewModel.resendOtp(
      context,
      email: 'user@example.com',
      flow: 'login',
      password: 'Password123',
    );

    expect(result, isTrue);
    expect(authService.requestLoginOtpCalls, 1);
    expect(authService.sendOtpCalls, 0);
    expect(authService.lastEmail, 'user@example.com');
    expect(authService.lastPassword, 'Password123');
    expect(viewModel.devOtp, '123456');
  });

  testWidgets('resend failure returns false and sets Vietnamese error', (
    tester,
  ) async {
    final authService = _FakeAuthService(
      sendOtpError: const AuthServiceException('Không thể gửi OTP lúc này'),
    );
    final viewModel = AuthViewModel(authService: authService);
    late BuildContext context;

    await tester.pumpWidget(
      _ContextHarness(onContext: (value) => context = value),
    );

    final result = await viewModel.resendOtp(
      context,
      email: 'user@example.com',
      flow: 'signup',
    );
    await tester.pump();

    expect(result, isFalse);
    expect(viewModel.errorMessage, contains('Không thể gửi OTP'));
    expect(find.textContaining('Không thể gửi OTP'), findsOneWidget);
  });

  testWidgets('login resend without password fails without backend call', (
    tester,
  ) async {
    final authService = _FakeAuthService();
    final viewModel = AuthViewModel(authService: authService);
    late BuildContext context;

    await tester.pumpWidget(
      _ContextHarness(onContext: (value) => context = value),
    );

    final result = await viewModel.resendOtp(
      context,
      email: 'user@example.com',
      flow: 'login',
    );
    await tester.pump();

    expect(result, isFalse);
    expect(authService.requestLoginOtpCalls, 0);
    expect(authService.sendOtpCalls, 0);
    expect(viewModel.errorMessage, contains('mật khẩu'));
  });

  testWidgets('login navigation submits password login without OTP', (
    tester,
  ) async {
    final authService = _FakeAuthService();
    final viewModel = AuthViewModel(authService: authService);

    await tester.pumpWidget(
      MaterialApp(
        routes: {
          '/': (context) => Scaffold(
            body: TextButton(
              onPressed: () => viewModel.loginAndNavigate(
                context,
                'user@example.com',
                'Password123',
              ),
              child: const Text('login'),
            ),
          ),
          '/home': (context) => const Scaffold(body: Text('home')),
          '/profile-setup': (context) =>
              const Scaffold(body: Text('profile setup')),
          '/otp': (context) => const Scaffold(body: Text('otp')),
        },
      ),
    );

    await tester.tap(find.text('login'));
    await tester.pumpAndSettle();

    expect(authService.loginCalls, 1);
    expect(authService.requestLoginOtpCalls, 0);
    expect(authService.lastEmail, 'user@example.com');
    expect(authService.lastPassword, 'Password123');
    expect(find.text('home'), findsOneWidget);
    expect(find.text('otp'), findsNothing);
  });
}

class _ContextHarness extends StatelessWidget {
  final ValueChanged<BuildContext> onContext;

  const _ContextHarness({required this.onContext});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) {
            onContext(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _FakeAuthService extends AuthService {
  _FakeAuthService({
    this.sendOtpResult = const SendOtpResult(message: 'Đã gửi mã OTP'),
    this.requestLoginOtpResult = const SendOtpResult(message: 'Đã gửi mã OTP'),
    this.sendOtpError,
  }) : super(baseUrlOverride: 'https://api.example.com/api');

  final SendOtpResult sendOtpResult;
  final SendOtpResult requestLoginOtpResult;
  final LoginResult loginResult = const LoginResult(
    userId: 'user-id',
    email: 'user@example.com',
    name: 'User',
    accessToken: 'access-token',
    refreshToken: 'refresh-token',
  );
  final Object? sendOtpError;

  int sendOtpCalls = 0;
  int requestLoginOtpCalls = 0;
  int loginCalls = 0;
  String? lastEmail;
  String? lastPassword;

  @override
  Future<SendOtpResult> sendOtp(String email) async {
    sendOtpCalls++;
    lastEmail = email;
    final error = sendOtpError;
    if (error != null) throw error;
    return sendOtpResult;
  }

  @override
  Future<SendOtpResult> requestLoginOtp({
    required String email,
    required String password,
  }) async {
    requestLoginOtpCalls++;
    lastEmail = email;
    lastPassword = password;
    return requestLoginOtpResult;
  }

  @override
  Future<LoginResult> login({
    required String email,
    required String password,
  }) async {
    loginCalls++;
    lastEmail = email;
    lastPassword = password;
    return loginResult;
  }

  @override
  Future<Map<String, dynamic>> getCurrentUser() async {
    return {
      'id': loginResult.userId,
      'email': loginResult.email,
      'profile': {
        'fullName': loginResult.name,
        'gender': 'MALE',
        'birthDate': '2000-01-01',
      },
    };
  }
}
