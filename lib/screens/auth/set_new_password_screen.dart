import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../theme/app_theme.dart';
import '../../viewmodels/auth/auth_viewmodel.dart';
import '../../widgets/bondy_button.dart';

class SetNewPasswordScreen extends StatefulWidget {
  final String email;

  const SetNewPasswordScreen({super.key, required this.email});

  @override
  State<SetNewPasswordScreen> createState() => _SetNewPasswordScreenState();
}

class _SetNewPasswordScreenState extends State<SetNewPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
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
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Bondy',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: BondyColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                'Đặt mật khẩu mới',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: BondyColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                email.isEmpty
                    ? 'Nhập mật khẩu mới cho tài khoản'
                    : 'Nhập mật khẩu mới cho tài khoản',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: BondyColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),
              _PasswordField(
                controller: _passwordController,
                hintText: 'Mật khẩu mới',
                isObscured: _obscurePassword,
                onToggleVisibility: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
                onChanged: (_) {
                  _validateConfirmPassword();
                },
              ),
              const SizedBox(height: 12),
              _PasswordField(
                controller: _confirmPasswordController,
                hintText: 'Xác nhận mật khẩu mới',
                isObscured: _obscureConfirmPassword,
                onToggleVisibility: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
                onChanged: (_) {
                  _validateConfirmPassword();
                },
                errorText: _confirmError,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 16,
                    color: BondyColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Tối thiểu 6 ký tự',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: BondyColors.textSecondary,
                    ),
                  ),
                ],
              ),
              if (auth.errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  auth.errorMessage!,
                  style: GoogleFonts.plusJakartaSans(
                    color: BondyColors.error,
                    fontSize: 13,
                  ),
                ),
              ],
              const Spacer(),
              BondyButton(
                key: const Key('set_new_password_submit_button'),
                text: auth.isLoading ? 'Đang xác nhận...' : 'Xác nhận',
                isLoading: auth.isLoading,
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
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool isObscured;
  final VoidCallback onToggleVisibility;
  final ValueChanged<String> onChanged;
  final String? errorText;

  const _PasswordField({
    required this.controller,
    required this.hintText,
    required this.isObscured,
    required this.onToggleVisibility,
    required this.onChanged,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: errorText != null ? BondyColors.error : BondyColors.divider,
            ),
            color: Colors.white,
          ),
          child: TextField(
            controller: controller,
            obscureText: isObscured,
            autocorrect: false,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: hintText,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 18,
              ),
              hintStyle: GoogleFonts.plusJakartaSans(color: BondyColors.textHint),
              suffixIcon: IconButton(
                icon: Icon(
                  isObscured ? Icons.visibility_off : Icons.visibility,
                  color: BondyColors.textSecondary,
                ),
                onPressed: onToggleVisibility,
              ),
            ),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Text(
            errorText!,
            style: GoogleFonts.plusJakartaSans(
              color: BondyColors.error,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}