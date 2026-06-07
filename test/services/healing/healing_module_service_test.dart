import 'dart:convert';

import 'package:bondy/services/api_client.dart';
import 'package:bondy/services/auth_service.dart';
import 'package:bondy/services/healing/healing_service.dart';
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

  test(
    'adapts the current healing home payload for the full UI module',
    () async {
      final client = await authenticatedClient(
        MockClient((request) async {
          expect(request.method, 'GET');
          expect(
            request.url.toString(),
            'https://api.example.com/api/healing/home',
          );
          return _utf8Response({
            'success': true,
            'data': {
              'flowState': {
                'isFirstTime': false,
                'hasInProgress': false,
                'hasTodayCheckin': true,
                'primaryIntent': 'STABILIZE',
                'topBlock': 'START_PATH',
              },
              'todayCheckin': {
                'mood': 'ANXIOUS',
                'readiness': 'NOT_READY',
                'needs': ['REASSURANCE'],
                'trigger': 'LONG_NO_REPLY_48H',
                'smallGoal': 'Take one slow breath',
                'source': 'VOLUNTARY',
                'createdAt': '2026-05-17T08:00:00.000Z',
              },
              'todayForYou': {},
              'continueJourney': null,
              'recommendedPlan': {
                'templateId': 'plan-reflect',
                'title': 'Gọi tên vòng lặp',
                'description': '3 ngày phản tư',
                'durationDays': 3,
                'currentDay': null,
                'lastCompletedDay': 0,
                'progressPercent': 0,
                'days': [],
              },
              'activePlanSummary': null,
              'journalPreview': [],
              'articles': [
                {
                  'id': 'article-1',
                  'type': 'ARTICLE',
                  'title': 'Article',
                  'summary': 'Summary',
                  'category': 'reflection',
                  'accessLevel': 'FREE',
                  'isLocked': false,
                },
              ],
              'exercises': [],
              'audios': [
                {
                  'id': 'audio-1',
                  'type': 'AUDIO',
                  'title': 'Grounding audio',
                  'summary': 'Audio summary',
                  'category': 'grounding',
                  'accessLevel': 'FREE',
                  'isLocked': false,
                },
              ],
              'rituals': [
                {
                  'id': 'ritual-1',
                  'type': 'RITUAL',
                  'title': 'Morning reset',
                  'summary': 'Ritual summary',
                  'category': 'daily',
                  'accessLevel': 'FREE',
                  'isLocked': false,
                },
              ],
              'courses': [],
            },
          });
        }),
      );

      final home = await HealingApiDataSource(apiClient: client).fetchHome();

      expect(home.todayMood?.mood, 'ANXIOUS');
      expect(home.todayMood?.intensity, 8);
      expect(home.recommendedPlan?.title, 'Gọi tên vòng lặp');
      expect(home.sections.articles.single.title, 'Article');
      expect(home.sections.audios.single.title, 'Grounding audio');
      expect(home.sections.rituals.single.title, 'Morning reset');
    },
  );

  test(
    'translates legacy UI check-in input to the current server contract',
    () async {
      final client = await authenticatedClient(
        MockClient((request) async {
          expect(request.method, 'POST');
          expect(
            request.url.toString(),
            'https://api.example.com/api/healing/checkin',
          );
          expect(jsonDecode(request.body), {
            'mood': 'ANXIOUS',
            'readiness': 'NOT_READY',
            'needs': ['CALM_DOWN'],
            'trigger': 'LONG_NO_REPLY_48H',
            'smallGoal': 'Take one slow breath',
            'source': 'VOLUNTARY',
          });
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'emotionalLog': null,
                'persisted': false,
                'routeAfterCheckin': 'HEALING_HOME',
                'recoveryBundle': {},
              },
            }),
            200,
          );
        }),
      );

      await HealingApiDataSource(apiClient: client).checkIn(
        mood: 'ANXIOUS',
        intensity: 8,
        context: 'LONG_NO_REPLY_48H',
        note: 'Take one slow breath',
      );
    },
  );

  test(
    'loads entry state and active timeline for adaptive healing flow',
    () async {
      final client = await authenticatedClient(
        MockClient((request) async {
          if (request.url.path.endsWith('/healing/entry')) {
            expect(request.url.queryParameters['entry'], 'VOLUNTARY');
            return _utf8Response({
              'success': true,
              'data': {
                'entry': 'VOLUNTARY',
                'requiresAssessment': true,
                'assessmentType': 'MINI_HEALING',
                'assessment': null,
                'assignment': null,
              },
            });
          }

          expect(
            request.url.toString(),
            'https://api.example.com/api/healing/plan/timeline',
          );
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'assignmentId': 'assignment-1',
                'templateId': 'plan-reflect',
                'currentDay': 2,
                'lastCompletedDay': 1,
                'progressPercent': 33,
                'days': [
                  {
                    'dayNumber': 1,
                    'title': 'Observe',
                    'isUnlocked': true,
                    'isCompleted': true,
                  },
                ],
              },
            }),
            200,
          );
        }),
      );

      final source = HealingApiDataSource(apiClient: client);
      final entry = await source.fetchEntryState();
      final timeline = await source.fetchActivePlanTimeline();

      expect(entry.requiresAssessment, isTrue);
      expect(timeline.progressPercent, 33);
      expect(timeline.days.single.isCompleted, isTrue);
    },
  );

  test('loads plan preview, starts plan, and completes plan items', () async {
    final client = await authenticatedClient(
      MockClient((request) async {
        if (request.url.path.endsWith('/healing/plan/preview')) {
          return _utf8Response({
            'success': true,
            'data': {
              'templateId': 'plan-reflect',
              'title': 'Gọi tên vòng lặp',
              'description': '3 ngày phản tư',
              'durationDays': 3,
              'currentDay': null,
              'lastCompletedDay': 0,
              'progressPercent': 0,
              'days': [],
            },
          });
        }
        if (request.url.path.endsWith('/healing/plan/start')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'started': true,
                'assignment': {
                  'id': 'assignment-1',
                  'templateId': 'plan-reflect',
                  'status': 'IN_PROGRESS',
                  'currentDay': 1,
                  'lastCompletedDay': 0,
                },
              },
            }),
            200,
          );
        }

        expect(
          request.url.toString(),
          'https://api.example.com/api/healing/plan/items/article-1/complete',
        );
        expect(jsonDecode(request.body), {
          'completionType': 'ARTICLE',
          'durationSeconds': 90,
          'answers': null,
        });
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'completed': true,
              'completion': {'contentId': 'article-1'},
            },
          }),
          200,
        );
      }),
    );

    final source = HealingApiDataSource(apiClient: client);
    final preview = await source.fetchRecommendedPlanPreview();
    final started = await source.startRecommendedPlan();
    final completed = await source.completePlanItem(
      'article-1',
      completionType: 'ARTICLE',
      durationSeconds: 90,
    );

    expect(preview.title, 'Gọi tên vòng lặp');
    expect(started.started, isTrue);
    expect(completed.completed, isTrue);
  });

  test('confirms replacement when starting a course', () async {
    final client = await authenticatedClient(
      MockClient((request) async {
        expect(request.method, 'POST');
        expect(
          request.url.toString(),
          'https://api.example.com/api/healing/courses/course-new/start',
        );
        expect(jsonDecode(request.body), {'replaceActive': true});
        return _utf8Response({
          'success': true,
          'data': {
            'started': true,
            'progress': {
              'courseId': 'course-new',
              'status': 'IN_PROGRESS',
              'startedAt': '2026-06-07T10:00:00.000Z',
              'currentDay': 1,
              'lastCompletedDay': 0,
            },
            'course': {
              'id': 'course-new',
              'type': 'COURSE',
              'title': 'Lộ trình mới',
              'summary': '',
              'category': 'healing',
              'accessLevel': 'FREE',
              'isLocked': false,
            },
          },
        });
      }),
    );

    final result = await HealingApiDataSource(
      apiClient: client,
    ).startCourse('course-new', replaceActive: true);

    expect(result.started, isTrue);
  });
}

http.Response _utf8Response(Map<String, dynamic> body) {
  return http.Response.bytes(
    utf8.encode(jsonEncode(body)),
    200,
    headers: const {'content-type': 'application/json; charset=utf-8'},
  );
}
