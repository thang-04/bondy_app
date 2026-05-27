import 'package:bondy/models/healing/healing_models.dart';
import 'package:bondy/screens/healing/ritual_audio_detail_screen.dart';
import 'package:bondy/screens/healing/ritual_reading_detail_screen.dart';
import 'package:bondy/services/healing/healing_data_source.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ritual reading detail uses a full article-style layout', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RitualReadingDetailScreen(
          ritualId: 'ritual-1',
          service: _FakeRitualDataSource(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Image), findsWidgets);
    expect(find.text('Bondy Wellness Team'), findsOneWidget);
    expect(find.text('Đã đọc xong'), findsOneWidget);
  });

  testWidgets('ritual audio detail uses a rich audio preview layout', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: RitualAudioDetailScreen()));

    expect(find.byType(Image), findsWidgets);
    await tester.scrollUntilVisible(
      find.text('Bạn sẽ nhận được gì sau 5 phút'),
      180,
    );
    expect(find.text('Bạn sẽ nhận được gì sau 5 phút'), findsOneWidget);
    expect(find.text('Phát ngay'), findsOneWidget);
  });
}

class _FakeRitualDataSource implements HealingDataSource {
  @override
  Future<HealingRitual> fetchRitual(String id) async => HealingRitual.fromJson({
    'id': id,
    'title': 'Ritual',
    'summary': 'A short grounding ritual.',
    'category': 'daily',
    'durationMinutes': 5,
  });

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
