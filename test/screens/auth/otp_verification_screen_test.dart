import 'package:bondy/screens/auth/otp_verification_screen.dart';
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

  testWidgets('successful login resend calls backend and resets countdown', (
    tester,
  ) async {
    final authService = _FakeAuthService(
      requestLoginOtpResult: const SendOtpResult(
        message: 'Đã gửi mã OTP đăng nhập',
      ),
    );

    await _pumpOtpScreen(
      tester,
      authService: authService,
      routeArguments: {
        'email': 'user@example.com',
        'flow': 'login',
        'password': 'Password123',
      },
      resendCooldownSeconds: 1,
    );
    await tester.pump(const Duration(seconds: 1));

    await tester.enterText(find.byKey(const Key('otp_digit_0')), '1');
    await tester.enterText(find.byKey(const Key('otp_digit_1')), '2');
    await tester.tap(find.byKey(const Key('otp_resend_button')));
    await tester.pump();

    expect(authService.requestLoginOtpCalls, 1);
    expect(authService.lastEmail, 'user@example.com');
    expect(authService.lastPassword, 'Password123');
    expect(find.text('Gửi lại mã sau 1s'), findsOneWidget);
    expect(find.text('1'), findsNothing);
    expect(find.text('2'), findsNothing);
  });

  testWidgets(
    'failed resend keeps button available and does not restart timer',
    (tester) async {
      final authService = _FakeAuthService(
        sendOtpError: const AuthServiceException('Không thể gửi lại mã OTP'),
      );

      await _pumpOtpScreen(
        tester,
        authService: authService,
        routeArguments: {'email': 'user@example.com', 'flow': 'signup'},
        resendCooldownSeconds: 1,
      );
      await tester.pump(const Duration(seconds: 1));

      await tester.tap(find.byKey(const Key('otp_resend_button')));
      await tester.pump();

      expect(authService.sendOtpCalls, 1);
      expect(find.byKey(const Key('otp_resend_button')), findsOneWidget);
      expect(find.text('Gửi lại mã sau 1s'), findsNothing);
      expect(find.textContaining('Không thể gửi lại mã OTP'), findsOneWidget);
    },
  );
}

Future<void> _pumpOtpScreen(
  WidgetTester tester, {
  required _FakeAuthService authService,
  required Map<String, dynamic> routeArguments,
  required int resendCooldownSeconds,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      onGenerateRoute: (_) => MaterialPageRoute<void>(
        settings: RouteSettings(arguments: routeArguments),
        builder: (_) => ChangeNotifierProvider(
          create: (_) => AuthViewModel(authService: authService),
          child: OtpVerificationScreen(
            resendCooldownSeconds: resendCooldownSeconds,
          ),
        ),
      ),
    ),
  );
}

class _FakeAuthService extends AuthService {
  _FakeAuthService({
    this.sendOtpResult = const SendOtpResult(message: 'Đã gửi mã OTP'),
    this.requestLoginOtpResult = const SendOtpResult(message: 'Đã gửi mã OTP'),
    this.sendOtpError,
  }) : super(baseUrlOverride: 'https://api.example.com/api');

  final SendOtpResult sendOtpResult;
  final SendOtpResult requestLoginOtpResult;
  final Object? sendOtpError;

  int sendOtpCalls = 0;
  int requestLoginOtpCalls = 0;
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
}
