import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bondy/widgets/onboarding/onboarding_tooltip.dart';

void main() {
  testWidgets('OnboardingTooltip should display titles, contents and invoke callbacks', (WidgetTester tester) async {
    bool nextCalled = false;
    bool skipCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OnboardingTooltip(
            title: 'Welcome Tour',
            content: 'Let us show you around',
            icon: '👋',
            currentStep: 1,
            totalSteps: 2,
            onNext: () => nextCalled = true,
            onSkip: () => skipCalled = true,
          ),
        ),
      ),
    );

    expect(find.text('Welcome Tour'), findsOneWidget);
    expect(find.text('Let us show you around'), findsOneWidget);
    expect(find.text('BƯỚC 1/2'), findsOneWidget);

    await tester.tap(find.text('Tiếp tục'));
    await tester.pump();
    expect(nextCalled, true);

    await tester.tap(find.text('Bỏ qua'));
    await tester.pump();
    expect(skipCalled, true);
  });
}
