import 'package:bondy/widgets/home/banner_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BannerWidget', () {
    testWidgets('renders title and cta', (tester) async {
      final data = {
        'title': 'Hoàn thành khảo sát',
        'cta': 'Bắt đầu ngay',
        'action': 'COMPLETE_SURVEY',
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BannerWidget(data: data),
          ),
        ),
      );

      expect(find.text('Hoàn thành khảo sát'), findsOneWidget);
      expect(find.text('Bắt đầu ngay'), findsOneWidget);
    });

    testWidgets('uses correct gradient colors', (tester) async {
      final data = {'title': 'Test', 'cta': 'CTA', 'action': ''};

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BannerWidget(data: data),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.gradient, isNotNull);
    });
  });
}