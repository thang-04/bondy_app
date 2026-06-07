import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';
import '../../viewmodels/auth/auth_viewmodel.dart';
import '../../widgets/bondy_button.dart';
import '../../widgets/bondy_logo.dart';
import '../../widgets/common/bondy_feedback.dart';
import '../../widgets/common/bondy_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Lắng nghe ViewModel để show popup khi cần liên kết account Google
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AuthViewModel>().addListener(_onAuthChanged);
      }
    });
  }

  void _onAuthChanged() {
    final auth = context.read<AuthViewModel>();
    if (auth.hasPendingGoogleLink && mounted) {
      _showLinkAccountDialog(auth.errorMessage ?? '');
    }
  }

  void _showLinkAccountDialog(String message) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Image.asset(
              'assets/images/google_logo.png',
              width: 22,
              height: 22,
            ),
            const SizedBox(width: 10),
            Text(
              'Liên kết tài khoản',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: GoogleFonts.inter(
            fontSize: 14,
            height: 1.5,
            color: BondyColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Huỷ',
              style: GoogleFonts.inter(color: BondyColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: BondyColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 10,
              ),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              context
                  .read<AuthViewModel>()
                  .confirmLinkGoogleAccount(context);
            },
            child: Text(
              'Liên kết Google',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    if (mounted) {
      context.read<AuthViewModel>().removeListener(_onAuthChanged);
    }
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
                          'Đăng nhập',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: BondyColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Nhập email và mật khẩu để tiếp tục kết nối đồng điệu cảm xúc.',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color: BondyColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 36),
                        _AuthField(
                          key: const Key('login_email_field'),
                          controller: _emailController,
                          hintText: 'Nhập địa chỉ email của bạn',
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: Icons.email_outlined,
                          autofocus: true,
                          onChanged: (_) => _validate(),
                        ),
                        const SizedBox(height: 16),
                        _AuthField(
                          key: const Key('login_password_field'),
                          controller: _passwordController,
                          hintText: 'Nhập mật khẩu',
                          obscureText: true,
                          prefixIcon: Icons.lock_outlined,
                          onChanged: (_) => _validate(),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () =>
                                Navigator.of(context).pushNamed('/forgot-password'),
                            child: Text(
                              'Quên mật khẩu?',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                color: BondyColors.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        BondyInlineError(message: auth.errorMessage),
                        const SizedBox(height: 24),
                        BondyButton(
                          key: const Key('login_submit_button'),
                          text: auth.isLoading ? 'Đang đăng nhập...' : 'Đăng nhập',
                          isLoading: auth.isLoading,
                          borderRadius: 30,
                          onPressed: auth.isValid && !auth.isLoading
                              ? () => context.read<AuthViewModel>().loginAndNavigate(
                                  context,
                                  _emailController.text,
                                  _passwordController.text,
                                )
                              : () {},
                        ),
                        const SizedBox(height: 20),
                        // ─── Divider ───
                        const _OrDivider(),
                        const SizedBox(height: 20),
                        // ─── Nút Google Sign-In ───
                        _GoogleSignInButton(
                          isLoading: auth.isLoading,
                          onPressed: () => context
                              .read<AuthViewModel>()
                              .loginWithGoogleAndNavigate(context),
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

class _AuthField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final IconData prefixIcon;
  final ValueChanged<String> onChanged;
  final bool autofocus;

  const _AuthField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onChanged,
    required this.prefixIcon,
    this.keyboardType,
    this.obscureText = false,
    this.autofocus = false,
  });

  @override
  State<_AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<_AuthField> {
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
                )
              ]
            : [bondySoftShadow(0.02)],
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        autofocus: widget.autofocus,
        keyboardType: widget.keyboardType,
        autocorrect: false,
        obscureText: _obscureText,
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
                      color: _isFocused ? BondyColors.primary : BondyColors.textHint,
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget: Divider "hoặc"
// ─────────────────────────────────────────────────────────────────────────────

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: BondyColors.divider)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'hoặc',
            style: GoogleFonts.inter(
              color: BondyColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ),
        const Expanded(child: Divider(color: BondyColors.divider)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget: Nút đăng nhập bằng Google
// ─────────────────────────────────────────────────────────────────────────────

class _GoogleSignInButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _GoogleSignInButton({
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: AnimatedOpacity(
        opacity: isLoading ? 0.6 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: BondyColors.divider, width: 1.5),
            boxShadow: [bondySoftShadow(0.04)],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/google_logo.png',
                width: 22,
                height: 22,
              ),
              const SizedBox(width: 12),
              Text(
                'Tiếp tục với Google',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: BondyColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
