import 'package:bondy/screens/discover/discover_matching_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps physical swipe directions to Tinder actions', () {
    expect(discoverSwipeActionForDirection(AxisDirection.left), 'PASS');
    expect(discoverSwipeActionForDirection(AxisDirection.right), 'LIKE');
    expect(discoverSwipeActionForDirection(AxisDirection.up), 'SUPER_LIKE');
    expect(discoverSwipeActionForDirection(AxisDirection.down), 'PASS');
  });

  test('does not auto-start the discover swipe tutorial', () {
    expect(discoverSwipeTutorialAutoStartEnabled, isFalse);
  });
}
