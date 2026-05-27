import 'package:flutter/material.dart';

import 'healing_navigation.dart';
import 'healing_stitch_style.dart';

class StabilizeQuickActionsScreen extends StatefulWidget {
  const StabilizeQuickActionsScreen({super.key});

  @override
  State<StabilizeQuickActionsScreen> createState() => _StabilizeQuickActionsScreenState();
}

class _StabilizeQuickActionsScreenState extends State<StabilizeQuickActionsScreen> {
  final Set<String> _completedActions = {};

  Future<void> _openExercise(String id) async {
    final result = await Navigator.of(context).pushNamed(
      healingExerciseDetailRoute,
      arguments: id,
    );
    if (result == true) {
      setState(() {
        _completedActions.add(id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HealingStitchColors.creamBackground,
      appBar: AppBar(title: const Text('Ổn định nhanh')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Mình tạm ổn định trước nhé', style: healingText(size: 22, weight: FontWeight.w900)),
          const SizedBox(height: 12),
          // Bug fix: IDs phải khớp với seed data trong
          // bondy_server/src/service/healing.seed.ts (exercise-breathing-478,
          // exercise-grounding-54321). Trước đây dùng ID rút gọn (breathe-60s /
          // grounding) → server throw "Healing content not found".
          _ActionTile(
            title: 'Thở 60 giây',
            subtitle: 'Hít thở sâu và đều',
            isCompleted: _completedActions.contains('exercise-breathing-478'),
            onTap: () => _openExercise('exercise-breathing-478'),
          ),
          _ActionTile(
            title: 'Checklist grounding',
            subtitle: '5-4-3-2-1',
            isCompleted: _completedActions.contains('exercise-grounding-54321'),
            onTap: () => _openExercise('exercise-grounding-54321'),
          ),
          _ActionTile(
            title: 'Prompt xả căng ngắn',
            subtitle: 'Giải phóng căng thẳng',
            isCompleted: false,
            onTap: () => Navigator.of(context).pushNamed('/chatbot'),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).maybePop();
            },
            child: const Text('Mình đã ổn hơn'),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isCompleted;
  final VoidCallback onTap;

  const _ActionTile({
    required this.title,
    required this.subtitle,
    required this.isCompleted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: isCompleted ? const Color(0xFFF0FDF4) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isCompleted ? const Color(0xFF86EFAC) : const Color(0xFFF2F0ED),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: isCompleted
            ? Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFFDCFCE7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, size: 20, color: Color(0xFF16A34A)),
              )
            : null,
        title: Text(
          title,
          style: healingText(
            weight: FontWeight.w800,
            color: isCompleted ? const Color(0xFF15803D) : HealingStitchColors.textMain,
          ),
        ),
        subtitle: isCompleted
            ? Text(
                'Đã hoàn thành ✓',
                style: healingText(size: 12, weight: FontWeight.w600, color: const Color(0xFF16A34A)),
              )
            : Text(subtitle, style: healingText(size: 12, color: HealingStitchColors.textMuted)),
        trailing: isCompleted
            ? const Icon(Icons.check_circle, size: 24, color: Color(0xFF16A34A))
            : const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
