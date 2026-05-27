import 'package:bondy/widgets/home/emotion_checkin_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EmotionCheckinWidget', () {
    testWidgets('renders partner name and check-in CTA', (tester) async {
      final data = {'partner_name': 'Minh', 'relationship_id': 'rel_123'};

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: EmotionCheckinWidget(data: data),
            ),
          ),
        ),
      );

      expect(find.textContaining('Minh'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('opens relationship check-in flow from CTA', (tester) async {
      final data = {'partner_name': 'Test', 'relationship_id': 'rel_123'};

      await tester.pumpWidget(
        MaterialApp(
          routes: {
            '/relationship/checkin': (_) =>
                const Scaffold(body: Text('relationship check-in')),
          },
          home: Scaffold(
            body: SingleChildScrollView(
              child: EmotionCheckinWidget(data: data),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('relationship check-in'), findsOneWidget);
    });
  });
}
