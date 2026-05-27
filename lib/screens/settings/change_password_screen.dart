import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../theme/app_theme.dart';
import '../../viewmodels/auth/auth_viewmodel.dart';
import '../../widgets/bondy_button.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  bool _isValid = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  void _validate() {
    setState(() {
      _isValid =
          _currentPasswordController.text.isNotEmpty &&
          _newPasswordController.text.length >= 6;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthViewModel>(context, listen: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đổi mật khẩu'),
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
                'Đổi mật khẩu',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: BondyColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Nhập mật khẩu hiện tại và mật khẩu mới',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: BondyColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),
              _PasswordField(
                key: const Key('change_password_current_field'),
                controller: _currentPasswordController,
                hintText: 'Mật khẩu hiện tại',
                onChanged: (_) => _validate(),
              ),
              const SizedBox(height: 12),
              _PasswordField(
                key: const Key('change_password_new_field'),
                controller: _newPasswordController,
                hintText: 'Mật khẩu mới (tối thiểu 6 ký tự)',
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
                key: const Key('change_password_submit_button'),
                text: auth.isLoading ? 'Đang đổi...' : 'Đổi mật khẩu',
                isLoading: auth.isLoading,
                onPressed: _isValid && !auth.isLoading
                    ? () => context.read<AuthViewModel>().changePassword(
                        context,
                        _currentPasswordController.text,
                        _newPasswordController.text,
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

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;

  const _PasswordField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onChanged,
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
        obscureText: true,
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
