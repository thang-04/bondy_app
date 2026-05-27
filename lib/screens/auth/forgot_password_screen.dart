import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../theme/app_theme.dart';
import '../../viewmodels/auth/auth_viewmodel.dart';
import '../../widgets/bondy_button.dart';
import '../../widgets/bondy_logo.dart';
import '../../widgets/common/bondy_feedback.dart';
import '../../widgets/common/bondy_widgets.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();

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
                          'Quên mật khẩu',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: BondyColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Nhập email của bạn để nhận mã xác thực đặt lại mật khẩu.',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color: BondyColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 36),
                        _ForgotPasswordEmailField(
                          key: const Key('forgot_password_email_field'),
                          controller: _emailController,
                          hintText: 'Email của bạn',
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: Icons.email_outlined,
                          autofocus: true,
                          onChanged: context.read<AuthViewModel>().validateEmail,
                        ),
                        const SizedBox(height: 12),
                        BondyInlineError(message: auth.errorMessage),
                        const SizedBox(height: 32),
                        BondyButton(
                          key: const Key('forgot_password_submit_button'),
                          text: auth.isLoading ? 'Đang gửi...' : 'Gửi mã xác thực',
                          isLoading: auth.isLoading,
                          borderRadius: 30,
                          onPressed: auth.isValid && !auth.isLoading
                              ? () => context
                                    .read<AuthViewModel>()
                                    .forgotPasswordAndNavigate(
                                      context,
                                      _emailController.text,
                                    )
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

class _ForgotPasswordEmailField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final IconData prefixIcon;
  final ValueChanged<String> onChanged;
  final bool autofocus;

  const _ForgotPasswordEmailField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onChanged,
    required this.prefixIcon,
    this.keyboardType,
    this.autofocus = false,
  });

  @override
  State<_ForgotPasswordEmailField> createState() => _ForgotPasswordEmailFieldState();
}

class _ForgotPasswordEmailFieldState extends State<_ForgotPasswordEmailField> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: _isFocused ? BondyColors.primary : BondyColors.divider,
          width: _isFocused ? 1.5 : 1,
        ),
        color: _isFocused ? Colors.white : BondyColors.surface,
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: BondyColors.primary.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ]
            : [bondySoftShadow(0.02)],
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        autofocus: widget.autofocus,
        keyboardType: widget.keyboardType,
        autocorrect: false,
        onChanged: widget.onChanged,
        decoration: InputDecoration(
          hintText: widget.hintText,
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Icon(
              widget.prefixIcon,
              color: _isFocused ? BondyColors.primary : BondyColors.textHint,
              size: 22,
            ),
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
          hintStyle: GoogleFonts.manrope(color: BondyColors.textHint, fontSize: 15),
        ),
        style: GoogleFonts.manrope(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: BondyColors.textPrimary,
        ),
      ),
    );
  }
}
