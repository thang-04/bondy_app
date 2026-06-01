import 'package:flutter/material.dart';

import '../../models/healing/healing_models.dart';
import '../../viewmodels/healing/healing_home_viewmodel.dart';
import '../../widgets/navigation/bondy_bottom_nav_bar.dart';
import 'healing_navigation.dart';
import 'healing_stitch_style.dart';
import 'widgets/content_hub_articles_tab.dart';
import 'widgets/content_hub_courses_tab.dart';
import 'widgets/healing_content_search_delegate.dart';

class ContentHubLibraryScreen extends StatefulWidget {
  final HealingHomeViewModel? viewModel;

  const ContentHubLibraryScreen({super.key, this.viewModel});

  @override
  State<ContentHubLibraryScreen> createState() =>
      _ContentHubLibraryScreenState();
}

class _ContentHubLibraryScreenState extends State<ContentHubLibraryScreen> {
  late final HealingHomeViewModel _viewModel;
  late final bool _ownsViewModel;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _viewModel = widget.viewModel ?? HealingHomeViewModel();
    _ownsViewModel = widget.viewModel == null;
    _viewModel.loadHome();
  }

  @override
  void dispose() {
    if (_ownsViewModel) _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        final sections = _viewModel.home?.sections ?? _emptyHealingSections;
        return Scaffold(
          backgroundColor: HealingStitchColors.contentBackground,
          bottomNavigationBar: BondyBottomNavBar(
            currentIndex: 1,
            onTabSelected: (index) {
              final route = switch (index) {
                0 => '/home',
                1 => healingHomeRoute,
                2 => '/home/matches',
                3 => '/home/profile',
                _ => '/home',
              };
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil(route, (_) => false);
            },
            onMatchTap: () => Navigator.of(context).pushNamed('/discover'),
          ),
          body: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 16),
                _buildCategoryScroller(),
                if (_viewModel.isLoading && _viewModel.home == null)
                  const LinearProgressIndicator(
                    minHeight: 2,
                    color: HealingStitchColors.pink,
                    backgroundColor: Colors.transparent,
                  )
                else
                  const SizedBox(height: 2),
                if (_viewModel.errorMessage != null && _viewModel.home == null)
                  _FallbackNotice(message: 'Không thể tải thư viện từ server.'),
                Expanded(child: _buildTabContent(sections)),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openSearch(HealingHomeSections sections) {
    showSearch<void>(
      context: context,
      delegate: HealingContentSearchDelegate(
        items: flattenHealingSections(sections),
      ),
    );
  }

  Widget _buildTabContent(HealingHomeSections sections) {
    switch (_selectedTabIndex) {
      case 0:
        return _AllContentTab(
          sections: sections,
          onSearch: () => _openSearch(sections),
          onSwitchTab: (index) => setState(() => _selectedTabIndex = index),
        );
      case 1:
        return ContentHubCoursesTab(courses: sections.courses);
      case 2:
        return ContentHubArticlesTab(articles: sections.articles);
      case 3:
        return _AudioSessionsTab(audios: sections.audios);
      default:
        return _AllContentTab(
          sections: sections,
          onSearch: () => _openSearch(sections),
          onSwitchTab: (index) => setState(() => _selectedTabIndex = index),
        );
    }
  }

  Widget _buildCategoryScroller() {
    final labels = ['Tất cả', 'Khoá học', 'Bài đọc', 'Audio'];
    return SizedBox(
      height: 58,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 9),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final selected = index == _selectedTabIndex;
          return GestureDetector(
            onTap: () => setState(() => _selectedTabIndex = index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              decoration: BoxDecoration(
                gradient: selected ? HealingStitchColors.warmGradient : null,
                color: selected ? null : Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: selected
                      ? Colors.transparent
                      : const Color(0xFFF3F4F6),
                ),
                boxShadow: selected
                    ? [healingGlowShadow()]
                    : [healingSoftShadow(0.03)],
              ),
              child: Center(
                child: Text(
                  labels[index],
                  style: healingText(
                    size: 13,
                    weight: FontWeight.w900,
                    color: selected
                        ? Colors.white
                        : HealingStitchColors.textSoft,
                  ),
                ),
              ),
            ),
          );
        },
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemCount: labels.length,
      ),
    );
  }
}

class _AllContentTab extends StatelessWidget {
  final HealingHomeSections sections;
  final VoidCallback onSearch;
  final void Function(int tabIndex) onSwitchTab;

  const _AllContentTab({
    required this.sections,
    required this.onSearch,
    required this.onSwitchTab,
  });

  @override
  Widget build(BuildContext context) {
    final featured =
        _firstOrNull(sections.courses) ??
        _firstOrNull(sections.articles) ??
        _firstOrNull(sections.exercises);
    final continueItems = sections.courses.isNotEmpty
        ? sections.courses
        : _combinedItems(sections);
    final communicationItems = _combinedItems(sections);

    return ListView(
      padding: const EdgeInsets.only(bottom: 28),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 6, 24, 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Content Hub',
                      style: healingText(size: 24, weight: FontWeight.w900),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Khám phá nội dung healing phù hợp với bạn',
                      style: healingText(
                        size: 13,
                        weight: FontWeight.w700,
                        color: HealingStitchColors.textSoft,
                      ),
                    ),
                  ],
                ),
              ),
              HealingIconButton(icon: Icons.search, onTap: onSearch),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _SectionTitle(
            title: 'Dành cho bạn',
            action: 'Xem tất cả',
            onTap: () => onSwitchTab(1),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: featured == null
              ? const _EmptyContentCard(message: 'Chưa có gợi ý nội dung.')
              : _FeaturedContentCard(item: featured),
        ),
        const SizedBox(height: 28),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: _SectionTitle(title: 'Tiếp tục học'),
        ),
        const SizedBox(height: 12),
        _HorizontalContentScroller(items: continueItems),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _SectionTitle(
            title: 'Giao tiếp',
            action: 'Xem tất cả',
            onTap: () => onSwitchTab(2),
          ),
        ),
        const SizedBox(height: 12),
        _SquareContentScroller(items: communicationItems),
        const SizedBox(height: 24),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: _DailyByteCard(),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _SectionTitle(
            title: 'Bài tập nhanh',
            action: 'Xem tất cả',
            onTap: () {
              onSearch();
            },
          ),
        ),
        const SizedBox(height: 12),
        _CompactContentList(items: sections.exercises),
      ],
    );
  }
}

class _AudioSessionsTab extends StatefulWidget {
  final List<HealingContentPreview> audios;

  const _AudioSessionsTab({required this.audios});

  @override
  State<_AudioSessionsTab> createState() => _AudioSessionsTabState();
}

class _AudioSessionsTabState extends State<_AudioSessionsTab> {
  static const int _initialLimit = 5;
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final items = widget.audios;
    final hasMore = items.length > _initialLimit;
    final visibleItems = _showAll || !hasMore
        ? items
        : items.take(_initialLimit).toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
      children: [
        Text(
          'Audio & hướng dẫn',
          style: healingText(size: 28, weight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Text(
          'Nghe thiền định và bài tập hướng dẫn — chạm để bắt đầu.',
          style: healingText(
            size: 13,
            color: HealingStitchColors.textSoft,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 20),
        for (final item in visibleItems) ...[
          _SessionTile(item: item),
          const SizedBox(height: 12),
        ],
        if (hasMore && !_showAll)
          Center(
            child: TextButton.icon(
              onPressed: () => setState(() => _showAll = true),
              icon: const Icon(Icons.expand_more, size: 18),
              label: Text(
                'Xem thêm (${items.length - _initialLimit})',
                style: healingText(
                  size: 13,
                  weight: FontWeight.w800,
                  color: HealingStitchColors.pink,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onTap;

  const _SectionTitle({required this.title, this.action, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Text(
            title,
            style: healingText(size: 18, weight: FontWeight.w900),
          ),
        ),
        if (action != null)
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              action!,
              style: healingText(
                size: 12,
                weight: FontWeight.w900,
                color: HealingStitchColors.pink,
              ),
            ),
          ),
      ],
    );
  }
}

class _FeaturedContentCard extends StatelessWidget {
  final HealingContentPreview item;

  const _FeaturedContentCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => openHealingContent(context, item),
      child: AspectRatio(
        aspectRatio: 0.82,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [healingSoftShadow(0.1)],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(_imageFor(item), fit: BoxFit.cover),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.84),
                      Colors.black.withValues(alpha: 0.25),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        _ContentBadge(
                          label: _labelFor(item),
                          translucent: true,
                        ),
                        const SizedBox(width: 8),
                        const _ContentBadge(label: 'Ready', icon: Icons.bolt),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      item.title,
                      style: healingText(
                        size: 25,
                        weight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.summary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: healingText(
                        size: 13,
                        weight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.9),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _MetaPill(item: item),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 11,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: [healingSoftShadow(0.16)],
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.play_circle_fill,
                                size: 20,
                                color: HealingStitchColors.pink,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Start',
                                style: healingText(
                                  size: 13,
                                  weight: FontWeight.w900,
                                  color: HealingStitchColors.pink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HorizontalContentScroller extends StatelessWidget {
  final List<HealingContentPreview> items;

  const _HorizontalContentScroller({required this.items});

  @override
  Widget build(BuildContext context) {
    final visibleItems = items;
    if (visibleItems.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: _EmptyContentCard(message: 'Chưa có nội dung để tiếp tục.'),
      );
    }
    return SizedBox(
      height: 104,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) =>
            _ContinueLearningCard(item: visibleItems[index]),
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemCount: visibleItems.length,
      ),
    );
  }
}

class _ContinueLearningCard extends StatelessWidget {
  final HealingContentPreview item;

  const _ContinueLearningCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => openHealingContent(context, item),
      child: Container(
        width: 286,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF3F4F6)),
          boxShadow: [healingSoftShadow(0.035)],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(
                _imageFor(item),
                width: 72,
                height: 72,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _labelFor(item).toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: healingText(
                      size: 10,
                      weight: FontWeight.w900,
                      color: HealingStitchColors.pink,
                    ).copyWith(letterSpacing: 0.4),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: healingText(size: 14, weight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _durationLabel(item),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: healingText(
                      size: 12,
                      color: HealingStitchColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: HealingStitchColors.paleCoral,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward,
                color: HealingStitchColors.pink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SquareContentScroller extends StatelessWidget {
  final List<HealingContentPreview> items;

  const _SquareContentScroller({required this.items});

  @override
  Widget build(BuildContext context) {
    final visibleItems = items;
    if (visibleItems.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: _EmptyContentCard(
          message: 'Chưa có nội dung trong danh mục này.',
        ),
      );
    }
    return SizedBox(
      height: 244,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) =>
            _SquareContentCard(item: visibleItems[index]),
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemCount: visibleItems.length,
      ),
    );
  }
}

class _SquareContentCard extends StatelessWidget {
  final HealingContentPreview item;

  const _SquareContentCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => openHealingContent(context, item),
      child: SizedBox(
        width: 150,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(_imageFor(item), fit: BoxFit.cover),
                    Align(
                      alignment: Alignment.topRight,
                      child: Container(
                        margin: const EdgeInsets.all(10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          _durationLabel(item),
                          style: healingText(size: 10, weight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: HealingStitchColors.pink.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                _labelFor(item).toUpperCase(),
                style: healingText(
                  size: 10,
                  weight: FontWeight.w900,
                  color: HealingStitchColors.pink,
                ).copyWith(letterSpacing: 0.6),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              item.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: healingText(
                size: 15,
                weight: FontWeight.w900,
                height: 1.15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactContentList extends StatefulWidget {
  final List<HealingContentPreview> items;
  final int initialLimit;

  const _CompactContentList({required this.items, this.initialLimit = 5});

  @override
  State<_CompactContentList> createState() => _CompactContentListState();
}

class _CompactContentListState extends State<_CompactContentList> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: _EmptyContentCard(message: 'Chưa có bài tập nhanh.'),
      );
    }
    final hasMore = items.length > widget.initialLimit;
    final visibleItems = _showAll || !hasMore
        ? items
        : items.take(widget.initialLimit).toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          for (final item in visibleItems) ...[
            _SessionTile(item: item),
            const SizedBox(height: 10),
          ],
          if (hasMore && !_showAll)
            TextButton.icon(
              onPressed: () => setState(() => _showAll = true),
              icon: const Icon(Icons.expand_more, size: 18),
              label: Text(
                'Xem thêm (${items.length - widget.initialLimit})',
                style: healingText(
                  size: 13,
                  weight: FontWeight.w800,
                  color: HealingStitchColors.pink,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  final HealingContentPreview item;

  const _SessionTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => openHealingContent(
          context,
          item,
          fallbackRoute: healingExerciseDetailRoute,
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFF3F4F6)),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: HealingStitchColors.paleCoral,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.self_improvement,
                  color: HealingStitchColors.pink,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: healingText(size: 14, weight: FontWeight.w900),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.summary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: healingText(
                        size: 12,
                        color: HealingStitchColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: HealingStitchColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DailyByteCard extends StatelessWidget {
  const _DailyByteCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFF3F4F6)),
        boxShadow: [healingSoftShadow(0.07)],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFFF3F4F6)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lightbulb,
                  size: 14,
                  color: HealingStitchColors.pink,
                ),
                const SizedBox(width: 6),
                Text(
                  'DAILY BYTE',
                  style: healingText(
                    size: 10,
                    weight: FontWeight.w900,
                    color: HealingStitchColors.textSoft,
                  ).copyWith(letterSpacing: 1),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Đi chậm lại không làm bạn thua cuộc; nó giúp bạn nghe mình rõ hơn.',
            textAlign: TextAlign.center,
            style: healingText(size: 20, weight: FontWeight.w700, height: 1.35),
          ),
          const SizedBox(height: 18),
          Container(
            width: 48,
            height: 4,
            decoration: BoxDecoration(
              gradient: HealingStitchColors.warmGradient,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContentBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool translucent;

  const _ContentBadge({
    required this.label,
    this.icon,
    this.translucent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: translucent
            ? Colors.white.withValues(alpha: 0.22)
            : HealingStitchColors.pink,
        borderRadius: BorderRadius.circular(999),
        border: translucent ? Border.all(color: Colors.white24) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: Colors.white),
            const SizedBox(width: 3),
          ],
          Text(
            label.toUpperCase(),
            style: healingText(
              size: 10,
              weight: FontWeight.w900,
              color: Colors.white,
            ).copyWith(letterSpacing: 0.7),
          ),
        ],
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final HealingContentPreview item;

  const _MetaPill({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          const Icon(Icons.schedule, color: Colors.white, size: 15),
          const SizedBox(width: 5),
          Text(
            _durationLabel(item),
            style: healingText(
              size: 12,
              weight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _FallbackNotice extends StatelessWidget {
  final String message;

  const _FallbackNotice({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7ED),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFFEDD5)),
        ),
        child: Text(
          message,
          style: healingText(size: 11, color: const Color(0xFF9A3412)),
        ),
      ),
    );
  }
}

class _EmptyContentCard extends StatelessWidget {
  final String message;

  const _EmptyContentCard({required this.message});

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
        style: healingText(size: 13, color: HealingStitchColors.textMuted),
      ),
    );
  }
}

List<HealingContentPreview> _combinedItems(HealingHomeSections sections) {
  return [
    ...sections.articles,
    ...sections.exercises,
    ...sections.audios,
    ...sections.rituals,
    ...sections.courses,
  ];
}

T? _firstOrNull<T>(List<T> items) => items.isEmpty ? null : items.first;

String _labelFor(HealingContentPreview item) {
  return switch (item.type.toUpperCase()) {
    'ARTICLE' => 'Bài đọc',
    'EXERCISE' => 'Bài tập',
    'COURSE' => 'Khoá học',
    _ => 'Nội dung',
  };
}

String _durationLabel(HealingContentPreview item) {
  if (item.estimatedMinutes != null) return '${item.estimatedMinutes} phút';
  if (item.durationDays != null) return '${item.durationDays} ngày';
  return 'Mở ngay';
}

String _imageFor(HealingContentPreview item) {
  return switch (item.type.toUpperCase()) {
    'ARTICLE' => HealingStitchAssets.activeListening,
    'EXERCISE' => HealingStitchAssets.compactAudioWater,
    'AUDIO' => HealingStitchAssets.compactAudioWater,
    'RITUAL' => HealingStitchAssets.meditation,
    'COURSE' => HealingStitchAssets.contentHero,
    _ => HealingStitchAssets.contentHero,
  };
}

const _emptyHealingSections = HealingHomeSections(
  articles: [],
  exercises: [],
  audios: [],
  rituals: [],
  courses: [],
);
