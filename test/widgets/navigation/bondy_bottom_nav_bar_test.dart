import 'package:bondy/widgets/navigation/bondy_bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('nav labels stay on one line on narrow screens', (tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: BondyBottomNavBar(
            currentIndex: 0,
            onTabSelected: (_) {},
            onMatchTap: () {},
          ),
        ),
      ),
    );

    for (final label in [
      'Discover',
      'Healing',
      'Match',
      'Matches',
      'Profile',
    ]) {
      final text = tester.widget<Text>(find.text(label));

      expect(text.maxLines, 1, reason: '$label should not wrap');
      expect(text.softWrap, isFalse, reason: '$label should not wrap');
      expect(text.textAlign, TextAlign.center, reason: '$label should align');
    }
  });
}
