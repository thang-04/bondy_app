import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../theme/app_theme.dart';
import '../../viewmodels/auth/auth_viewmodel.dart';
import '../../widgets/bondy_button.dart';
import '../../widgets/bondy_logo.dart';
import '../../widgets/common/bondy_feedback.dart';
import '../../widgets/common/bondy_widgets.dart';

class SetPasswordScreen extends StatefulWidget {
  const SetPasswordScreen({super.key});

  @override
  State<SetPasswordScreen> createState() => _SetPasswordScreenState();
}

class _SetPasswordScreenState extends State<SetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isValid = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _validate() {
    setState(() {
      _isValid =
          _passwordController.text.length >= 6 &&
          _passwordController.text == _confirmPasswordController.text;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final email = ModalRoute.of(context)?.settings.arguments?.toString() ?? '';

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
                          'Tạo mật khẩu',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: BondyColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          email.isEmpty
                              ? 'Tạo mật khẩu để hoàn tất tài khoản của bạn.'
                              : 'Email $email đã xác thực. Tạo mật khẩu để hoàn tất tài khoản.',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color: BondyColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 36),
                        _SetPasswordTextField(
                          key: const Key('register_password_field'),
                          controller: _passwordController,
                          hintText: 'Mật khẩu (tối thiểu 6 ký tự)',
                          prefixIcon: Icons.lock_outlined,
                          obscureText: true,
                          autofocus: true,
                          onChanged: (_) => _validate(),
                        ),
                        const SizedBox(height: 16),
                        _SetPasswordTextField(
                          key: const Key('register_confirm_password_field'),
                          controller: _confirmPasswordController,
                          hintText: 'Nhập lại mật khẩu',
                          prefixIcon: Icons.lock_clock_outlined,
                          obscureText: true,
                          onChanged: (_) => _validate(),
                        ),
                        const SizedBox(height: 12),
                        BondyInlineError(message: auth.errorMessage),
                        const SizedBox(height: 24),
                        BondyButton(
                          key: const Key('register_submit_button'),
                          text: auth.isLoading
                              ? 'Đang tạo...'
                              : 'Tạo tài khoản',
                          isLoading: auth.isLoading,
                          borderRadius: 30,
                          onPressed: _isValid && !auth.isLoading
                              ? () => context
                                    .read<AuthViewModel>()
                                    .setPasswordAndNavigate(
                                      context,
                                      _passwordController.text,
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

class _SetPasswordTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final IconData prefixIcon;
  final ValueChanged<String> onChanged;
  final bool autofocus;

  const _SetPasswordTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onChanged,
    required this.prefixIcon,
    this.obscureText = false,
    this.autofocus = false,
  });

  @override
  State<_SetPasswordTextField> createState() => _SetPasswordTextFieldState();
}

class _SetPasswordTextFieldState extends State<_SetPasswordTextField> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
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
                ),
              ]
            : [bondySoftShadow(0.02)],
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        autofocus: widget.autofocus,
        obscureText: _obscureText,
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
          suffixIcon: widget.obscureText
              ? Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: IconButton(
                    icon: Icon(
                      _obscureText
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: _isFocused
                          ? BondyColors.primary
                          : BondyColors.textHint,
                      size: 22,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  ),
                )
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
          hintStyle: GoogleFonts.manrope(
            color: BondyColors.textHint,
            fontSize: 15,
          ),
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
