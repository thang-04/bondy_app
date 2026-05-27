import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/healing/healing_models.dart';
import '../../viewmodels/healing/healing_detail_viewmodels.dart';
import '../../widgets/navigation/bondy_bottom_nav_bar.dart';
import 'healing_stitch_style.dart';

class HealingArticleDetailScreen extends StatefulWidget {
  final String? contentId;
  final HealingArticleViewModel? viewModel;

  const HealingArticleDetailScreen({super.key, this.contentId, this.viewModel});

  @override
  State<HealingArticleDetailScreen> createState() =>
      _HealingArticleDetailScreenState();
}

class _HealingArticleDetailScreenState
    extends State<HealingArticleDetailScreen> {
  HealingArticleViewModel? _viewModel;
  bool _ownsViewModel = false;
  bool _didLoad = false;

  @override
  void dispose() {
    if (_ownsViewModel) {
      _viewModel?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contentId = _contentId(context);
    if (contentId == null || contentId.isEmpty) {
      return _ArticleScaffold(
        article: _legacyArticle,
        isLegacy: true,
        onComplete: () => Navigator.of(context).maybePop(true),
      );
    }

    _viewModel ??= widget.viewModel ?? HealingArticleViewModel();
    _ownsViewModel = widget.viewModel == null;
    if (!_didLoad) {
      _didLoad = true;
      _viewModel!.loadArticle(contentId);
    }

    return AnimatedBuilder(
      animation: _viewModel!,
      builder: (context, _) {
        final viewModel = _viewModel!;
        if (viewModel.isLoading && viewModel.article == null) {
          return const _LoadingArticleScaffold();
        }
        if (viewModel.errorMessage != null && viewModel.article == null) {
          return _ArticleErrorScaffold(
            message: viewModel.errorMessage!,
            onRetry: () => viewModel.loadArticle(contentId),
          );
        }
        final navigator = Navigator.of(context);
        return _ArticleScaffold(
          article: viewModel.article ?? _legacyArticle,
          isLegacy: false,
          isCompleted: viewModel.isCompleted,
          isCompleting: viewModel.isCompleting,
          onComplete: () {
            viewModel.complete().then((_) {
              if (!mounted || !viewModel.isCompleted) return;
              navigator.maybePop(true);
            });
          },
        );
      },
    );
  }

  String? _contentId(BuildContext context) {
    if (widget.contentId != null) return widget.contentId;
    final args = ModalRoute.of(context)?.settings.arguments;
    return args?.toString();
  }
}

class _ArticleScaffold extends StatelessWidget {
  final HealingArticle article;
  final bool isLegacy;
  final bool isCompleted;
  final bool isCompleting;
  final VoidCallback? onComplete;

  const _ArticleScaffold({
    required this.article,
    required this.isLegacy,
    this.isCompleted = false,
    this.isCompleting = false,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HealingStitchColors.creamBackground,
      bottomNavigationBar: BondyBottomNavBar(
        currentIndex: 1,
        onTabSelected: (index) {
          final route = switch (index) {
            0 => '/home',
            1 => '/home/healing',
            2 => '/home/matches',
            3 => '/home/profile',
            _ => '/home',
          };
          Navigator.of(context).pushNamedAndRemoveUntil(route, (_) => false);
        },
        onMatchTap: () => Navigator.of(context).pushNamed('/discover'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(0, 10, 0, 100),
          children: [
            HealingTopBar(
              title: 'Article',
              onBack: () => Navigator.of(context).maybePop(),
            ),
            const SizedBox(height: 8),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              height: 220,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                image: const DecorationImage(
                  image: AssetImage(HealingStitchAssets.meditation),
                  fit: BoxFit.cover,
                ),
                boxShadow: [healingSoftShadow(0.1)],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                article.title,
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
                    backgroundImage: AssetImage(HealingStitchAssets.avatarOne),
                    backgroundColor: HealingStitchColors.creamBackground,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          article.authorName,
                          style: healingText(size: 14, weight: FontWeight.w800),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          article.isExternalPreview
                              ? article.sourceName ?? 'External source'
                              : '${article.estimatedReadMinutes} phút đọc',
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
            if (article.isExternalPreview) ...[
              const SizedBox(height: 16),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFF2F0ED)),
                ),
                child: Text(
                  article.whySuggested,
                  style: healingText(
                    size: 13,
                    color: HealingStitchColors.textSoft,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                article.body.isEmpty ? article.summary : article.body,
                style: healingText(
                  size: 15,
                  height: 1.6,
                  color: HealingStitchColors.textMain,
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SizedBox(
          width: double.infinity,
          child: HealingGradientButton(
            label: article.isExternalPreview
                ? article.externalUrl?.isNotEmpty == true
                      ? 'Copy link nguồn'
                      : 'Chưa có link nguồn'
                : isCompleted
                ? 'Đã hoàn thành'
                : isCompleting
                ? 'Đang hoàn thành...'
                : 'Hoàn thành',
            icon: article.isExternalPreview
                ? Icons.copy
                : isCompleted
                ? Icons.check_circle
                : Icons.check_circle_outline,
            onTap: () {
              if (!article.isExternalPreview) {
                if (!isCompleted && !isCompleting) {
                  onComplete?.call();
                }
                return;
              }

              final url = article.externalUrl;
              if (url == null || url.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Chưa có link nguồn.')),
                );
                return;
              }

              Clipboard.setData(ClipboardData(text: url));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã copy link nguồn.')),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LoadingArticleScaffold extends StatelessWidget {
  const _LoadingArticleScaffold();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: HealingStitchColors.creamBackground,
      body: Center(
        child: CircularProgressIndicator(color: HealingStitchColors.pink),
      ),
    );
  }
}

class _ArticleErrorScaffold extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ArticleErrorScaffold({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HealingStitchColors.creamBackground,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: onRetry,
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final _legacyArticle = HealingArticle.fromJson({
  'id': 'legacy-article',
  'type': 'ARTICLE',
  'sourceType': 'INTERNAL',
  'title': 'Thấu hiểu nỗi đau và sự buông bỏ',
  'summary': 'Bài đọc chữa lành cơ bản',
  'thumbnailUrl': null,
  'category': 'legacy',
  'tags': [],
  'moodTargets': [],
  'contextTargets': [],
  'accessLevel': 'FREE',
  'language': 'vi',
  'reviewStatus': 'APPROVED',
  'isPublished': true,
  'body':
      'Khi một mối quan hệ khép lại, nỗi đau thường để lại một khoảng trống lớn.',
  'estimatedReadMinutes': 5,
  'authorName': 'Bondy Wellness Team',
  'sourceName': null,
  'externalUrl': null,
  'copyrightNote': null,
  'isExternalPreview': false,
  'whySuggested': '',
});
