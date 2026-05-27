import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../theme/app_theme.dart';
import '../../viewmodels/auth/auth_viewmodel.dart';
import '../../widgets/bondy_button.dart';

class VerifyOtpScreen extends StatefulWidget {
  final String email;

  const VerifyOtpScreen({super.key, required this.email});

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final _otpController = TextEditingController();
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
      _otpController.clear();
      _remainingSeconds = _initialSeconds;
      _isExpired = false;
    });
    _startCountdown();
  }

  Future<void> _handleVerify() async {
    if (_isExpired) return;

    final otp = _otpController.text.trim();
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
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthViewModel>().isLoading;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Bondy',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: BondyColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                'Xác thực mã OTP',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: BondyColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Nhập mã đã gửi đến ${widget.email}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: BondyColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: BondyColors.divider),
                  color: Colors.white,
                ),
                child: TextField(
                  key: const Key('verify_otp_input'),
                  controller: _otpController,
                  enabled: !_isExpired,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _isComplete = value.length == 6;
                    });
                  },
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 4,
                  ),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: '------',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      color: BondyColors.textHint,
                      fontSize: 20,
                      letterSpacing: 8,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Countdown timer
              if (_isExpired)
                Text(
                  'Mã đã hết hạn. Vui lòng yêu cầu mã mới.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: BondyColors.error,
                  ),
                )
              else
                Text(
                  'Mã hết hạn sau: $_formattedTime',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: BondyColors.textSecondary,
                  ),
                ),
              const Spacer(),
              BondyButton(
                key: const Key('verify_otp_confirm_button'),
                text: isLoading
                    ? 'Đang xác thực...'
                    : _isExpired
                        ? 'Mã đã hết hạn'
                        : 'Xác nhận',
                isLoading: isLoading,
                onPressed: _isComplete && !_isExpired && !isLoading
                    ? _handleVerify
                    : () {},
              ),
              const SizedBox(height: 16),
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
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}