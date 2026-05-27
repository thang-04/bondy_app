import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../theme/app_theme.dart';
import '../../viewmodels/auth/auth_viewmodel.dart';
import '../../widgets/bondy_button.dart';
import '../../widgets/bondy_logo.dart';
import '../../widgets/common/bondy_feedback.dart';
import '../../widgets/common/bondy_widgets.dart';

class SetNewPasswordScreen extends StatefulWidget {
  final String email;

  const SetNewPasswordScreen({super.key, required this.email});

  @override
  State<SetNewPasswordScreen> createState() => _SetNewPasswordScreenState();
}

class _SetNewPasswordScreenState extends State<SetNewPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _confirmError;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool get _isValid {
    return _passwordController.text.length >= 6 &&
        _confirmPasswordController.text.isNotEmpty;
  }

  void _validateConfirmPassword() {
    setState(() {
      if (_confirmPasswordController.text.isEmpty) {
        _confirmError = null;
      } else if (_passwordController.text != _confirmPasswordController.text) {
        _confirmError = 'Mật khẩu xác nhận không khớp';
      } else {
        _confirmError = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final email = ModalRoute.of(context)?.settings.arguments as String? ?? '';
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
                          'Đặt mật khẩu mới',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: BondyColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Nhập mật khẩu mới để thiết lập lại quyền truy cập tài khoản.',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color: BondyColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 36),
                        _SetNewPasswordTextField(
                          key: const Key('set_new_password_field'),
                          controller: _passwordController,
                          hintText: 'Mật khẩu mới (tối thiểu 6 ký tự)',
                          prefixIcon: Icons.lock_outlined,
                          obscureText: true,
                          autofocus: true,
                          onChanged: (_) {
                            _validateConfirmPassword();
                          },
                        ),
                        const SizedBox(height: 16),
                        _SetNewPasswordTextField(
                          key: const Key('set_new_password_confirm_field'),
                          controller: _confirmPasswordController,
                          hintText: 'Xác nhận mật khẩu mới',
                          prefixIcon: Icons.lock_clock_outlined,
                          obscureText: true,
                          onChanged: (_) {
                            _validateConfirmPassword();
                          },
                          errorText: _confirmError,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              size: 16,
                              color: BondyColors.textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Tối thiểu 6 ký tự',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: BondyColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        BondyInlineError(message: auth.errorMessage),
                        const SizedBox(height: 24),
                        BondyButton(
                          key: const Key('set_new_password_submit_button'),
                          text: auth.isLoading ? 'Đang xác nhận...' : 'Xác nhận',
                          isLoading: auth.isLoading,
                          borderRadius: 30,
                          onPressed: _isValid && _confirmError == null && !auth.isLoading
                              ? () async {
                                  final authViewModel = context.read<AuthViewModel>();
                                  final success = await authViewModel.setPasswordEmailAndNavigate(
                                    context,
                                    email,
                                    _passwordController.text,
                                  );
                                  if (success && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Đặt lại mật khẩu thành công!'),
                                      ),
                                    );
                                    Navigator.of(context).pushNamedAndRemoveUntil(
                                      '/login',
                                      (route) => route.isFirst,
                                    );
                                  }
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

class _SetNewPasswordTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final IconData prefixIcon;
  final ValueChanged<String> onChanged;
  final bool autofocus;
  final String? errorText;

  const _SetNewPasswordTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onChanged,
    required this.prefixIcon,
    this.obscureText = false,
    this.autofocus = false,
    this.errorText,
  });

  @override
  State<_SetNewPasswordTextField> createState() => _SetNewPasswordTextFieldState();
}

class _SetNewPasswordTextFieldState extends State<_SetNewPasswordTextField> {
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
    final hasError = widget.errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: hasError
                  ? BondyColors.error
                  : (_isFocused ? BondyColors.primary : BondyColors.divider),
              width: _isFocused ? 1.5 : 1,
            ),
            color: _isFocused ? Colors.white : BondyColors.surface,
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: hasError
                          ? BondyColors.error.withValues(alpha: 0.08)
                          : BondyColors.primary.withValues(alpha: 0.08),
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
            obscureText: _obscureText,
            autocorrect: false,
            onChanged: widget.onChanged,
            decoration: InputDecoration(
              hintText: widget.hintText,
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Icon(
                  widget.prefixIcon,
                  color: hasError
                      ? BondyColors.error
                      : (_isFocused ? BondyColors.primary : BondyColors.textHint),
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
                          color: hasError
                              ? BondyColors.error
                              : (_isFocused ? BondyColors.primary : BondyColors.textHint),
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
              hintStyle: GoogleFonts.manrope(color: BondyColors.textHint, fontSize: 15),
            ),
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: BondyColors.textPrimary,
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Text(
              widget.errorText!,
              style: GoogleFonts.plusJakartaSans(
                color: BondyColors.error,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }
}