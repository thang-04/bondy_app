import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../theme/app_theme.dart';
import '../../viewmodels/auth/auth_viewmodel.dart';
import '../../widgets/bondy_button.dart';
import '../../widgets/bondy_logo.dart';

class VerifyOtpScreen extends StatefulWidget {
  final String email;

  const VerifyOtpScreen({super.key, required this.email});

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isComplete = false;

  static const int _initialSeconds = 300; // 5 minutes
  late int _remainingSeconds;
  bool _isExpired = false;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = _initialSeconds;
    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _isExpired = true;
          timer.cancel();
        }
      });
    });
  }

  String get _formattedTime {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _handleResend() async {
    if (_isExpired || !mounted) return;

    final success = await context.read<AuthViewModel>().resendOtp(
      context,
      email: widget.email,
      flow: 'password_reset',
    );

    if (!mounted || !success) return;

    setState(() {
      for (final controller in _controllers) {
        controller.clear();
      }
      _focusNodes.first.requestFocus();
      _remainingSeconds = _initialSeconds;
      _isExpired = false;
      _isComplete = false;
    });
    _startCountdown();
  }

  Future<void> _handleVerify() async {
    if (_isExpired) return;

    final otp = _controllers.map((c) => c.text).join();
    if (otp.length != 6) return;

    final auth = context.read<AuthViewModel>();
    await auth.verifyOtpAndNavigate(
      context,
      widget.email,
      otp,
      'password_reset',
    );

    // If verify succeeded, navigate to set-new-password
    if (auth.errorMessage == null && mounted) {
      Navigator.of(context).pushNamed('/set-new-password', arguments: widget.email);
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                        const Center(
                          child: BondyLogo(size: 140),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Xác thực mã OTP',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: BondyColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Nhập mã 6 số đã được gửi đến email ${widget.email} của bạn.',
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
                            final isFilled = _controllers[index].text.isNotEmpty;
                            return SizedBox(
                              width: 48,
                              height: 58,
                              child: TextField(
                                key: Key('verify_otp_digit_$index'),
                                controller: _controllers[index],
                                focusNode: _focusNodes[index],
                                autofocus: index == 0,
                                enabled: !_isExpired,
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
                                  setState(() {
                                    _isComplete = _controllers.every((c) => c.text.isNotEmpty);
                                  });
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
                                      ? BondyColors.primaryLight.withValues(alpha: 0.4)
                                      : Colors.white,
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 24),
                        // Countdown timer
                        Center(
                          child: _isExpired
                              ? Text(
                                  'Mã đã hết hạn. Vui lòng yêu cầu mã mới.',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    color: BondyColors.error,
                                    fontWeight: FontWeight.w600,
                                  ),
                                )
                              : Text(
                                  'Mã hết hạn sau: $_formattedTime',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    color: BondyColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 48),
                        BondyButton(
                          key: const Key('verify_otp_confirm_button'),
                          text: isLoading
                              ? 'Đang xác thực...'
                              : _isExpired
                                  ? 'Mã đã hết hạn'
                                  : 'Xác nhận',
                          isLoading: isLoading,
                          borderRadius: 30,
                          onPressed: _isComplete && !_isExpired && !isLoading
                              ? _handleVerify
                              : () {},
                        ),
                        const SizedBox(height: 20),
                        // Resend button
                        Center(
                          child: TextButton(
                            key: const Key('verify_otp_resend_button'),
                            onPressed: !_isExpired && !isLoading ? _handleResend : null,
                            child: Text(
                              'Chưa nhận được mã? Gửi lại',
                              style: GoogleFonts.plusJakartaSans(
                                color: _isExpired
                                    ? BondyColors.textHint
                                    : BondyColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
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