import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../theme/app_theme.dart';
import '../../viewmodels/auth/auth_viewmodel.dart';
import '../../widgets/bondy_button.dart';

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
                'Quên mật khẩu',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: BondyColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Nhập email để nhận link đặt lại mật khẩu',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: BondyColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: BondyColors.divider),
                  color: Colors.white,
                ),
                child: TextField(
                  key: const Key('forgot_password_email_field'),
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  onChanged: context.read<AuthViewModel>().validateEmail,
                  decoration: InputDecoration(
                    hintText: 'Email của bạn',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
                    ),
                    hintStyle: GoogleFonts.plusJakartaSans(
                      color: BondyColors.textHint,
                    ),
                  ),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
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
                key: const Key('forgot_password_submit_button'),
                text: auth.isLoading ? 'Đang gửi...' : 'Gửi link đặt lại',
                isLoading: auth.isLoading,
                onPressed: auth.isValid && !auth.isLoading
                    ? () => context
                          .read<AuthViewModel>()
                          .forgotPasswordAndNavigate(
                            context,
                            _emailController.text,
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
