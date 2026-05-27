import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bondy_button.dart';
import '../../viewmodels/auth/auth_viewmodel.dart';

class SignUpPhoneScreen extends StatefulWidget {
  const SignUpPhoneScreen({super.key});

  @override
  State<SignUpPhoneScreen> createState() => _SignUpPhoneScreenState();
}

class _SignUpPhoneScreenState extends State<SignUpPhoneScreen> {
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                'Email\ncủa bạn là gì?',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: BondyColors.textPrimary,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Chúng tôi sẽ gửi mã xác thực đến email này.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: BondyColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),
              // Email input
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: BondyColors.divider),
                  color: Colors.white,
                ),
                child: TextField(
                  key: const Key('auth_email_field'),
                  controller: _phoneController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  onChanged: (value) {
                    context.read<AuthViewModel>().validateEmail(value);
                  },
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
              const Spacer(),
              // Dùng context.watch để tự động bắt sự kiện khi isValid thay đổi
              BondyButton(
                key: const Key('auth_continue_button'),
                text: context.watch<AuthViewModel>().isLoading
                    ? 'Đang gửi...'
                    : 'Tiếp tục',
                onPressed: context.watch<AuthViewModel>().isValid
                    ? () {
                        // Gọi Controller xử lý action submit
                        context.read<AuthViewModel>().sendOtpAndNavigate(
                          context,
                          _phoneController.text,
                        );
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
