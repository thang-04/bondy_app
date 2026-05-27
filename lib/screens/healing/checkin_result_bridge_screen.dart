import 'package:flutter/material.dart';

import 'healing_navigation.dart';
import 'healing_stitch_style.dart';

class CheckinResultBridgeScreen extends StatelessWidget {
  const CheckinResultBridgeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HealingStitchColors.creamBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bạn đã check-in hôm nay',
                style: healingText(size: 24, weight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                'Hãy chọn bước tiếp theo để tiếp tục hành trình.',
                style: healingText(size: 13, color: HealingStitchColors.textSoft),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFF2F0ED)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gợi ý ngay bây giờ',
                        style: healingText(size: 15, weight: FontWeight.w900),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '- Ổn định trước nếu đang quá tải\n- Reflection nếu bạn đã sẵn sàng',
                        style: healingText(
                          size: 12,
                          color: HealingStitchColors.textMuted,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              HealingGradientButton(
                label: 'Ổn định ngay',
                icon: Icons.favorite,
                onTap: () => Navigator.of(
                  context,
                ).pushNamed('/healing/stabilize-quick-actions'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil(healingHomeRoute, (_) => false),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text('Về Healing Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

