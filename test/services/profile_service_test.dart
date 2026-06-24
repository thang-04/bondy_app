import 'dart:convert';

import 'package:bondy/services/api_client.dart';
import 'package:bondy/services/auth_service.dart';
import 'package:bondy/services/profile_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

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

  test('updates authenticated profile setup fields', () async {
    final apiClient = await authenticatedClient(
      MockClient((request) async {
        expect(request.method, 'PATCH');
        expect(
          request.url.toString(),
          'https://api.example.com/api/profile/me',
        );
        expect(request.headers['authorization'], 'Bearer access-token');
        expect(jsonDecode(request.body), {
          'fullName': 'Linh',
          'gender': 'Nữ',
          'birthDate': '2000-01-02',
        });
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {'id': 'profile-id', 'fullName': 'Linh'},
          }),
          200,
        );
      }),
    );
    final service = ProfileService(apiClient: apiClient);

    final result = await service.updateProfile(
      fullName: 'Linh',
      gender: 'Nữ',
      birthDate: '2000-01-02',
    );

    expect(result['id'], 'profile-id');
  });

  test('updates authenticated location', () async {
    final apiClient = await authenticatedClient(
      MockClient((request) async {
        expect(request.method, 'PATCH');
        expect(
          request.url.toString(),
          'https://api.example.com/api/profile/location',
        );
        expect(request.headers['authorization'], 'Bearer access-token');
        expect(jsonDecode(request.body), {
          'city': 'Ho Chi Minh',
          'latitude': 10.762622,
          'longitude': 106.660172,
        });
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {'id': 'profile-id', 'city': 'Ho Chi Minh'},
          }),
          200,
        );
      }),
    );
    final service = ProfileService(apiClient: apiClient);

    final result = await service.updateLocation(
      city: 'Ho Chi Minh',
      latitude: 10.762622,
      longitude: 106.660172,
    );

    expect(result['city'], 'Ho Chi Minh');
  });

  test('updates authenticated GPS location without readable city', () async {
    final apiClient = await authenticatedClient(
      MockClient((request) async {
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
    final service = ProfileService(apiClient: apiClient);

    final result = await service.updateLocation(
      city: null,
      latitude: 21.0278,
      longitude: 105.8342,
    );

    expect(result['id'], 'profile-id');
    expect(result['city'], isNull);
  });

  test('surfaces profile validation failures', () async {
    final apiClient = await authenticatedClient(
      MockClient((request) async {
        return http.Response.bytes(
          utf8.encode(
            jsonEncode({'success': false, 'error': 'Dữ liệu không hợp lệ'}),
          ),
          400,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );
    final service = ProfileService(apiClient: apiClient);

    await expectLater(
      service.updateProfile(
        fullName: '',
        gender: 'invalid',
        birthDate: 'bad-date',
      ),
      throwsA(isA<ApiClientException>()),
    );
  });

  test('fetches available interests without auth', () async {
    final mockClient = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.toString(), 'https://api.example.com/api/interests');
      expect(request.headers.containsKey('authorization'), false);
      return http.Response(
        jsonEncode({
          'success': true,
          'data': [
            {'id': 'int-1', 'name': 'Music'},
            {'id': 'int-2', 'name': 'Travel'},
          ],
        }),
        200,
      );
    });
    final apiClient = ApiClient(
      baseUrlOverride: 'https://api.example.com/api',
      client: mockClient,
    );
    final service = ProfileService(apiClient: apiClient);

    final result = await service.getInterests();

    expect(result.length, 2);
    expect(result[0]['id'], 'int-1');
    expect(result[0]['name'], 'Music');
  });

  test('saves selected interests with auth', () async {
    final apiClient = await authenticatedClient(
      MockClient((request) async {
        expect(request.method, 'PUT');
        expect(
          request.url.toString(),
          'https://api.example.com/api/profile/interests',
        );
        expect(request.headers['authorization'], 'Bearer access-token');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['interestIds'], ['int-1', 'int-2']);
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {'saved': 2},
          }),
          200,
        );
      }),
    );
    final service = ProfileService(apiClient: apiClient);

    await service.saveInterests(['int-1', 'int-2']);
  });

  test('handles empty interests list', () async {
    final mockClient = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.toString(), 'https://api.example.com/api/interests');
      return http.Response(jsonEncode({'success': true, 'data': []}), 200);
    });
    final apiClient = ApiClient(
      baseUrlOverride: 'https://api.example.com/api',
      client: mockClient,
    );
    final service = ProfileService(apiClient: apiClient);

    final result = await service.getInterests();

    expect(result, isEmpty);
  });

  test('interests save validates interestIds shape', () async {
    final apiClient = await authenticatedClient(
      MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body.containsKey('interestIds'), true);
        expect(body['interestIds'], isA<List>());
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {'saved': 1},
          }),
          200,
        );
      }),
    );
    final service = ProfileService(apiClient: apiClient);

    await service.saveInterests(['int-1']);
  });
}
