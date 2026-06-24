import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bondy/widgets/onboarding/showcase_step.dart';

void main() {
  test('ShowcaseStep should initialize with correct values', () {
    final key = GlobalKey();
    final step = ShowcaseStep(
      targetKey: key,
      title: 'Test Title',
      content: 'Test Content',
      icon: '🔥',
      position: ShowcasePosition.bottom,
    );

    expect(step.targetKey, key);
    expect(step.title, 'Test Title');
    expect(step.content, 'Test Content');
    expect(step.icon, '🔥');
    expect(step.position, ShowcasePosition.bottom);
  });
}
