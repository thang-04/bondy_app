import 'package:bondy/screens/relationship/relationship_home_dashboard.dart';
import 'package:bondy/services/relationship_service.dart';
import 'package:bondy/viewmodels/relationship/relationship_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

class _FakeRelationshipService extends RelationshipService {
  RelationshipDailyAction? savedAction;

  @override
  Future<RelationshipDashboard> getDashboard() async {
    return RelationshipDashboard(
      hasRelationship: true,
      relationshipId: 'relationship-1',
      partnerName: 'An',
      daysTogether: 10,
    );
  }

  @override
  Future<RelationshipDailyAction> fetchDailyAction({String? dateKey}) async {
    return RelationshipDailyAction(
      actionKey: 'gratitude_note',
      dateKey: dateKey ?? '2026-06-07',
      title: 'Gửi một lời cảm ơn chân thành',
      description: 'Một lời cảm ơn nhỏ bé có thể thắp sáng cả ngày dài.',
      status: RelationshipDailyActionStatus.active,
    );
  }

  @override
  Future<RelationshipDailyAction> updateDailyActionState({
    required String actionKey,
    required String dateKey,
    required RelationshipDailyActionStatus status,
    DateTime? remindAt,
  }) async {
    savedAction = RelationshipDailyAction(
      actionKey: actionKey,
      dateKey: dateKey,
      title: 'Gửi một lời cảm ơn chân thành',
      description: 'Một lời cảm ơn nhỏ bé có thể thắp sáng cả ngày dài.',
      status: status,
      remindAt: remindAt,
    );
    return savedAction!;
  }
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('timeline button opens the relationship timeline screen', (
    tester,
  ) async {
    final service = _FakeRelationshipService();
    final viewModel = RelationshipViewModel(service: service);

    await tester.pumpWidget(
      MaterialApp(
        routes: {
          '/relationship/timeline': (_) =>
              const Scaffold(body: Text('relationship timeline')),
          '/relationship/checkin': (_) =>
              const Scaffold(body: Text('relationship checkin')),
          '/relationship/conflict-tool': (_) =>
              const Scaffold(body: Text('relationship conflict')),
          '/relationship/milestones': (_) =>
              const Scaffold(body: Text('relationship milestones')),
          '/chatbot': (_) => const Scaffold(body: Text('chatbot')),
        },
        home: RelationshipHomeDashboard(viewModel: viewModel),
      ),
    );
    await tester.pumpAndSettle();

    final timelineButton = find.byKey(
      const Key('relationship_timeline_button'),
    );
    await tester.ensureVisible(timelineButton);
    await tester.tap(timelineButton);
    await tester.pumpAndSettle();

    expect(find.text('relationship timeline'), findsOneWidget);
  });

  testWidgets('remind and skip buttons persist daily action state', (
    tester,
  ) async {
    final service = _FakeRelationshipService();
    final viewModel = RelationshipViewModel(service: service);

    await tester.pumpWidget(
      MaterialApp(home: RelationshipHomeDashboard(viewModel: viewModel)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('relationship_daily_remind_button')));
    await tester.pumpAndSettle();

    expect(service.savedAction?.status, RelationshipDailyActionStatus.reminded);
    expect(find.text('Đã hẹn nhắc'), findsOneWidget);

    await tester.tap(find.byKey(const Key('relationship_daily_skip_button')));
    await tester.pumpAndSettle();

    expect(service.savedAction?.status, RelationshipDailyActionStatus.skipped);
    expect(
      find.byKey(const Key('relationship_daily_action_card')),
      findsNothing,
    );
  });
}
