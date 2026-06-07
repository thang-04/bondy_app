import 'package:bondy/models/healing/healing_models.dart';
import 'package:bondy/screens/healing/healing_mode_dashboard_screen.dart';
import 'package:bondy/services/healing/healing_data_source.dart';
import 'package:bondy/services/healing/healing_progress_store.dart';
import 'package:bondy/viewmodels/healing/healing_home_viewmodel.dart';
import 'package:bondy/widgets/navigation/bondy_bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() => HealingProgressStore.instance.clear());

  testWidgets(
    'auto opens quick check-in when user enters without today check-in',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HealingModeDashboardScreen(
            viewModel: HealingHomeViewModel(
              service: _FakeHealingDataSource(_home(hasTodayCheckin: false)),
              displayNameLoader: _noDisplayName,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.text('Your check-ins are private and secure.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('hides its own bottom nav when embedded in the main shell', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HealingModeDashboardScreen(
          showBottomNavigation: false,
          viewModel: HealingHomeViewModel(
            service: _FakeHealingDataSource(_home(hasTodayCheckin: true)),
            displayNameLoader: _noDisplayName,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(BondyBottomNavBar), findsNothing);
  });

  testWidgets(
    'hides quick check-in action after user already checked in today',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HealingModeDashboardScreen(
            viewModel: HealingHomeViewModel(
              service: _FakeHealingDataSource(_home(hasTodayCheckin: true)),
              displayNameLoader: _noDisplayName,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Check-in nhanh'), findsNothing);
      await tester.scrollUntilVisible(
        find.byKey(const Key('today-checkin-summary-card')),
        200,
      );
      expect(
        find.byKey(const Key('today-checkin-summary-card')),
        findsOneWidget,
      );
    },
  );

  testWidgets('shows current plan day only after the user has started a plan', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HealingModeDashboardScreen(
          viewModel: HealingHomeViewModel(
            service: _FakeHealingDataSource(
              _home(
                hasTodayCheckin: true,
                activePlanSummary: {
                  'assignmentId': 'assignment-1',
                  'templateId': 'plan-reflect',
                  'title': 'Gọi tên vòng lặp',
                  'description': '3 ngày phản tư',
                  'durationDays': 3,
                  'currentDay': 2,
                  'lastCompletedDay': 1,
                  'progressPercent': 33,
                  'days': [],
                },
              ),
            ),
            displayNameLoader: _noDisplayName,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.textContaining('Ngày 2/3'), findsOneWidget);
    expect(find.text('Gọi tên vòng lặp'), findsOneWidget);
  });

  testWidgets('shows a plan discovery CTA before the user starts a plan', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HealingModeDashboardScreen(
          viewModel: HealingHomeViewModel(
            service: _FakeHealingDataSource(
              _home(
                hasTodayCheckin: true,
                recommendedPlan: {
                  'templateId': 'plan-reflect',
                  'title': 'Gọi tên vòng lặp',
                  'description': '3 ngày phản tư',
                  'durationDays': 3,
                  'currentDay': null,
                  'lastCompletedDay': 0,
                  'progressPercent': 0,
                  'days': [],
                },
              ),
            ),
            displayNameLoader: _noDisplayName,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Khám phá lộ trình phù hợp'),
      200,
    );
    expect(find.text('Khám phá lộ trình phù hợp'), findsOneWidget);
    expect(find.textContaining('Ngày 1/3'), findsNothing);
  });
  testWidgets('opens active plan audio in plan mode and records completion', (
    tester,
  ) async {
    final source = _FakeHealingDataSource(
      _home(
        hasTodayCheckin: true,
        activePlanSummary: {
          'assignmentId': 'assignment-1',
          'templateId': 'plan-reflect',
          'title': 'Active plan',
          'description': 'Daily plan',
          'durationDays': 3,
          'currentDay': 1,
          'lastCompletedDay': 0,
          'progressPercent': 0,
          'days': [
            {
              'dayNumber': 1,
              'title': 'Start',
              'isUnlocked': true,
              'isCompleted': false,
              'items': [
                {
                  'type': 'AUDIO',
                  'contentId': 'audio-grounding',
                  'isCompleted': false,
                },
              ],
            },
          ],
        },
      ),
    );
    Object? routeArgs;

    await tester.pumpWidget(
      MaterialApp(
        home: HealingModeDashboardScreen(
          viewModel: HealingHomeViewModel(
            service: source,
            displayNameLoader: _noDisplayName,
          ),
        ),
        onGenerateRoute: (settings) {
          if (settings.name == '/healing/audio-player') {
            routeArgs = settings.arguments;
            return MaterialPageRoute<void>(
              builder: (context) => Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Complete fake audio'),
                  ),
                ),
              ),
            );
          }
          return null;
        },
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Audio'));
    await tester.pumpAndSettle();

    expect(routeArgs, {'audioId': 'audio-grounding', 'planMode': true});

    await tester.tap(find.text('Complete fake audio'));
    await tester.pumpAndSettle();

    expect(source.completedPlanItems, [
      {'id': 'audio-grounding', 'type': 'AUDIO'},
    ]);
  });

  testWidgets('opens unlocked previous plan day item and records completion', (
    tester,
  ) async {
    final source = _FakeHealingDataSource(
      _home(
        hasTodayCheckin: true,
        activePlanSummary: {
          'assignmentId': 'assignment-1',
          'templateId': 'plan-reflect',
          'title': 'Active plan',
          'description': 'Daily plan',
          'durationDays': 3,
          'currentDay': 2,
          'lastCompletedDay': 0,
          'progressPercent': 0,
          'days': [
            {
              'dayNumber': 1,
              'title': 'Previous day',
              'isUnlocked': true,
              'isCompleted': false,
              'items': [
                {
                  'type': 'AUDIO',
                  'contentId': 'audio-day-1',
                  'isCompleted': false,
                },
              ],
            },
            {
              'dayNumber': 2,
              'title': 'Current day',
              'isUnlocked': true,
              'isCompleted': false,
              'items': [
                {
                  'type': 'REFLECTION',
                  'contentId': 'reflection-day-2',
                  'isCompleted': false,
                },
              ],
            },
            {
              'dayNumber': 3,
              'title': 'Future day',
              'isUnlocked': false,
              'isCompleted': false,
              'items': [],
            },
          ],
        },
      ),
    );
    Object? routeArgs;

    await tester.pumpWidget(
      MaterialApp(
        home: HealingModeDashboardScreen(
          viewModel: HealingHomeViewModel(
            service: source,
            displayNameLoader: _noDisplayName,
          ),
        ),
        onGenerateRoute: (settings) {
          if (settings.name == '/healing/audio-player') {
            routeArgs = settings.arguments;
            return MaterialPageRoute<void>(
              builder: (context) => Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Complete fake previous audio'),
                  ),
                ),
              ),
            );
          }
          return null;
        },
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Reflection'), findsOneWidget);
    expect(find.text('Audio'), findsNothing);
    await tester.tap(find.text('Previous day'));
    await tester.pumpAndSettle();

    expect(find.text('Audio'), findsOneWidget);
    await tester.tap(find.text('Audio'));
    await tester.pumpAndSettle();

    expect(routeArgs, {'audioId': 'audio-day-1', 'planMode': true});

    await tester.tap(find.text('Complete fake previous audio'));
    await tester.pumpAndSettle();

    expect(source.completedPlanItems, [
      {'id': 'audio-day-1', 'type': 'AUDIO'},
    ]);
  });

  testWidgets('toggles active plan day task lists from day headers', (
    tester,
  ) async {
    final source = _FakeHealingDataSource(
      _home(
        hasTodayCheckin: true,
        activePlanSummary: {
          'assignmentId': 'assignment-1',
          'templateId': 'plan-reflect',
          'title': 'Active plan',
          'description': 'Daily plan',
          'durationDays': 3,
          'currentDay': 2,
          'lastCompletedDay': 0,
          'progressPercent': 0,
          'days': [
            {
              'dayNumber': 1,
              'title': 'Previous day',
              'isUnlocked': true,
              'isCompleted': false,
              'items': [
                {
                  'type': 'AUDIO',
                  'contentId': 'audio-day-1',
                  'isCompleted': false,
                },
              ],
            },
            {
              'dayNumber': 2,
              'title': 'Current day',
              'isUnlocked': true,
              'isCompleted': false,
              'items': [
                {
                  'type': 'REFLECTION',
                  'contentId': 'reflection-day-2',
                  'isCompleted': false,
                },
              ],
            },
          ],
        },
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: HealingModeDashboardScreen(
          viewModel: HealingHomeViewModel(
            service: source,
            displayNameLoader: _noDisplayName,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Reflection'), findsOneWidget);
    expect(find.text('Audio'), findsNothing);

    await tester.tap(find.text('Previous day'));
    await tester.pumpAndSettle();

    expect(find.text('Reflection'), findsOneWidget);
    expect(find.text('Audio'), findsOneWidget);

    await tester.tap(find.text('Previous day'));
    await tester.pumpAndSettle();

    expect(find.text('Reflection'), findsOneWidget);
    expect(find.text('Audio'), findsNothing);

    await tester.tap(find.text('Current day'));
    await tester.pumpAndSettle();

    expect(find.text('Reflection'), findsNothing);
  });

  testWidgets('keeps future locked plan day items hidden', (tester) async {
    final source = _FakeHealingDataSource(
      _home(
        hasTodayCheckin: true,
        activePlanSummary: {
          'assignmentId': 'assignment-1',
          'templateId': 'plan-reflect',
          'title': 'Active plan',
          'description': 'Daily plan',
          'durationDays': 3,
          'currentDay': 2,
          'lastCompletedDay': 0,
          'progressPercent': 0,
          'days': [
            {
              'dayNumber': 1,
              'title': 'Previous day',
              'isUnlocked': true,
              'isCompleted': false,
              'items': [],
            },
            {
              'dayNumber': 2,
              'title': 'Current day',
              'isUnlocked': true,
              'isCompleted': false,
              'items': [],
            },
            {
              'dayNumber': 3,
              'title': 'Future day',
              'isUnlocked': false,
              'isCompleted': false,
              'items': [
                {
                  'type': 'AUDIO',
                  'contentId': 'audio-day-3',
                  'isCompleted': false,
                },
              ],
            },
          ],
        },
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: HealingModeDashboardScreen(
          viewModel: HealingHomeViewModel(
            service: source,
            displayNameLoader: _noDisplayName,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Audio'), findsNothing);
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    await tester.tap(find.text('Future day'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('Audio'), findsNothing);
  });

  testWidgets(
    'shows content hub CTA for active plan and navigates to content',
    (tester) async {
      bool openedContentHub = false;

      await tester.pumpWidget(
        MaterialApp(
          home: HealingModeDashboardScreen(
            viewModel: HealingHomeViewModel(
              service: _FakeHealingDataSource(
                _home(
                  hasTodayCheckin: true,
                  activePlanSummary: {
                    'assignmentId': 'assignment-1',
                    'templateId': 'plan-reflect',
                    'title': 'Active plan',
                    'description': 'Daily plan',
                    'durationDays': 3,
                    'currentDay': 2,
                    'lastCompletedDay': 0,
                    'progressPercent': 0,
                    'days': [],
                  },
                ),
              ),
              displayNameLoader: _noDisplayName,
            ),
          ),
          onGenerateRoute: (settings) {
            if (settings.name == '/content') {
              openedContentHub = true;
              return MaterialPageRoute<void>(
                builder: (_) => const Scaffold(
                  body: Center(child: Text('Content hub opened')),
                ),
              );
            }
            return null;
          },
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Khám phá Content Hub'), findsOneWidget);
      await tester.tap(find.text('Khám phá Content Hub'));
      await tester.pumpAndSettle();

      expect(openedContentHub, isTrue);
      expect(find.text('Content hub opened'), findsOneWidget);
    },
  );
}

Future<String?> _noDisplayName() async => null;

HealingHomeData _home({
  required bool hasTodayCheckin,
  Map<String, dynamic>? activePlanSummary,
  Map<String, dynamic>? recommendedPlan,
}) {
  return HealingHomeData.fromJson({
    'flowState': {
      'isFirstTime': false,
      'hasInProgress': false,
      'hasTodayCheckin': hasTodayCheckin,
      'primaryIntent': 'REFLECT',
      'topBlock': 'START_PATH',
    },
    'todayCheckin': hasTodayCheckin
        ? {
            'mood': 'ANXIOUS',
            'readiness': 'EXPLORING',
            'needs': ['CLARITY'],
            'trigger': 'USER_SELF_REPORT',
            'smallGoal': 'Take a breath',
            'source': 'VOLUNTARY',
            'createdAt': '2026-05-18T08:00:00.000Z',
          }
        : null,
    'todayForYou': {},
    'activePlanSummary': activePlanSummary,
    'recommendedPlan': recommendedPlan,
    'journalPreview': [],
    'articles': [],
    'exercises': [],
    'audios': [],
    'rituals': [],
    'courses': [],
  });
}

class _FakeHealingDataSource implements HealingDataSource {
  final HealingHomeData home;
  final List<Map<String, String>> completedPlanItems = [];

  _FakeHealingDataSource(this.home);

  @override
  Future<HealingHomeData> fetchHome() async => home;

  @override
  Future<HealingCheckinResult> checkIn({
    required String mood,
    required int intensity,
    String? context,
    String source = 'VOLUNTARY',
    String? note,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<HealingArticle> fetchArticle(String id) => throw UnimplementedError();

  @override
  Future<HealingCompletionResult> completeArticle(
    String id, {
    int? durationSeconds,
    Object? answers,
  }) => throw UnimplementedError();

  @override
  Future<HealingAudio> fetchAudio(String id) => throw UnimplementedError();

  @override
  Future<HealingRitual> fetchRitual(String id) => throw UnimplementedError();

  @override
  Future<HealingExercise> fetchExercise(String id) =>
      throw UnimplementedError();

  @override
  Future<HealingCompletionResult> completeExercise(
    String id, {
    int? durationSeconds,
    Object? answers,
  }) => throw UnimplementedError();

  @override
  Future<HealingCourse> fetchCourse(String id) => throw UnimplementedError();

  @override
  Future<HealingCourseStartResult> startCourse(
    String id, {
    bool replaceActive = false,
  }) => throw UnimplementedError();

  @override
  Future<HealingCompletionResult> completeLesson(
    String courseId,
    String lessonId, {
    int? durationSeconds,
    Object? answers,
  }) => throw UnimplementedError();

  @override
  Future<HealingEntryState> fetchEntryState({String entry = 'VOLUNTARY'}) =>
      throw UnimplementedError();

  @override
  Future<HealingPlanTimeline> fetchActivePlanTimeline() =>
      throw UnimplementedError();

  @override
  Future<HealingPlanPreview> fetchRecommendedPlanPreview() =>
      throw UnimplementedError();

  @override
  Future<HealingPlanStartResult> startRecommendedPlan() =>
      throw UnimplementedError();

  @override
  Future<HealingCompletionResult> completePlanItem(
    String id, {
    required String completionType,
    int? durationSeconds,
    Object? answers,
  }) async {
    completedPlanItems.add({'id': id, 'type': completionType});
    return HealingCompletionResult.fromJson({
      'completed': true,
      'completion': {'contentId': id},
    });
  }
}
