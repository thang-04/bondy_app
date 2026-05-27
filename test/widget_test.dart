import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bondy/services/auth_service.dart';

void main() {
  test('AuthService resolves API base URL', () {
    final url = AuthService.resolveBaseUrl(
      baseUrlOverride: 'https://api.example.com/api',
    );
    expect(url, 'https://api.example.com/api');
  });

  testWidgets('Material smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Text('Bondy')),
      ),
    );
    expect(find.text('Bondy'), findsOneWidget);
  });
}
