import 'package:flutter/material.dart';

import '../../services/profile_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bondy_button.dart';
import '../../widgets/common/bondy_feedback.dart';
import '../../widgets/common/bondy_widgets.dart';

/// Dedicated full-screen flow for deleting an account.
///
/// Previously this lived inside [ProfilePrivacyScreen] as a small inline
/// AlertDialog. App-store reviewers (and GDPR) expect a more prominent,
/// reviewable surface that explains consequences and requires re-entry of
/// the password + an explicit "DELETE" confirmation string.
class AccountDeleteScreen extends StatefulWidget {
  const AccountDeleteScreen({super.key});

  @override
  State<AccountDeleteScreen> createState() => _AccountDeleteScreenState();
}

class _AccountDeleteScreenState extends State<AccountDeleteScreen> {
  final ProfileService _profileService = ProfileService();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _submitting = false;

  static const _confirmPhrase = 'XÓA';

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      !_submitting &&
      _passwordController.text.trim().isNotEmpty &&
      _confirmController.text.trim().toUpperCase() == _confirmPhrase;

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() => _submitting = true);
    try {
      await _profileService.deleteAccount(password: _passwordController.text);
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil('/onboarding', (_) => false);
    } catch (e) {
      if (!mounted) return;
      BondyFeedback.showError(context, e);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BondyColors.background,
      appBar: AppBar(title: const Text('Xóa tài khoản')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: BondyColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: BondyColors.error.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_rounded, color: BondyColors.error),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Hành động này không thể hoàn tác. Hồ sơ, ảnh, matches và tin nhắn sẽ bị ẩn danh theo chính sách Bondy.',
                        style: bondyText(
                          size: 13,
                          weight: FontWeight.w600,
                          color: BondyColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Sẽ xảy ra điều gì khi bạn xóa?',
                style: bondyText(size: 16, weight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const _BulletItem(
                text: 'Hồ sơ và ảnh sẽ được ẩn danh ngay lập tức.',
              ),
              const _BulletItem(
                text:
                    'Tin nhắn còn lại sẽ giữ làm bằng chứng nếu có khiếu nại an toàn.',
              ),
              const _BulletItem(
                text:
                    'Subscription chưa hết hạn sẽ KHÔNG được hoàn tiền tự động — liên hệ hỗ trợ trước.',
              ),
              const _BulletItem(
                text: 'Bạn cần đăng ký lại từ đầu nếu muốn quay lại sau này.',
              ),
              const SizedBox(height: 24),
              Text(
                'Mật khẩu hiện tại',
                style: bondyText(weight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: true,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Nhập mật khẩu để xác nhận',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Nhập "$_confirmPhrase" để xác nhận',
                style: bondyText(weight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _confirmController,
                textCapitalization: TextCapitalization.characters,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Gõ XÓA bằng chữ in hoa',
                  prefixIcon: Icon(Icons.keyboard_alt_outlined),
                ),
              ),
              const SizedBox(height: 24),
              BondyButton(
                text: _submitting ? 'Đang xóa...' : 'Xóa tài khoản vĩnh viễn',
                isLoading: _submitting,
                isOutlined: false,
                onPressed: _canSubmit ? _submit : () {},
              ),
              const SizedBox(height: 12),
              BondyButton(
                text: 'Hủy',
                isOutlined: true,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BulletItem extends StatelessWidget {
  final String text;
  const _BulletItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6, right: 10),
            child: Icon(
              Icons.circle,
              size: 6,
              color: BondyColors.textSecondary,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: bondyText(
                size: 14,
                color: BondyColors.textSecondary,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
