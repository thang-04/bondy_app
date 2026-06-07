import 'package:bondy/models/healing/healing_models.dart';
import 'package:bondy/screens/healing/healing_course_detail_screen.dart';
import 'package:bondy/services/api_client.dart';
import 'package:bondy/viewmodels/healing/healing_detail_viewmodels.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _ConflictCourseViewModel extends HealingCourseViewModel {
  final List<bool> replaceCalls = [];

  @override
  Future<void> loadCourse(String id) async {
    course = const HealingCourse(
      id: 'course-new',
      title: 'Lộ trình mới',
      summary: 'Một lộ trình khác',
      accessLevel: 'FREE',
      durationDays: 7,
      goal: '',
      scheduleType: 'HYBRID',
      progress: null,
      lessons: [],
    );
    notifyListeners();
  }

  @override
  Future<void> startCourse({bool replaceActive = false}) async {
    replaceCalls.add(replaceActive);
    if (!replaceActive) {
      throw const ApiClientException(
        'Bạn đang có một lộ trình khác.',
        statusCode: 409,
        code: 'ACTIVE_COURSE_CONFIRMATION_REQUIRED',
        data: {
          'activeCourse': {
            'courseId': 'course-current',
            'title': 'Lộ trình hiện tại',
          },
        },
      );
    }
  }
}

void main() {
  Future<_ConflictCourseViewModel> openConflictDialog(
    WidgetTester tester,
  ) async {
    final viewModel = _ConflictCourseViewModel();

    await tester.pumpWidget(
      MaterialApp(
        home: HealingCourseDetailScreen(
          contentId: 'course-new',
          viewModel: viewModel,
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Bắt đầu lộ trình'));
    await tester.pumpAndSettle();
    return viewModel;
  }

  testWidgets('asks before replacing the active healing course', (
    tester,
  ) async {
    final viewModel = await openConflictDialog(tester);

    expect(find.text('Thay đổi lộ trình?'), findsOneWidget);
    expect(find.textContaining('Lộ trình hiện tại'), findsOneWidget);
    expect(find.text('Giữ lộ trình hiện tại'), findsOneWidget);
    expect(find.text('Xác nhận bắt đầu'), findsOneWidget);

    await tester.tap(find.text('Xác nhận bắt đầu'));
    await tester.pumpAndSettle();

    expect(viewModel.replaceCalls, [false, true]);
  });

  testWidgets('keeps the active course when replacement is cancelled', (
    tester,
  ) async {
    final viewModel = await openConflictDialog(tester);

    await tester.tap(find.text('Giữ lộ trình hiện tại'));
    await tester.pumpAndSettle();

    expect(find.text('Thay đổi lộ trình?'), findsNothing);
    expect(viewModel.replaceCalls, [false]);
  });
}
