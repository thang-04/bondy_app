import 'package:flutter/material.dart';

import '../../../models/healing/healing_models.dart';
import '../healing_navigation.dart';
import '../healing_stitch_style.dart';

class HealingContentSearchDelegate extends SearchDelegate<void> {
  final List<HealingContentPreview> items;

  HealingContentSearchDelegate({required this.items});

  List<HealingContentPreview> _filtered(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return items;
    return items.where((item) {
      final haystack =
          '${item.title} ${item.summary} ${item.category} ${item.tags.join(' ')}'
              .toLowerCase();
      return haystack.contains(q);
    }).toList();
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    final results = _filtered(query);
    if (results.isEmpty) {
      return Center(
        child: Text(
          'Không tìm thấy nội dung phù hợp.',
          style: healingText(color: HealingStitchColors.textMuted),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: results.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = results[index];
        return ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: HealingStitchColors.border),
          ),
          tileColor: HealingStitchColors.surface,
          title: Text(
            item.title,
            style: healingText(weight: FontWeight.w800),
          ),
          subtitle: Text(
            '${item.type} · ${item.category}',
            style: healingText(size: 12, color: HealingStitchColors.textMuted),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            close(context, null);
            openHealingContent(context, item);
          },
        );
      },
    );
  }
}

List<HealingContentPreview> flattenHealingSections(HealingHomeSections sections) {
  return [
    ...sections.courses,
    ...sections.articles,
    ...sections.exercises,
    ...sections.audios,
    ...sections.rituals,
  ];
}
