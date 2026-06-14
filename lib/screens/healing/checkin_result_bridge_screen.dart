import 'package:flutter/material.dart';

import '../../models/healing/healing_models.dart';
import 'healing_navigation.dart';
import 'healing_stitch_style.dart';

class CheckinResultBridgeScreen extends StatelessWidget {
  const CheckinResultBridgeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final result = args is HealingCheckinResult ? args : null;
    final bundle = result?.recoveryBundle;

    return Scaffold(
      backgroundColor: HealingStitchColors.creamBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BridgeAppBar(
              onClose: () => Navigator.of(
                context,
              ).pushNamedAndRemoveUntil(healingHomeRoute, (_) => false),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
                children: [
                  _MoodHeader(result: result),
                  const SizedBox(height: 14),
                  if (bundle?.groundingMessage.isNotEmpty == true) ...[
                    _GroundingBlock(text: bundle!.groundingMessage),
                    const SizedBox(height: 14),
                  ],
                  if (bundle?.safetyMessage != null) ...[
                    _SafetyAlert(text: bundle!.safetyMessage!),
                    const SizedBox(height: 14),
                  ],
                  ..._buildSuggestions(context, bundle),
                  if (bundle?.reflectionPrompt.isNotEmpty == true) ...[
                    const SizedBox(height: 14),
                    _ReflectionBlock(prompt: bundle!.reflectionPrompt),
                  ],
                  const SizedBox(height: 24),
                  HealingGradientButton(
                    label: _primaryCtaLabel(bundle),
                    icon: Icons.play_arrow_rounded,
                    onTap: () => _onPrimaryCta(context, bundle),
                  ),
                  const SizedBox(height: 10),
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
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSuggestions(
    BuildContext context,
    HealingRecoveryBundle? bundle,
  ) {
    if (bundle == null) return const [];
    final widgets = <Widget>[];
    final ex = bundle.suggestedExercise;
    final ar = bundle.suggestedArticle;
    final co = bundle.suggestedCourse;
    if (ex != null) {
      widgets.add(
        _SuggestionCard(
          item: ex,
          badge: 'BÀI TẬP',
          onTap: () => _openContent(context, ex),
        ),
      );
    }
    if (ar != null) {
      if (widgets.isNotEmpty) widgets.add(const SizedBox(height: 10));
      widgets.add(
        _SuggestionCard(
          item: ar,
          badge: 'BÀI ĐỌC',
          onTap: () => _openContent(context, ar),
        ),
      );
    }
    if (co != null) {
      if (widgets.isNotEmpty) widgets.add(const SizedBox(height: 10));
      widgets.add(
        _SuggestionCard(
          item: co,
          badge: 'KHOÁ HỌC',
          onTap: () => _openContent(context, co),
        ),
      );
    }
    return widgets;
  }

  String _primaryCtaLabel(HealingRecoveryBundle? bundle) {
    if (bundle == null) return 'Về Healing Home';
    if (bundle.suggestedExercise != null) return 'Bắt đầu bài tập';
    if (bundle.suggestedArticle != null) return 'Đọc bài gợi ý';
    if (bundle.suggestedCourse != null) return 'Khám phá khoá học';
    return 'Tiếp tục hành trình';
  }

  void _onPrimaryCta(BuildContext context, HealingRecoveryBundle? bundle) {
    final firstSuggestion =
        bundle?.suggestedExercise ??
        bundle?.suggestedArticle ??
        bundle?.suggestedCourse;
    if (firstSuggestion != null) {
      _openContent(context, firstSuggestion);
      return;
    }
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(healingHomeRoute, (_) => false);
  }

  void _openContent(BuildContext context, HealingContentPreview item) {
    final route = switch (item.type.toUpperCase()) {
      'ARTICLE' => '/healing/article-detail',
      'EXERCISE' => '/healing/exercise-detail',
      'AUDIO' => '/healing/audio-player',
      'COURSE' => '/healing/course-detail',
      'RITUAL' => '/healing/ritual-reading-detail',
      _ => '/healing/article-detail',
    };
    Navigator.of(context).pushNamed(route, arguments: item.id);
  }
}

class _BridgeAppBar extends StatelessWidget {
  final VoidCallback onClose;
  const _BridgeAppBar({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.close), onPressed: onClose),
          Expanded(
            child: Text(
              'Kết quả check-in',
              style: healingText(size: 16, weight: FontWeight.w900),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _MoodHeader extends StatelessWidget {
  final HealingCheckinResult? result;
  const _MoodHeader({required this.result});

  String _moodEmoji(String? mood) {
    return switch ((mood ?? '').toUpperCase()) {
      'ANXIOUS' || 'STRESSED' => '😰',
      'SAD' || 'HURT' => '😢',
      'ANGRY' => '😣',
      'CALM' || 'OK' => '🙂',
      'HAPPY' => '😊',
      _ => '💛',
    };
  }

  String? _extractMood(HealingCheckinResult? result) {
    final log = result?.emotionalLog;
    if (log is Map) {
      final mood = log['mood'];
      if (mood is String) return mood;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final mood = _extractMood(result);
    final acknowledgement =
        result?.recoveryBundle.acknowledgement.isNotEmpty == true
        ? result!.recoveryBundle.acknowledgement
        : 'Bạn đã check-in hôm nay';
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF2F0ED)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(_moodEmoji(mood), style: const TextStyle(fontSize: 36)),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              acknowledgement,
              style: healingText(
                size: 16,
                weight: FontWeight.w900,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GroundingBlock extends StatelessWidget {
  final String text;
  const _GroundingBlock({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFEDD5)),
      ),
      child: Text(
        text,
        style: healingText(
          size: 13,
          height: 1.45,
          color: const Color(0xFF9A3412),
        ),
      ),
    );
  }
}

class _SafetyAlert extends StatelessWidget {
  final String text;
  const _SafetyAlert({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE4E6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFECDD3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.favorite, color: Color(0xFFBE123C), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: healingText(
                size: 12,
                color: const Color(0xFF9F1239),
                height: 1.45,
                weight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  final HealingContentPreview item;
  final String badge;
  final VoidCallback onTap;

  const _SuggestionCard({
    required this.item,
    required this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFF2F0ED)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      badge,
                      style: healingText(
                        size: 10,
                        weight: FontWeight.w900,
                        color: HealingStitchColors.pink,
                      ).copyWith(letterSpacing: 0.8),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.title,
                      style: healingText(size: 14, weight: FontWeight.w900),
                    ),
                    if (item.summary.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.summary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: healingText(
                          size: 12,
                          height: 1.4,
                          color: HealingStitchColors.textSoft,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.arrow_forward, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReflectionBlock extends StatelessWidget {
  final String prompt;
  const _ReflectionBlock({required this.prompt});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFCE7F3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gợi ý phản tư',
            style: healingText(
              size: 11,
              weight: FontWeight.w900,
              color: HealingStitchColors.pink,
            ).copyWith(letterSpacing: 0.8),
          ),
          const SizedBox(height: 6),
          Text(prompt, style: healingText(size: 13, height: 1.45)),
        ],
      ),
    );
  }
}
