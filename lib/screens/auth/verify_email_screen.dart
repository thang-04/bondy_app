import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../theme/app_theme.dart';
import '../../viewmodels/auth/auth_viewmodel.dart';
import '../../widgets/bondy_button.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _tokenController = TextEditingController();
  bool _isValid = false;

  @override
  void dispose() {
    _tokenController.dispose();
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
                'Xác thực email',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: BondyColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Nhập mã xác nhận đã được gửi đến email của bạn',
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
                  key: const Key('verify_email_token_field'),
                  controller: _tokenController,
                  autocorrect: false,
                  onChanged: (value) => setState(() {
                    _isValid = value.trim().isNotEmpty;
                  }),
                  decoration: InputDecoration(
                    hintText: 'Mã xác nhận',
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
                key: const Key('verify_email_submit_button'),
                text: auth.isLoading ? 'Đang xác nhận...' : 'Xác nhận',
                isLoading: auth.isLoading,
                onPressed: _isValid && !auth.isLoading
                    ? () =>
                          context.read<AuthViewModel>().verifyEmailAndNavigate(
                            context,
                            _tokenController.text.trim(),
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
