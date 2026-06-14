import 'dart:convert';

import 'package:bondy/services/api_client.dart';
import 'package:bondy/services/auth_service.dart';
import 'package:bondy/services/report_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('ReportService', () {
    test('creates report with SPAM reason', () async {
      final storage = FlutterSecureStorage();
      await storage.write(key: 'accessToken', value: 'access-token');
      final authService = AuthService(
        baseUrlOverride: 'https://api.example.com/api',
        storage: storage,
      );
      final apiClient = ApiClient(
        baseUrlOverride: 'https://api.example.com/api',
        authService: authService,
        client: MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.headers['authorization'], 'Bearer access-token');
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['targetUserId'], 'target-user-id');
          expect(body['reason'], 'SPAM');
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {'reportId': 'report-123', 'status': 'CREATED'},
            }),
            200,
          );
        }),
      );
      final service = ReportService(apiClient);

      final result = await service.createReport(
        targetUserId: 'target-user-id',
        reason: ReportReason.spam,
      );

      expect(result.reportId, 'report-123');
      expect(result.status, 'CREATED');
    });

    test('creates report with HARASSMENT reason', () async {
      final storage = FlutterSecureStorage();
      await storage.write(key: 'accessToken', value: 'access-token');
      final authService = AuthService(
        baseUrlOverride: 'https://api.example.com/api',
        storage: storage,
      );
      final apiClient = ApiClient(
        baseUrlOverride: 'https://api.example.com/api',
        authService: authService,
        client: MockClient((request) async {
          expect(request.method, 'POST');
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['reason'], 'HARASSMENT');
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {'reportId': 'report-456', 'status': 'CREATED'},
            }),
            200,
          );
        }),
      );
      final service = ReportService(apiClient);

      final result = await service.createReport(
        targetUserId: 'target-user-id',
        reason: ReportReason.harassment,
      );

      expect(result.reportId, 'report-456');
    });

    test('creates report with FAKE_PROFILE reason', () async {
      final storage = FlutterSecureStorage();
      await storage.write(key: 'accessToken', value: 'access-token');
      final authService = AuthService(
        baseUrlOverride: 'https://api.example.com/api',
        storage: storage,
      );
      final apiClient = ApiClient(
        baseUrlOverride: 'https://api.example.com/api',
        authService: authService,
        client: MockClient((request) async {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['reason'], 'FAKE_PROFILE');
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {'reportId': 'report-789', 'status': 'CREATED'},
            }),
            200,
          );
        }),
      );
      final service = ReportService(apiClient);

      final result = await service.createReport(
        targetUserId: 'fake-user',
        reason: ReportReason.fakeProfile,
      );

      expect(result.reportId, 'report-789');
    });

    test('creates report with INAPPROPRIATE reason', () async {
      final storage = FlutterSecureStorage();
      await storage.write(key: 'accessToken', value: 'access-token');
      final authService = AuthService(
        baseUrlOverride: 'https://api.example.com/api',
        storage: storage,
      );
      final apiClient = ApiClient(
        baseUrlOverride: 'https://api.example.com/api',
        authService: authService,
        client: MockClient((request) async {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['reason'], 'INAPPROPRIATE');
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {'reportId': 'report-999', 'status': 'CREATED'},
            }),
            200,
          );
        }),
      );
      final service = ReportService(apiClient);

      final result = await service.createReport(
        targetUserId: 'inappropriate-user',
        reason: ReportReason.inappropriate,
      );

      expect(result.reportId, 'report-999');
    });

    test('creates report with OTHER reason', () async {
      final storage = FlutterSecureStorage();
      await storage.write(key: 'accessToken', value: 'access-token');
      final authService = AuthService(
        baseUrlOverride: 'https://api.example.com/api',
        storage: storage,
      );
      final apiClient = ApiClient(
        baseUrlOverride: 'https://api.example.com/api',
        authService: authService,
        client: MockClient((request) async {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['reason'], 'OTHER');
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {'reportId': 'report-101', 'status': 'CREATED'},
            }),
            200,
          );
        }),
      );
      final service = ReportService(apiClient);

      final result = await service.createReport(
        targetUserId: 'other-user',
        reason: ReportReason.other,
      );

      expect(result.reportId, 'report-101');
    });

    test('throws ApiClientException when report fails', () async {
      final storage = FlutterSecureStorage();
      await storage.write(key: 'accessToken', value: 'access-token');
      final authService = AuthService(
        baseUrlOverride: 'https://api.example.com/api',
        storage: storage,
      );
      final apiClient = ApiClient(
        baseUrlOverride: 'https://api.example.com/api',
        authService: authService,
        client: MockClient((request) async {
          return http.Response(
            jsonEncode({'success': false, 'error': 'User not found'}),
            404,
          );
        }),
      );
      final service = ReportService(apiClient);

      expect(
        () => service.createReport(
          targetUserId: 'nonexistent',
          reason: ReportReason.spam,
        ),
        throwsA(isA<ApiClientException>()),
      );
    });
  });
}
