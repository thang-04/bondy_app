import 'package:bondy/widgets/home/discovery_card_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'formats home discovery profile location from city and distance',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          routes: {'/discover': (_) => const SizedBox.shrink()},
          home: Scaffold(
            body: DiscoveryCardWidget(
              data: {
                'profiles': [
                  {
                    'name': 'Mai',
                    'city': 'Dong Da, Ha Noi',
                    'distanceKm': 2.5,
                    'common_interests': ['Music'],
                  },
                ],
              },
            ),
          ),
        ),
      );

      expect(
        find.text('C\u00e1ch b\u1ea1n 2.5 km \u2022 Dong Da, Ha Noi'),
        findsOneWidget,
      );
    },
  );

  testWidgets('does not render coordinate strings as home discovery location', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        routes: {'/discover': (_) => const SizedBox.shrink()},
        home: Scaffold(
          body: DiscoveryCardWidget(
            data: {
              'profiles': [
                {
                  'name': 'Mai',
                  'city': '21.027800, 105.834200',
                  'common_interests': ['Music'],
                },
              ],
            },
          ),
        ),
      ),
    );

    expect(find.text('21.027800, 105.834200'), findsNothing);
  });
}
