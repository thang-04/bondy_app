import 'package:flutter/material.dart';
import '../../services/safety_checkin_service.dart';

class ActiveCheckinBanner extends StatefulWidget {
  const ActiveCheckinBanner({super.key});

  @override
  State<ActiveCheckinBanner> createState() => _ActiveCheckinBannerState();
}

class _ActiveCheckinBannerState extends State<ActiveCheckinBanner> {
  final _service = SafetyCheckinService();
  List<SafetyCheckin> _checkins = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await _service.fetchActiveCheckins();
      if (mounted) setState(() => _checkins = list);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirm(SafetyCheckin c) async {
    await _service.confirmCheckin(c.id);
    await _load();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã xác nhận an toàn')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _checkins.isEmpty) return const SizedBox.shrink();
    final checkin = _checkins.first;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Row(
        children: [
          const Icon(Icons.shield, color: Colors.orange),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Check-in an toàn đang bật',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                if (checkin.expectedReturnAt != null)
                  Text(
                    'Dự kiến về: ${_fmt(checkin.expectedReturnAt!)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _confirm(checkin),
            child: const Text('Tôi an toàn'),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime dt) {
    final l = dt.toLocal();
    return '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')} ${l.day}/${l.month}';
  }
}
