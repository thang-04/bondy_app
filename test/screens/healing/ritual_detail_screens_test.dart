import 'package:bondy/models/healing/healing_models.dart';
import 'package:bondy/screens/healing/healing_navigation.dart';
import 'package:bondy/services/healing/healing_data_source.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Redesign §5.6: bỏ 2 màn `ritual_*_detail` trùng lặp. RITUAL giờ được
/// `openRitualContent` phân giải về màn Audio/Đọc chuẩn.
void main() {
  testWidgets('audio rituals route to the canonical audio player', (
    tester,
  ) async {
    String? capturedRoute;
    Object? capturedArgs;

    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: (settings) {
          capturedRoute = settings.name;
          capturedArgs = settings.arguments;
          return MaterialPageRoute<bool>(
            builder: (_) => const Scaffold(body: Text('routed')),
          );
        },
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => openRitualContent(
                  context,
                  'ritual-audio',
                  service: _FakeRitualSource(audioId: 'audio-1'),
                ),
                child: const Text('go'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    expect(capturedRoute, healingAudioPlayerRoute);
    expect(capturedArgs, {'audioId': 'audio-1', 'planMode': false});
  });

  testWidgets('reading rituals route to the canonical article screen', (
    tester,
  ) async {
    String? capturedRoute;
    Object? capturedArgs;

    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: (settings) {
          capturedRoute = settings.name;
          capturedArgs = settings.arguments;
          return MaterialPageRoute<bool>(
            builder: (_) => const Scaffold(body: Text('routed')),
          );
        },
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => openRitualContent(
                  context,
                  'ritual-read',
                  service: _FakeRitualSource(readingId: 'article-9'),
                ),
                child: const Text('go'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    expect(capturedRoute, healingArticleDetailRoute);
    expect(capturedArgs, 'article-9');
  });
}

class _FakeRitualSource implements HealingDataSource {
  final String? audioId;
  final String? readingId;

  _FakeRitualSource({this.audioId, this.readingId});

  @override
  Future<HealingRitual> fetchRitual(String id) async => HealingRitual.fromJson({
    'id': id,
    'title': 'Ritual',
    'summary': 'A short grounding ritual.',
    'category': 'daily',
    'durationMinutes': 5,
    'audioContentId': audioId,
    'readingContentId': readingId,
  });

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
