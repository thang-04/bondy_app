import 'dart:convert';

import 'package:bondy/screens/auth/google_map_location_screen.dart';
import 'package:bondy/services/api_client.dart';
import 'package:bondy/services/auth_service.dart';
import 'package:bondy/services/profile_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    FlutterSecureStorage.setMockInitialValues({});
  });

  Future<ApiClient> authenticatedClient(http.Client client) async {
    const storage = FlutterSecureStorage();
    await storage.write(key: 'accessToken', value: 'access-token');
    final authService = AuthService(
      baseUrlOverride: 'https://api.example.com/api',
      storage: storage,
    );
    return ApiClient(
      baseUrlOverride: 'https://api.example.com/api',
      authService: authService,
      client: client,
    );
  }

  testWidgets('location setup renders free map flow without Google Maps key', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: GoogleMapLocationScreen(showMapTiles: false)),
    );
    await tester.pump();

    expect(find.text('Vị trí của bạn'), findsOneWidget);
    expect(find.text('Xác nhận vị trí'), findsOneWidget);
    expect(find.textContaining('GPS'), findsOneWidget);
    expect(find.byIcon(Icons.location_on), findsOneWidget);
  });

  testWidgets('shared GPS save continues when no readable city is resolved', (
    tester,
  ) async {
    var requestSeen = false;
    var continued = false;
    final apiClient = await authenticatedClient(
      MockClient((request) async {
        requestSeen = true;
        expect(request.method, 'PATCH');
        expect(
          request.url.toString(),
          'https://api.example.com/api/profile/location',
        );
        expect(request.headers['authorization'], 'Bearer access-token');
        expect(jsonDecode(request.body), {
          'latitude': 21.0278,
          'longitude': 105.8342,
        });
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {'id': 'profile-id', 'city': null},
          }),
          200,
        );
      }),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: GoogleMapLocationScreen(
          profileService: ProfileService(apiClient: apiClient),
          initialPosition: const LatLng(21.0278, 105.8342),
          loadCurrentPositionOnStart: false,
          showMapTiles: false,
          resolveAddress: (center, manualAddress) async {
            expect(center.latitude, 21.0278);
            expect(center.longitude, 105.8342);
            expect(manualAddress, isEmpty);
            return null;
          },
          onLocationSaved: (_) async {
            continued = true;
          },
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('location_confirm_button')));
    await tester.pumpAndSettle();

    expect(requestSeen, isTrue);
    expect(continued, isTrue);
    expect(find.textContaining('Khong xac dinh duoc khu vuc'), findsNothing);
  });
}
