import 'package:bondy/screens/auth/google_map_location_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('location setup renders free map flow without Google Maps key', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: GoogleMapLocationScreen(),
      ),
    );
    await tester.pump();

    expect(find.text('Vị trí của bạn'), findsOneWidget);
    expect(find.text('Xác nhận vị trí'), findsOneWidget);
    expect(find.textContaining('GPS'), findsOneWidget);
    expect(find.byIcon(Icons.location_on), findsOneWidget);
  });
}
