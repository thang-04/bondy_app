import 'dart:convert';

import 'package:bondy/services/api_client.dart';
import 'package:bondy/services/auth_service.dart';
import 'package:bondy/services/relationship_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('rewrites relative inviter photos for display', () {
    final invitation = RelationshipInvitation.fromJson({
      'id': 'invite-1',
      'inviterId': 'user-1',
      'inviterName': 'An',
      'inviterPhoto': '/uploads/profiles/an.jpg',
      'status': 'PENDING',
      'createdAt': '2026-06-07T10:00:00.000Z',
    });

    expect(invitation.inviterPhoto, isNotNull);
    expect(invitation.inviterPhoto, endsWith('/uploads/profiles/an.jpg'));
    expect(invitation.inviterPhoto, startsWith('http'));
  });

  test('rewrites relative partner photos for the relationship home', () {
    final dashboard = RelationshipDashboard.fromJson({
      'hasRelationship': true,
      'relationshipId': 'relationship-1',
      'partner': {
        'id': 'user-2',
        'name': 'Bình',
        'photoUrl': '/uploads/profiles/binh.jpg',
      },
    });

    expect(dashboard.partnerPhotoUrl, isNotNull);
    expect(dashboard.partnerPhotoUrl, endsWith('/uploads/profiles/binh.jpg'));
    expect(dashboard.partnerPhotoUrl, startsWith('http'));
  });

  test('loads relationship timeline items from the API', () async {
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
        expect(request.method, 'GET');
        expect(
          request.url.toString(),
          'https://api.example.com/api/relationships/timeline',
        );
        expect(request.headers['authorization'], 'Bearer access-token');
        return http.Response(
          jsonEncode({
            'success': true,
            'data': [
              {
                'id': 'milestone-1',
                'type': 'MILESTONE',
                'title': '100 ngày bên nhau',
                'description': 'Một cột mốc đáng nhớ',
                'occurredAt': '2026-06-07T10:00:00.000Z',
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );

    final items = await RelationshipService(
      apiClient: apiClient,
    ).fetchTimeline();

    expect(items, hasLength(1));
    expect(items.single.type, RelationshipTimelineItemType.milestone);
    expect(items.single.title, '100 ngày bên nhau');
    expect(items.single.occurredAt, DateTime.utc(2026, 6, 7, 10));
  });

  test('persists daily action reminder state through the API', () async {
    final storage = FlutterSecureStorage();
    await storage.write(key: 'accessToken', value: 'access-token');
    final remindAt = DateTime.utc(2026, 6, 8, 2);
    final authService = AuthService(
      baseUrlOverride: 'https://api.example.com/api',
      storage: storage,
    );
    final apiClient = ApiClient(
      baseUrlOverride: 'https://api.example.com/api',
      authService: authService,
      client: MockClient((request) async {
        expect(request.method, 'POST');
        expect(
          request.url.toString(),
          'https://api.example.com/api/relationships/daily-action/state',
        );
        expect(jsonDecode(request.body), {
          'actionKey': 'gratitude_note',
          'dateKey': '2026-06-07',
          'status': 'REMINDED',
          'remindAt': remindAt.toIso8601String(),
        });
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'actionKey': 'gratitude_note',
              'dateKey': '2026-06-07',
              'title': 'Gửi một lời cảm ơn chân thành',
              'description': 'Một lời cảm ơn nhỏ bé...',
              'status': 'REMINDED',
              'remindAt': remindAt.toIso8601String(),
            },
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );

    final action = await RelationshipService(apiClient: apiClient)
        .updateDailyActionState(
          actionKey: 'gratitude_note',
          dateKey: '2026-06-07',
          status: RelationshipDailyActionStatus.reminded,
          remindAt: remindAt,
        );

    expect(action.status, RelationshipDailyActionStatus.reminded);
    expect(action.remindAt, remindAt);
  });
}
