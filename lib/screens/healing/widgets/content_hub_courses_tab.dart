import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../models/healing/healing_models.dart';
import '../healing_navigation.dart';
import '../healing_stitch_style.dart';

class ContentHubCoursesTab extends StatefulWidget {
  final List<HealingContentPreview> courses;

  const ContentHubCoursesTab({super.key, required this.courses});

  @override
  State<ContentHubCoursesTab> createState() => _ContentHubCoursesTabState();
}

class _ContentHubCoursesTabState extends State<ContentHubCoursesTab> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _journeyKey = GlobalKey();
  String _selectedCategory = 'Tất cả';
  bool _savedOnly = false;
  final Set<String> _savedCourseIds = {};
  static const _savedKey = 'healing_saved_courses';

  @override
  void initState() {
    super.initState();
    _loadSavedCourses();
  }

  Future<void> _loadSavedCourses() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_savedKey) ?? [];
    if (!mounted) return;
    setState(() => _savedCourseIds.addAll(saved));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToJourney() {
    final context = _journeyKey.currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final courses = _filteredCourses();
    final featured = courses.isNotEmpty ? courses.first : null;
    final categories = <String>{
      'Tất cả',
      ...widget.courses.map((item) => _titleCase(item.category)).where((item) => item.isNotEmpty),
    }.toList();

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 28),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Khoá học',
                style: healingText(size: 28, weight: FontWeight.w900),
              ),
              HealingIconButton(
                icon: _savedOnly ? Icons.bookmarks : Icons.bookmarks_outlined,
                onTap: () => setState(() => _savedOnly = !_savedOnly),
              ),
            ],
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
                hintText: 'Tìm kiếm chủ đề, kỹ năng...',
                hintStyle: healingText(color: HealingStitchColors.textMuted),
                prefixIcon: const Icon(Icons.search, color: HealingStitchColors.textMuted),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        if (featured != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _FeaturedCourseCard(course: featured),
          )
        else
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: _EmptyState(message: 'Chưa có khoá học nào để hiển thị.'),
          ),
        const SizedBox(height: 32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Chủ đề khám phá',
            style: healingText(size: 20, weight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemBuilder: (context, index) {
              final category = categories[index];
              return _CategoryPill(
                label: category,
                isSelected: category == _selectedCategory,
                onTap: () => setState(() => _selectedCategory = category),
              );
            },
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemCount: categories.length,
          ),
        ),
        const SizedBox(height: 32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Hành trình của bạn',
                style: healingText(size: 20, weight: FontWeight.w800),
              ),
              GestureDetector(
                onTap: _scrollToJourney,
                child: Text(
                  'Xem tất cả',
                  style: healingText(size: 14, weight: FontWeight.w700, color: HealingStitchColors.pink),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          key: _journeyKey,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              for (var i = 0; i < courses.length; i++) ...[
                _EnrolledCourseItem(
                  course: courses[i],
                  progress: i == 0 ? 0.45 : 0.15,
                  onSaveToggle: () async {
                    setState(() {
                      if (_savedCourseIds.contains(courses[i].id)) {
                        _savedCourseIds.remove(courses[i].id);
                      } else {
                        _savedCourseIds.add(courses[i].id);
                      }
                    });
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setStringList(_savedKey, _savedCourseIds.toList());
                  },
                ),
                if (i != courses.length - 1) const SizedBox(height: 12),
              ],
              if (courses.isEmpty) const _EmptyState(message: 'Không có khoá học phù hợp với bộ lọc.'),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Khoá học phổ biến',
            style: healingText(size: 20, weight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 290,
          child: courses.isEmpty
              ? const Center(child: _EmptyState(message: 'Chưa có khoá học phổ biến.'))
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemBuilder: (context, index) => _PopularCourseCard(course: courses[index]),
                  separatorBuilder: (_, _) => const SizedBox(width: 16),
                  itemCount: courses.length,
                ),
        ),
      ],
    );
  }

  List<HealingContentPreview> _filteredCourses() {
    final query = _searchController.text.trim().toLowerCase();
    return widget.courses.where((item) {
      final matchesCategory = _selectedCategory == 'Tất cả' ||
          _titleCase(item.category) == _selectedCategory;
      final haystack = [item.title, item.summary, item.category, ...item.tags]
          .join(' ')
          .toLowerCase();
      final matchesQuery = query.isEmpty || haystack.contains(query);
      final matchesSaved = !_savedOnly || _savedCourseIds.contains(item.id);
      return matchesCategory && matchesQuery && matchesSaved;
    }).toList();
  }
}

class _FeaturedCourseCard extends StatelessWidget {
  final HealingContentPreview course;

  const _FeaturedCourseCard({required this.course});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => openHealingContent(context, course),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [healingSoftShadow(0.08)],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(HealingStitchAssets.dailyHero, fit: BoxFit.cover),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.8),
                      Colors.black.withValues(alpha: 0.2),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 16,
                left: 16,
                child: _Badge(label: course.accessLevel == 'PREMIUM' ? 'Premium' : 'Nổi bật'),
              ),
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.title,
                      style: healingText(size: 20, weight: FontWeight.w900, color: Colors.white),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      course.summary,
                      style: healingText(size: 13, color: Colors.white.withValues(alpha: 0.8)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: HealingStitchColors.warmGradient,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.play_arrow, color: Colors.white, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'Tiếp tục',
                              style: healingText(size: 12, weight: FontWeight.w800, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
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

class _CategoryPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryPill({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? HealingStitchColors.paleCoral : HealingStitchColors.contentBackground,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: healingText(
            size: 14,
            weight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? HealingStitchColors.pink : HealingStitchColors.textMain,
          ),
        ),
      ),
    );
  }
}

class _EnrolledCourseItem extends StatelessWidget {
  final HealingContentPreview course;
  final double progress;
  final VoidCallback? onSaveToggle;

  const _EnrolledCourseItem({
    required this.course,
    required this.progress,
    this.onSaveToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => openHealingContent(context, course),
      onLongPress: onSaveToggle,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [healingSoftShadow(0.04)],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 64,
                height: 64,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(HealingStitchAssets.compactHero, fit: BoxFit.cover),
                    Container(
                      color: Colors.black.withValues(alpha: 0.2),
                      child: const Icon(Icons.play_arrow, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.title,
                    style: healingText(size: 16, weight: FontWeight.w800),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _courseMeta(course),
                    style: healingText(size: 12, color: HealingStitchColors.textMuted),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: HealingStitchColors.contentBackground,
                          valueColor: const AlwaysStoppedAnimation<Color>(HealingStitchColors.orange),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: healingText(size: 10, weight: FontWeight.w800, color: HealingStitchColors.orange),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PopularCourseCard extends StatelessWidget {
  final HealingContentPreview course;

  const _PopularCourseCard({required this.course});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => openHealingContent(context, course),
      child: Container(
        width: 260,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [healingSoftShadow(0.04)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(HealingStitchAssets.rekindling, fit: BoxFit.cover),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: _Badge(label: _courseMeta(course)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: HealingStitchColors.paleCoral,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _titleCase(course.category).toUpperCase(),
                style: healingText(size: 10, weight: FontWeight.w900, color: HealingStitchColors.pink),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              course.title,
              style: healingText(size: 16, weight: FontWeight.w800),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              children: [
                const Icon(Icons.view_module, size: 14, color: HealingStitchColors.textMuted),
                const SizedBox(width: 4),
                Text(_courseMeta(course), style: healingText(size: 12, weight: FontWeight.w600, color: HealingStitchColors.textMuted)),
                const Spacer(),
                const Icon(Icons.arrow_forward, size: 14, color: HealingStitchColors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;

  const _Badge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: healingText(size: 12, weight: FontWeight.w800, color: Colors.white),
      ),
    );
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

String _courseMeta(HealingContentPreview course) {
  if (course.durationDays != null) return '${course.durationDays} ngày';
  if (course.estimatedMinutes != null) return '${course.estimatedMinutes} phút';
  return 'Mở ngay';
}

String _titleCase(String value) {
  if (value.isEmpty) return value;
  return value[0].toUpperCase() + value.substring(1).toLowerCase();
}
