import 'package:flutter/material.dart';

import '../../services/profile_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/bondy_feedback.dart';
import '../../widgets/common/bondy_widgets.dart';

class ProfilePrivacyScreen extends StatefulWidget {
  const ProfilePrivacyScreen({super.key});

  @override
  State<ProfilePrivacyScreen> createState() => _ProfilePrivacyScreenState();
}

class _ProfilePrivacyScreenState extends State<ProfilePrivacyScreen> {
  final ProfileService _profileService = ProfileService();
  bool _visible = true;
  bool _loading = true;
  bool _saving = false;
  SnoozeStatus? _snooze;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _profileService.getProfile(),
        _profileService.getSnoozeStatus(),
      ]);
      if (!mounted) return;
      setState(() {
        _visible = !(results[0] as dynamic).isHidden;
        _snooze = results[1] as SnoozeStatus;
      });
    } catch (_) {
      // keep defaults
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleVisibility(bool value) async {
    setState(() => _saving = true);
    try {
      await _profileService.updateVisibility(hidden: !value);
      setState(() => _visible = value);
    } catch (e) {
      if (!mounted) return;
      BondyFeedback.showError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickSnooze() async {
    final choice = await showModalBottomSheet<String?>(
      context: context,
      backgroundColor: BondyColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Tạm dừng khám phá',
                style: bondyText(size: 18, weight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'Hồ sơ của bạn sẽ ẩn khỏi gợi ý của người khác trong thời gian được chọn.',
                style: bondyText(size: 13, color: BondyColors.textSecondary),
              ),
              const SizedBox(height: 16),
              for (final option in const [
                ('24h', '24 giờ'),
                ('72h', '3 ngày'),
                ('7d', '1 tuần'),
                ('30d', '30 ngày'),
              ])
                ListTile(
                  leading: const Icon(Icons.pause_circle_outline,
                      color: BondyColors.primary),
                  title: Text(option.$2,
                      style: bondyText(weight: FontWeight.w700)),
                  onTap: () => Navigator.pop(ctx, option.$1),
                ),
              if (_snooze?.isSnoozed == true)
                ListTile(
                  leading: const Icon(Icons.play_circle_outline,
                      color: Color(0xFF10B981)),
                  title: Text('Bật lại ngay',
                      style: bondyText(weight: FontWeight.w700)),
                  onTap: () => Navigator.pop(ctx, null),
                ),
            ],
          ),
        ),
      ),
    );
    if (!mounted) return;
    setState(() => _saving = true);
    try {
      final result = await _profileService.setSnooze(duration: choice);
      if (!mounted) return;
      setState(() => _snooze = result);
    } catch (e) {
      if (!mounted) return;
      BondyFeedback.showError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _formatSnooze() {
    final until = _snooze?.snoozedUntil;
    if (until == null) return 'Đang hoạt động';
    final remaining = until.difference(DateTime.now());
    if (remaining.isNegative) return 'Đang hoạt động';
    if (remaining.inDays >= 1) {
      return 'Tạm dừng — còn ${remaining.inDays} ngày';
    }
    return 'Tạm dừng — còn ${remaining.inHours} giờ';
  }

  Future<void> _deleteAccount() async {
    await Navigator.of(context).pushNamed('/settings/account-delete');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BondyColors.background,
      appBar: AppBar(title: const Text('Quyền riêng tư')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                SwitchListTile(
                  title: Text(
                    'Hiển thị hồ sơ khi khám phá',
                    style: bondyText(weight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    'Tắt để tạm ẩn khỏi gợi ý match.',
                    style: bondyText(
                      size: 13,
                      color: BondyColors.textSecondary,
                    ),
                  ),
                  value: _visible,
                  onChanged: _saving ? null : _toggleVisibility,
                ),
                const Divider(height: 24),
                ListTile(
                  leading: const Icon(Icons.pause_circle_outline,
                      color: BondyColors.primary),
                  title: Text('Tạm dừng khám phá',
                      style: bondyText(weight: FontWeight.w700)),
                  subtitle: Text(_formatSnooze(),
                      style: bondyText(
                        size: 13,
                        color: BondyColors.textSecondary,
                      )),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _saving ? null : _pickSnooze,
                ),
                ListTile(
                  leading: const Icon(Icons.notifications_none,
                      color: BondyColors.primary),
                  title: Text('Cài đặt thông báo',
                      style: bondyText(weight: FontWeight.w700)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context)
                      .pushNamed('/settings/notifications'),
                ),
                ListTile(
                  leading: const Icon(Icons.block_outlined,
                      color: BondyColors.primary),
                  title: Text('Danh sách đã chặn',
                      style: bondyText(weight: FontWeight.w700)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () =>
                      Navigator.of(context).pushNamed('/settings/blocked'),
                ),
                const Divider(height: 24),
                ListTile(
                  leading: const Icon(Icons.delete_outline,
                      color: BondyColors.error),
                  title: Text(
                    'Xóa tài khoản',
                    style: bondyText(
                      weight: FontWeight.w700,
                      color: BondyColors.error,
                    ),
                  ),
                  subtitle: Text(
                    'Dữ liệu cá nhân sẽ được ẩn danh theo chính sách Bondy.',
                    style: bondyText(
                      size: 13,
                      color: BondyColors.textSecondary,
                    ),
                  ),
                  onTap: _deleteAccount,
                ),
              ],
            ),
    );
  }
}
