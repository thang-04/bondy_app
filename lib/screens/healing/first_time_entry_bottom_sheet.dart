import 'package:flutter/material.dart';

import 'healing_stitch_style.dart';

class FirstTimeEntryBottomSheet extends StatelessWidget {
  final VoidCallback onCheckin;
  final VoidCallback onReflection;
  final VoidCallback onLater;

  const FirstTimeEntryBottomSheet({
    super.key,
    required this.onCheckin,
    required this.onReflection,
    required this.onLater,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bắt đầu Healing',
            style: healingText(size: 18, weight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            'Bạn muốn Bondy đồng hành theo cách nào trước?',
            style: healingText(size: 13, color: HealingStitchColors.textSoft),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.favorite_border),
            title: const Text('Check-in'),
            onTap: onCheckin,
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.auto_awesome),
            title: const Text('Reflection'),
            onTap: onReflection,
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.schedule),
            title: const Text('Để sau'),
            onTap: onLater,
          ),
        ],
      ),
    );
  }
}
