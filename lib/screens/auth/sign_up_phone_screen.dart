import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bondy_button.dart';
import '../../widgets/bondy_logo.dart';
import '../../viewmodels/auth/auth_viewmodel.dart';
import '../../widgets/common/bondy_widgets.dart';

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
                          'Email\ncủa bạn là gì?',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: BondyColors.textPrimary,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Chúng tôi sẽ gửi mã xác thực gồm 6 chữ số đến email này để xác nhận tài khoản.',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color: BondyColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 36),
                        // Email input
                        _SignUpEmailField(
                          key: const Key('auth_email_field'),
                          controller: _phoneController,
                          hintText: 'Email của bạn',
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: Icons.email_outlined,
                          autofocus: true,
                          onChanged: (value) {
                            context.read<AuthViewModel>().validateEmail(value);
                          },
                        ),
                        const SizedBox(height: 48),
                        BondyButton(
                          key: const Key('auth_continue_button'),
                          text: auth.isLoading ? 'Đang gửi...' : 'Tiếp tục',
                          isLoading: auth.isLoading,
                          borderRadius: 30,
                          onPressed: auth.isValid && !auth.isLoading
                              ? () {
                                  context
                                      .read<AuthViewModel>()
                                      .sendOtpAndNavigate(
                                        context,
                                        _phoneController.text,
                                      );
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

class _SignUpEmailField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final IconData prefixIcon;
  final ValueChanged<String> onChanged;
  final bool autofocus;

  const _SignUpEmailField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onChanged,
    required this.prefixIcon,
    this.keyboardType,
    this.autofocus = false,
  });

  @override
  State<_SignUpEmailField> createState() => _SignUpEmailFieldState();
}

class _SignUpEmailFieldState extends State<_SignUpEmailField> {
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
                ),
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
