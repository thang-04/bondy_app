import 'package:bondy/widgets/onboarding/onboarding_overlay.dart';
import 'package:bondy/widgets/onboarding/onboarding_tooltip.dart';
import 'package:bondy/widgets/onboarding/showcase_step.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('does not complete onboarding when no target widget was shown', (
    tester,
  ) async {
    final missingTargetKey = GlobalKey();
    var completed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () {
                  OnboardingOverlay.show(
                    context,
                    steps: [
                      ShowcaseStep(
                        targetKey: missingTargetKey,
                        title: 'Missing target',
                        content: 'This step should not be completed.',
                        icon: '*',
                      ),
                    ],
                    onCompleted: () => completed = true,
                  );
                },
                child: const Text('start'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('start'));
    for (var i = 0; i < 8; i++) {
      await tester.pump();
    }

    expect(find.text('Missing target'), findsNothing);
    expect(completed, isFalse);
  });

  testWidgets('shows tooltip controls for a visible target', (tester) async {
    final targetKey = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return Column(
                children: [
                  const SizedBox(height: 320),
                  SizedBox(
                    key: targetKey,
                    width: 64,
                    height: 64,
                    child: const Placeholder(),
                  ),
                  TextButton(
                    onPressed: () {
                      OnboardingOverlay.show(
                        context,
                        steps: [
                          ShowcaseStep(
                            targetKey: targetKey,
                            title: 'Visible target',
                            content: 'This step should be readable.',
                            icon: '*',
                            position: ShowcasePosition.top,
                          ),
                        ],
                      );
                    },
                    child: const Text('start'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('start'));
    await tester.pump();

    final tooltipFinder = find.byType(OnboardingTooltip);
    expect(tooltipFinder, findsOneWidget);
    expect(find.text('Visible target'), findsOneWidget);
    expect(
      find.descendant(of: tooltipFinder, matching: find.byType(TextButton)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: tooltipFinder, matching: find.byType(ElevatedButton)),
      findsOneWidget,
    );
    expect(tester.getRect(tooltipFinder).top, greaterThanOrEqualTo(0));
    expect(
      tester.getRect(tooltipFinder).bottom,
      lessThanOrEqualTo(tester.view.physicalSize.height),
    );
  });

  testWidgets('keeps tooltip within a constrained overlay host', (
    tester,
  ) async {
    final targetKey = GlobalKey();

    await tester.binding.setSurfaceSize(const Size(900, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: child,
            ),
          );
        },
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return Column(
                children: [
                  const SizedBox(height: 420),
                  SizedBox(
                    key: targetKey,
                    width: 64,
                    height: 64,
                    child: const Placeholder(),
                  ),
                  TextButton(
                    onPressed: () {
                      OnboardingOverlay.show(
                        context,
                        steps: [
                          ShowcaseStep(
                            targetKey: targetKey,
                            title: 'Constrained target',
                            content: 'This step should fit inside the host.',
                            icon: '*',
                            position: ShowcasePosition.top,
                          ),
                        ],
                      );
                    },
                    child: const Text('start'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('start'));
    await tester.pump();

    final tooltipRect = tester.getRect(find.byType(OnboardingTooltip));
    final hostRect = tester.getRect(find.byType(Scaffold));
    expect(tooltipRect.left, greaterThanOrEqualTo(hostRect.left));
    expect(tooltipRect.right, lessThanOrEqualTo(hostRect.right));
  });
}
