import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../theme/app_theme.dart';
import '../../viewmodels/auth/auth_viewmodel.dart';
import '../../widgets/bondy_button.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _tokenController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isValid = false;

  @override
  void dispose() {
    _tokenController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _validate() {
    setState(() {
      _isValid =
          _tokenController.text.trim().isNotEmpty &&
          _passwordController.text.length >= 6;
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
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                'Đặt lại mật khẩu',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: BondyColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                email.isEmpty
                    ? 'Nhập mã xác nhận từ email và mật khẩu mới'
                    : 'Nhập mã xác nhận đã gửi đến $email',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: BondyColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),
              _ResetField(
                key: const Key('reset_password_token_field'),
                controller: _tokenController,
                hintText: 'Mã xác nhận',
                onChanged: (_) => _validate(),
              ),
              const SizedBox(height: 12),
              _ResetField(
                key: const Key('reset_password_new_password_field'),
                controller: _passwordController,
                hintText: 'Mật khẩu mới (tối thiểu 6 ký tự)',
                obscureText: true,
                onChanged: (_) => _validate(),
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
                key: const Key('reset_password_submit_button'),
                text: auth.isLoading ? 'Đang đặt lại...' : 'Đặt lại mật khẩu',
                isLoading: auth.isLoading,
                onPressed: _isValid && !auth.isLoading
                    ? () => context
                          .read<AuthViewModel>()
                          .resetPasswordAndNavigate(
                            context,
                            _tokenController.text.trim(),
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

class _ResetField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final ValueChanged<String> onChanged;

  const _ResetField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onChanged,
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
        obscureText: obscureText,
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
        ),
        style: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
