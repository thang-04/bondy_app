import 'package:bondy/widgets/home/relationship_strength_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RelationshipStrengthCard', () {
    testWidgets('renders strength score and partner name', (tester) async {
      final data = {
        'partner_name': 'Minh',
        'strength_score': 75,
        'streak_days': 7,
        'common_interests': ['Du lịch', 'Âm nhạc'],
        'last_checkin': '2 giờ trước',
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: RelationshipStrengthCard(data: data),
            ),
          ),
        ),
      );

      expect(find.text('Sức mạnh mối quan hệ'), findsOneWidget);
      expect(find.text('Cùng Minh xây dựng tương lai'), findsOneWidget);
      expect(find.text('75%'), findsOneWidget);
      expect(find.text('7 ngày'), findsOneWidget);
    });

    testWidgets('shows streak badge when streak_days > 0', (tester) async {
      final data = {
        'partner_name': 'Minh',
        'strength_score': 50,
        'streak_days': 3,
        'common_interests': [],
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: RelationshipStrengthCard(data: data),
            ),
          ),
        ),
      );

      expect(find.text('3 ngày'), findsOneWidget);
      expect(find.byIcon(Icons.local_fire_department_rounded), findsOneWidget);
    });

    testWidgets('displays common interests as chips', (tester) async {
      final data = {
        'partner_name': 'Minh',
        'strength_score': 60,
        'streak_days': 0,
        'common_interests': ['Du lịch', 'Âm nhạc', 'Nấu ăn', 'Đọc sách'],
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: RelationshipStrengthCard(data: data),
            ),
          ),
        ),
      );

      expect(find.text('Du lịch'), findsOneWidget);
      expect(find.text('Âm nhạc'), findsOneWidget);
    });

    testWidgets('shows last checkin time when provided', (tester) async {
      final data = {
        'partner_name': 'Minh',
        'strength_score': 80,
        'streak_days': 0,
        'last_checkin': 'Hôm qua',
        'common_interests': [],
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: RelationshipStrengthCard(data: data),
            ),
          ),
        ),
      );

      expect(find.text('Check-in cuối: Hôm qua'), findsOneWidget);
    });
  });
}