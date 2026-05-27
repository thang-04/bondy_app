import 'package:flutter/material.dart';

import '../healing/healing_stitch_style.dart';
import '../../core/bondy_error_mapper.dart';
import '../../services/relationship_service.dart';
import '../../widgets/common/bondy_feedback.dart';

class MilestoneRemindersScreen extends StatefulWidget {
  const MilestoneRemindersScreen({super.key});

  @override
  State<MilestoneRemindersScreen> createState() => _MilestoneRemindersScreenState();
}

class _MilestoneRemindersScreenState extends State<MilestoneRemindersScreen> {
  final RelationshipService _service = RelationshipService();
  List<Map<String, dynamic>> _milestones = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _milestones = await _service.listMilestones();
    } catch (e) {
      _error = BondyErrorMapper.message(e);
      _milestones = [];
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showAddDialog() async {
    final titleController = TextEditingController();
    DateTime selected = DateTime.now().add(const Duration(days: 30));

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Thêm cột mốc', style: healingText(weight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(hintText: 'Tiêu đề'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: ctx,
                  initialDate: selected,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                );
                if (picked != null) selected = picked;
              },
              child: Text('Chọn ngày', style: healingText(color: HealingStitchColors.coral)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Lưu', style: healingText(color: HealingStitchColors.coral)),
          ),
        ],
      ),
    );

    if (saved != true || titleController.text.trim().isEmpty) return;

    try {
      await _service.addMilestone(
        title: titleController.text.trim(),
        milestoneDate: selected,
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      BondyFeedback.showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final upcoming = _milestones.where((m) {
      final d = DateTime.tryParse(m['milestoneDate']?.toString() ?? '');
      return d != null && !d.isBefore(now);
    }).toList();
    final past = _milestones.where((m) {
      final d = DateTime.tryParse(m['milestoneDate']?.toString() ?? '');
      return d != null && d.isBefore(now);
    }).toList();

    return Scaffold(
      backgroundColor: HealingStitchColors.warmBackground,
      appBar: AppBar(
        backgroundColor: HealingStitchColors.warmBackground,
        elevation: 0,
        leading: HealingIconButton(
          icon: Icons.arrow_back,
          onTap: () => Navigator.pop(context),
        ),
        title: Text('Dấu mốc kỷ niệm', style: healingText(size: 16, weight: FontWeight.w800)),
        centerTitle: true,
        actions: [
          HealingIconButton(icon: Icons.add, onTap: _showAddDialog),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: HealingStitchColors.coral,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: HealingStitchColors.coral))
            : ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                    'Đừng bỏ lỡ những khoảnh khắc quan trọng',
                    style: healingText(size: 22, weight: FontWeight.w800),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: healingText(color: HealingStitchColors.textSoft)),
                  ],
                  const SizedBox(height: 24),
                  Text('Sắp tới', style: healingText(size: 18, weight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  if (upcoming.isEmpty)
                    Text(
                      'Chưa có cột mốc sắp tới. Nhấn + để thêm.',
                      style: healingText(color: HealingStitchColors.textMuted),
                    )
                  else
                    ...upcoming.map((m) => _card(m, upcoming: true)),
                  const SizedBox(height: 24),
                  Text('Đã qua', style: healingText(size: 18, weight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  if (past.isEmpty)
                    Text('Chưa có kỷ niệm đã qua.', style: healingText(color: HealingStitchColors.textMuted))
                  else
                    ...past.map((m) => _card(m, upcoming: false)),
                ],
              ),
      ),
    );
  }

  Widget _card(Map<String, dynamic> m, {required bool upcoming}) {
    final date = DateTime.tryParse(m['milestoneDate']?.toString() ?? '');
    final label = date != null
        ? '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}'
        : '';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: upcoming ? HealingStitchColors.paleCoral : HealingStitchColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [healingSoftShadow()],
      ),
      child: Row(
        children: [
          Text(upcoming ? '🎂' : '✨', style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m['title']?.toString() ?? '', style: healingText(size: 16, weight: FontWeight.w700)),
                Text(label, style: healingText(size: 13, color: HealingStitchColors.coral)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
