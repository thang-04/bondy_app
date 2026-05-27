import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../theme/app_theme.dart';
import '../../viewmodels/auth/auth_viewmodel.dart';
import '../../widgets/bondy_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _validate() {
    context.read<AuthViewModel>().validateLogin(
      _emailController.text,
      _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
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
                'Đăng nhập',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: BondyColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Nhập email và mật khẩu để tiếp tục.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: BondyColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),
              _AuthField(
                key: const Key('login_email_field'),
                controller: _emailController,
                hintText: 'Email của bạn',
                keyboardType: TextInputType.emailAddress,
                onChanged: (_) => _validate(),
              ),
              const SizedBox(height: 12),
              _AuthField(
                key: const Key('login_password_field'),
                controller: _passwordController,
                hintText: 'Mật khẩu',
                obscureText: true,
                onChanged: (_) => _validate(),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () =>
                      Navigator.of(context).pushNamed('/forgot-password'),
                  child: Text(
                    'Quên mật khẩu?',
                    style: GoogleFonts.plusJakartaSans(
                      color: BondyColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              if (auth.errorMessage != null) ...[
                const SizedBox(height: 8),
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
                key: const Key('login_submit_button'),
                text: auth.isLoading ? 'Đang đăng nhập...' : 'Đăng nhập',
                isLoading: auth.isLoading,
                onPressed: auth.isValid && !auth.isLoading
                    ? () => context.read<AuthViewModel>().loginAndNavigate(
                        context,
                        _emailController.text,
                        _passwordController.text,
                      )
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

class _AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final ValueChanged<String> onChanged;

  const _AuthField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onChanged,
    this.keyboardType,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: BondyColors.divider),
        color: Colors.white,
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        autocorrect: false,
        obscureText: obscureText,
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
        ),
        style: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
