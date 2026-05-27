import 'package:bondy/widgets/home/emotion_checkin_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EmotionCheckinWidget', () {
    testWidgets('renders partner name and mood options', (tester) async {
      final data = {
        'partner_name': 'Minh',
        'relationship_id': 'rel_123',
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: EmotionCheckinWidget(data: data),
            ),
          ),
        ),
      );

      expect(find.text('Check-in cảm xúc hôm nay'), findsOneWidget);
      expect(find.text('Bạn đang cảm thế nào với Minh?'), findsOneWidget);
      expect(find.text('Vui'), findsOneWidget);
      expect(find.text('Bình yên'), findsOneWidget);
      expect(find.text('Buồn'), findsOneWidget);
      expect(find.text('Lo lắng'), findsOneWidget);
    });

    testWidgets('shows snackbar on mood tap', (tester) async {
      final data = {'partner_name': 'Test', 'relationship_id': 'rel_123'};

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: EmotionCheckinWidget(data: data),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Vui'));
      await tester.pump();

      expect(find.text('Đã ghi nhận cảm xúc: Vui'), findsOneWidget);
    });
  });
}