import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bondy/main.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    try {
      await dotenv.load(fileName: '.env');
    } catch (e) {
      // dotenv.load may fail in test context, ignore and use fallback URLs
    }
  });

  testWidgets('App loads smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const BondyApp());

    // Because this is a huge app with providers, we just ensure it builds without error.
    expect(find.byType(BondyApp), findsOneWidget);
  });
}
