import 'package:flutter/material.dart';

import '../../services/profile_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/bondy_feedback.dart';
import '../../widgets/common/bondy_widgets.dart';

/// User-controlled notification preferences, grouped by category.
/// Each category has up to 3 channels (push, email, in-app). The server
/// stores them as JSON so categories can be added without a migration.
class NotificationPrefsScreen extends StatefulWidget {
  const NotificationPrefsScreen({super.key});

  @override
  State<NotificationPrefsScreen> createState() =>
      _NotificationPrefsScreenState();
}

class _NotificationPrefsScreenState extends State<NotificationPrefsScreen> {
  final ProfileService _profileService = ProfileService();

  static const _categories = <_Category>[
    _Category(
      key: 'newMatch',
      title: 'Kết nối mới',
      description: 'Khi có ai đó match với bạn.',
      icon: Icons.favorite,
    ),
    _Category(
      key: 'newMessage',
      title: 'Tin nhắn mới',
      description: 'Khi có tin nhắn đến.',
      icon: Icons.chat_bubble_outline,
    ),
    _Category(
      key: 'matchExpiring',
      title: 'Match sắp hết hạn',
      description: 'Nhắc xác nhận trước 24h hết hạn.',
      icon: Icons.timer_outlined,
    ),
    _Category(
      key: 'healingReminder',
      title: 'Nhắc chữa lành hàng ngày',
      description: 'Daily checkin và bài tập gợi ý.',
      icon: Icons.spa_outlined,
    ),
    _Category(
      key: 'milestone',
      title: 'Cột mốc cặp đôi',
      description: 'Anniversary, streak, milestone…',
      icon: Icons.celebration_outlined,
    ),
    _Category(
      key: 'weeklySummary',
      title: 'Tóm tắt tuần',
      description: 'Email tổng hợp hành trình.',
      icon: Icons.mail_outline,
    ),
    _Category(
      key: 'marketing',
      title: 'Khuyến mãi & cập nhật Bondy',
      description: 'Tin tức, ưu đãi (không bắt buộc).',
      icon: Icons.campaign_outlined,
    ),
  ];

  bool _loading = true;
  bool _saving = false;
  Map<String, Map<String, bool>> _prefs = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final raw = await _profileService.getNotificationPrefs();
      if (!mounted) return;
      setState(() {
        _prefs = _coerce(raw);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      BondyFeedback.showError(context, e);
    }
  }

  Map<String, Map<String, bool>> _coerce(Map<String, dynamic> raw) {
    final out = <String, Map<String, bool>>{};
    for (final cat in _categories) {
      final node = raw[cat.key];
      if (node is Map<String, dynamic>) {
        out[cat.key] = {
          'push': node['push'] == true,
          'email': node['email'] == true,
          'inApp': node['inApp'] == true,
        };
      } else {
        out[cat.key] = {'push': true, 'email': false, 'inApp': true};
      }
    }
    return out;
  }

  Future<void> _toggle(String category, String channel, bool value) async {
    final previous = Map<String, Map<String, bool>>.from(
      _prefs.map((k, v) => MapEntry(k, Map<String, bool>.from(v))),
    );
    setState(() {
      _prefs[category]![channel] = value;
      _saving = true;
    });
    try {
      await _profileService.updateNotificationPrefs({
        category: {channel: value},
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _prefs = previous);
      BondyFeedback.showError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BondyColors.background,
      appBar: AppBar(title: const Text('Cài đặt thông báo')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _categories.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) =>
                  _buildCategoryCard(_categories[index]),
            ),
    );
  }

  Widget _buildCategoryCard(_Category cat) {
    final entry =
        _prefs[cat.key] ?? const {'push': true, 'email': false, 'inApp': true};
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BondyColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: BondyColors.cardBorder),
        boxShadow: [bondySoftShadow()],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: BondyColors.paleCoral,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(cat.icon, color: BondyColors.coral, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cat.title,
                      style: bondyText(size: 15, weight: FontWeight.w800),
                    ),
                    Text(
                      cat.description,
                      style: bondyText(
                        size: 12,
                        color: BondyColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final ch in const [
            ('push', 'Đẩy (push)'),
            ('inApp', 'Trong ứng dụng'),
            ('email', 'Email'),
          ])
            SwitchListTile.adaptive(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(
                ch.$2,
                style: bondyText(size: 13, weight: FontWeight.w600),
              ),
              value: entry[ch.$1] ?? false,
              onChanged: _saving ? null : (v) => _toggle(cat.key, ch.$1, v),
            ),
        ],
      ),
    );
  }
}

class _Category {
  final String key;
  final String title;
  final String description;
  final IconData icon;

  const _Category({
    required this.key,
    required this.title,
    required this.description,
    required this.icon,
  });
}
