import 'package:flutter/material.dart';

import '../../core/bondy_error_mapper.dart';
import '../../models/healing/healing_models.dart';
import '../../services/healing/healing_service.dart';
import '../../widgets/navigation/bondy_bottom_nav_bar.dart';
import 'healing_navigation.dart';
import 'healing_stitch_style.dart';

/// Refactor: trước đây screen là StatelessWidget hiển thị content cứng cho
/// mọi ritual. Giờ load theo ID từ route args (hoặc tham số) qua
/// `/healing/rituals/[id]` để mỗi ritual hiển thị đúng nội dung của nó.
class RitualReadingDetailScreen extends StatefulWidget {
  final bool planMode;
  final String? ritualId;
  final HealingDataSource? service;

  const RitualReadingDetailScreen({
    super.key,
    this.planMode = false,
    this.ritualId,
    this.service,
  });

  @override
  State<RitualReadingDetailScreen> createState() =>
      _RitualReadingDetailScreenState();
}

class _RitualReadingDetailScreenState extends State<RitualReadingDetailScreen> {
  late final HealingDataSource _service;
  HealingRitual? _ritual;
  HealingArticle? _reading;
  bool _isLoading = true;
  bool _didLoad = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? HealingService();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didLoad) return;
    _didLoad = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  String? _resolveRitualId() {
    if (widget.ritualId != null && widget.ritualId!.isNotEmpty) {
      return widget.ritualId;
    }
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String && args.isNotEmpty) return args;
    if (args is Map && args['ritualId'] is String) {
      return args['ritualId'] as String;
    }
    return null;
  }

  bool _isPlanMode() {
    if (widget.planMode) return true;
    final args = ModalRoute.of(context)?.settings.arguments;
    return args is Map && args['planMode'] == true;
  }

  Future<void> _load() async {
    final id = _resolveRitualId();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    if (id == null) {
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Thiếu mã ritual. Vui lòng mở lại từ màn hình lộ trình.';
      });
      return;
    }
    try {
      final ritual = await _service.fetchRitual(id);
      HealingArticle? reading;
      // Nếu ritual có readingContentId trỏ tới article thì lấy body article
      // làm nội dung đọc — không thì fallback sang summary của ritual.
      final readingId = ritual.readingContentId;
      if (readingId != null && readingId.isNotEmpty) {
        try {
          reading = await _service.fetchArticle(readingId);
        } catch (_) {
          // Article fetch fail không phải lỗi chết — hiển thị summary thay thế.
          reading = null;
        }
      }
      if (!mounted) return;
      setState(() {
        _ritual = ritual;
        _reading = reading;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = BondyErrorMapper.message(error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onCompleted() async {
    final ritual = _ritual;
    if (ritual == null) return;
    if (_isPlanMode()) {
      Navigator.of(context).maybePop(true);
      return;
    }
    Navigator.of(context).pushNamed(healingReflectionCompleteRoute);
  }

  @override
  Widget build(BuildContext context) {
    final ritual = _ritual;
    final reading = _reading;
    final bodyText = reading?.body.trim().isNotEmpty == true
        ? reading!.body
        : ritual?.summary ?? '';
    final completionPrompt = ritual?.completionPrompt;

    return Scaffold(
      backgroundColor: HealingStitchColors.creamBackground,
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
          Navigator.of(context).pushNamedAndRemoveUntil(route, (_) => false);
        },
        onMatchTap: () => Navigator.of(context).pushNamed('/discover'),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? _ErrorView(
                message: _errorMessage!,
                onRetry: () {
                  _didLoad = false;
                  _load();
                },
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(0, 10, 0, 110),
                children: [
                  HealingTopBar(
                    title: 'Bài đọc ritual',
                    onBack: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    height: 220,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [healingSoftShadow(0.1)],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child:
                        ritual?.thumbnailUrl != null &&
                            ritual!.thumbnailUrl!.isNotEmpty
                        ? Image.network(
                            ritual.thumbnailUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildHeroFallback(),
                          )
                        : _buildHeroFallback(),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      ritual?.title ?? 'Bài ritual',
                      style: healingText(size: 30, weight: FontWeight.w900),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: HealingStitchColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [healingSoftShadow(0.05)],
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 22,
                          backgroundColor: HealingStitchColors.creamBackground,
                          child: Icon(
                            Icons.favorite_outline,
                            color: HealingStitchColors.pink,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                reading?.authorName.isNotEmpty == true
                                    ? reading!.authorName
                                    : 'Bondy Wellness Team',
                                style: healingText(
                                  size: 14,
                                  weight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${ritual?.durationMinutes ?? 5} phút đọc',
                                style: healingText(
                                  size: 12,
                                  color: HealingStitchColors.textSoft,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (bodyText.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        bodyText,
                        style: healingText(
                          size: 15,
                          height: 1.6,
                          color: HealingStitchColors.textMain,
                        ),
                      ),
                    ),
                  if (completionPrompt != null &&
                      completionPrompt.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: HealingStitchColors.paleCoral,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        completionPrompt,
                        style: healingText(
                          size: 14,
                          color: HealingStitchColors.textMain,
                          weight: FontWeight.w600,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _isLoading || _errorMessage != null
          ? null
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                child: HealingGradientButton(
                  label: 'Đã đọc xong',
                  icon: Icons.check_circle_outline,
                  onTap: _onCompleted,
                ),
              ),
            ),
    );
  }

  Widget _buildHeroFallback() {
    return Image.asset(
      HealingStitchAssets.openBook,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => const ColoredBox(
        color: HealingStitchColors.paleCoral,
        child: Center(
          child: Icon(
            Icons.menu_book_outlined,
            color: HealingStitchColors.pink,
            size: 48,
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: HealingStitchColors.pink,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: healingText(size: 14, color: HealingStitchColors.textMain),
            ),
            const SizedBox(height: 16),
            HealingGradientButton(
              label: 'Thử lại',
              icon: Icons.refresh,
              onTap: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
