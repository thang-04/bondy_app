import 'package:bondy/models/healing/healing_models.dart';
import 'package:bondy/screens/healing/healing_audio_player_screen.dart';
import 'package:bondy/services/healing/healing_data_source.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('keeps plan audio completable when the audio file is unavailable', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    Object? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => HealingAudioPlayerScreen(
                    planMode: true,
                    audioId: 'audio-name-the-loop',
                    service: _FakeAudioDataSource(),
                  ),
                ),
              );
            },
            child: const Text('Open audio'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open audio'));
    await tester.pumpAndSettle();

    expect(find.text('Day 1 audio'), findsOneWidget);
    expect(find.textContaining('file'), findsOneWidget);

    await tester.tap(find.textContaining('session'));
    await tester.pumpAndSettle();

    expect(result, isTrue);
  });
}

class _FakeAudioDataSource implements HealingDataSource {
  @override
  Future<HealingAudio> fetchAudio(String id) async => HealingAudio.fromJson({
    'id': id,
    'title': 'Day 1 audio',
    'summary': 'A plan audio without an uploaded file yet.',
    'category': 'reflection',
    'audioUrl': '',
    'durationSeconds': 360,
    'narratorName': 'Bondy Voice',
  });

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
