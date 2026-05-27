import 'package:flutter/material.dart';

import '../../../models/healing/healing_models.dart';
import '../healing_navigation.dart';
import '../healing_stitch_style.dart';

class ContentHubArticlesTab extends StatefulWidget {
  final List<HealingContentPreview> articles;

  const ContentHubArticlesTab({super.key, required this.articles});

  @override
  State<ContentHubArticlesTab> createState() => _ContentHubArticlesTabState();
}

class _ContentHubArticlesTabState extends State<ContentHubArticlesTab> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Tất cả';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = <String>{
      'Tất cả',
      ...widget.articles.map((item) => _titleCase(item.category)).where((item) => item.isNotEmpty),
    }.toList();
    final items = _filteredArticles();

    return ListView(
      padding: const EdgeInsets.only(bottom: 28),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          child: Text(
            'Bài đọc',
            style: healingText(size: 28, weight: FontWeight.w900),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            decoration: BoxDecoration(
              color: HealingStitchColors.contentBackground,
              borderRadius: BorderRadius.circular(999),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Tìm bài đọc, chủ đề...',
                hintStyle: healingText(color: HealingStitchColors.textMuted),
                prefixIcon: const Icon(Icons.search, color: HealingStitchColors.textMuted),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemBuilder: (context, index) {
              final category = categories[index];
              return _ArticleCategoryChip(
                label: category,
                isSelected: category == _selectedCategory,
                onTap: () => setState(() => _selectedCategory = category),
              );
            },
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemCount: categories.length,
          ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: items.isEmpty
              ? _EmptyState(message: 'Chưa có article phù hợp với bộ lọc này.')
              : Column(
                  children: [
                    for (var i = 0; i < items.length; i++) ...[
                      _ArticleCard(article: items[i]),
                      if (i != items.length - 1) const SizedBox(height: 24),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  List<HealingContentPreview> _filteredArticles() {
    final query = _searchController.text.trim().toLowerCase();
    return widget.articles.where((item) {
      final matchesCategory = _selectedCategory == 'Tất cả' ||
          _titleCase(item.category) == _selectedCategory;
      final haystack = [item.title, item.summary, item.category, ...item.tags]
          .join(' ')
          .toLowerCase();
      final matchesQuery = query.isEmpty || haystack.contains(query);
      return matchesCategory && matchesQuery;
    }).toList();
  }
}

class _ArticleCategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ArticleCategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? HealingStitchColors.paleCoral : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? HealingStitchColors.paleCoral : const Color(0xFFF3F4F6),
          ),
        ),
        child: Text(
          label,
          style: healingText(
            size: 14,
            weight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? HealingStitchColors.pink : HealingStitchColors.textSoft,
          ),
        ),
      ),
    );
  }
}

class _ArticleCard extends StatelessWidget {
  final HealingContentPreview article;

  const _ArticleCard({required this.article});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => openHealingContent(context, article),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: 112,
              height: 112,
              child: _PreviewImage(item: article),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _titleCase(article.category).toUpperCase(),
                  style: healingText(
                    size: 10,
                    weight: FontWeight.w900,
                    color: HealingStitchColors.pink,
                  ).copyWith(letterSpacing: 0.8),
                ),
                const SizedBox(height: 8),
                Text(
                  article.title,
                  style: healingText(size: 18, weight: FontWeight.w800, height: 1.2),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 14, color: HealingStitchColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      _durationLabel(article),
                      style: healingText(size: 12, weight: FontWeight.w600, color: HealingStitchColors.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewImage extends StatelessWidget {
  final HealingContentPreview item;

  const _PreviewImage({required this.item});

  @override
  Widget build(BuildContext context) {
    final asset = switch (item.type.toUpperCase()) {
      'COURSE' => HealingStitchAssets.compactHero,
      'EXERCISE' => HealingStitchAssets.compactAudioWater,
      _ => HealingStitchAssets.activeListening,
    };
    return Image.asset(asset, fit: BoxFit.cover);
  }
}

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: healingText(size: 13, color: HealingStitchColors.textMuted),
      ),
    );
  }
}

String _durationLabel(HealingContentPreview item) {
  if (item.estimatedMinutes != null) return '${item.estimatedMinutes} phút đọc';
  if (item.durationDays != null) return '${item.durationDays} ngày';
  return 'Mở ngay';
}

String _titleCase(String value) {
  if (value.isEmpty) return value;
  return value[0].toUpperCase() + value.substring(1).toLowerCase();
}
