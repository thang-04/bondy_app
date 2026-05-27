import 'package:flutter/material.dart';

import 'healing_navigation.dart';
import 'healing_stitch_style.dart';

class DailyRitualOverviewScreen extends StatelessWidget {
  const DailyRitualOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: HealingStitchColors.creamBackground,
        appBar: AppBar(
          title: const Text('Nghi thức dành cho trạng thái hiện tại'),
          bottom: const TabBar(
            tabs: [
              Tab(text: '3 phút'),
              Tab(text: '5-10 phút'),
              Tab(text: '15+ phút'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _RitualList(
              items: [
                _RitualOption(
                  'Thở 3 phút',
                  'Mức năng lượng thấp',
                  healingExerciseDetailRoute,
                  'exercise-breathing-478',
                ),
                _RitualOption(
                  'Grounding nhanh',
                  '5-4-3-2-1',
                  healingExerciseDetailRoute,
                  'exercise-grounding-54321',
                ),
              ],
            ),
            _RitualList(
              items: [
                _RitualOption(
                  'Journal 5 phút',
                  'Viết ra điều cần buông',
                  '/chatbot',
                  null,
                ),
                _RitualOption(
                  'Audio trấn an',
                  'Guided session',
                  '/healing/ritual-audio-detail',
                  'ritual-morning-reset',
                ),
              ],
            ),
            _RitualList(
              items: [
                _RitualOption(
                  'Đọc sâu 15 phút',
                  'Đọc và chậm lại',
                  '/healing/ritual-reading-detail',
                  'ritual-readying-heart',
                ),
                _RitualOption(
                  'Thiền định sâu',
                  'Mở guided audio',
                  '/healing/ritual-audio-detail',
                  'ritual-morning-reset',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RitualList extends StatelessWidget {
  final List<_RitualOption> items;

  const _RitualList({required this.items});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemBuilder: (_, i) {
        final item = items[i];
        return Card(
          child: ListTile(
            title: Text(item.title, style: healingText(weight: FontWeight.w800)),
            subtitle: Text(item.subtitle, style: healingText(size: 12)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Navigator.of(
              context,
            ).pushNamed(item.route, arguments: item.argument),
          ),
        );
      },
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemCount: items.length,
    );
  }
}

class _RitualOption {
  final String title;
  final String subtitle;
  final String route;
  final Object? argument;

  const _RitualOption(this.title, this.subtitle, this.route, this.argument);
}
