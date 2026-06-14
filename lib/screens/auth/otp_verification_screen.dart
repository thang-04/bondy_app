import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/auth/auth_viewmodel.dart';
import '../../widgets/bondy_button.dart';
import '../../widgets/bondy_logo.dart';

class OtpVerificationScreen extends StatefulWidget {
  final int resendCooldownSeconds;

  const OtpVerificationScreen({super.key, this.resendCooldownSeconds = 60});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  late int _resendSeconds;
  bool _canResend = false;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    _resendSeconds = widget.resendCooldownSeconds;
    _startTimer();
  }

  void _startTimer() {
    _resendTimer?.cancel();
    if (_resendSeconds <= 0) {
      setState(() {
        _canResend = true;
      });
      return;
    }
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _resendSeconds--;
        if (_resendSeconds <= 0) {
          _resendSeconds = 0;
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  void _clearOtpFields() {
    for (final controller in _controllers) {
      controller.clear();
    }
    _focusNodes.first.requestFocus();
  }

  Future<void> _handleResend({
    required String email,
    required String flow,
    String? password,
  }) async {
    if (!_canResend) return;
    final success = await context.read<AuthViewModel>().resendOtp(
      context,
      email: email,
      flow: flow,
      password: password,
    );
    if (!mounted || !success) return;

    setState(() {
      _clearOtpFields();
      _resendSeconds = widget.resendCooldownSeconds;
      _canResend = false;
    });
    _startTimer();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  bool get _isComplete => _controllers.every((c) => c.text.isNotEmpty);

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final email = args is Map<String, dynamic>
        ? args['email']?.toString() ?? ''
        : args?.toString() ?? '';
    final flow = args is Map<String, dynamic>
        ? args['flow']?.toString() ?? 'signup'
        : 'signup';
    final password = args is Map<String, dynamic>
        ? args['password']?.toString()
        : null;
    final isLoading = context.watch<AuthViewModel>().isLoading;

    return Scaffold(
      backgroundColor: BondyColors.background,
      body: Stack(
        children: [
          // Background blurs
          Positioned(
            top: -48,
            right: -48,
            child: IgnorePointer(
              child: Container(
                width: 256,
                height: 256,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: BondyColors.primary.withValues(alpha: 0.08),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -96,
            left: -96,
            child: IgnorePointer(
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF92348E).withValues(alpha: 0.12),
                ),
              ),
            ),
          ),
          // Scrollable Content
          SafeArea(
            child: Column(
              children: [
                // Custom AppBar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        // Small glowing logo header
                        const Center(child: BondyLogo(size: 140)),
                        const SizedBox(height: 24),
                        Text(
                          'Nhập mã xác thực',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: BondyColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Mã gồm 6 số đã được gửi đến email $email của bạn.',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color: BondyColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 36),
                        // OTP fields
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(6, (index) {
                            final isFilled =
                                _controllers[index].text.isNotEmpty;
                            return SizedBox(
                              width: 48,
                              height: 58,
                              child: TextField(
                                key: Key('otp_digit_$index'),
                                controller: _controllers[index],
                                focusNode: _focusNodes[index],
                                autofocus: index == 0,
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(1),
                                ],
                                onChanged: (value) {
                                  if (value.isNotEmpty && index < 5) {
                                    _focusNodes[index + 1].requestFocus();
                                  }
                                  if (value.isEmpty && index > 0) {
                                    _focusNodes[index - 1].requestFocus();
                                  }
                                  setState(() {});
                                },
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: BondyColors.textPrimary,
                                ),
                                decoration: InputDecoration(
                                  contentPadding: EdgeInsets.zero,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24),
                                    borderSide: BorderSide(
                                      color: isFilled
                                          ? BondyColors.primary
                                          : BondyColors.divider,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24),
                                    borderSide: BorderSide(
                                      color: isFilled
                                          ? BondyColors.primary
                                          : BondyColors.divider,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24),
                                    borderSide: const BorderSide(
                                      color: BondyColors.primary,
                                      width: 2,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: isFilled
                                      ? BondyColors.primaryLight.withValues(
                                          alpha: 0.4,
                                        )
                                      : Colors.white,
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 24),
                        // Resend
                        Center(
                          child: _canResend
                              ? TextButton(
                                  key: const Key('otp_resend_button'),
                                  onPressed: isLoading
                                      ? null
                                      : () => _handleResend(
                                          email: email,
                                          flow: flow,
                                          password: password,
                                        ),
                                  child: Text(
                                    'Gửi lại mã',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: BondyColors.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                )
                              : Text(
                                  key: const Key('otp_resend_countdown'),
                                  'Gửi lại mã sau ${_resendSeconds}s',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: BondyColors.textHint,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 48),
                        BondyButton(
                          key: const Key('otp_confirm_button'),
                          text: isLoading ? 'Đang xác nhận...' : 'Xác nhận',
                          borderRadius: 30,
                          onPressed: _isComplete && !isLoading
                              ? () {
                                  final otp = _controllers
                                      .map((controller) => controller.text)
                                      .join();
                                  context
                                      .read<AuthViewModel>()
                                      .verifyOtpAndNavigate(
                                        context,
                                        email,
                                        otp,
                                        flow,
                                      );
                                }
                              : () {},
                        ),
                        const SizedBox(height: 48),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
