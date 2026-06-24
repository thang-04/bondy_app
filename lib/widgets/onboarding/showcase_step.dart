import 'package:flutter/material.dart';

enum ShowcasePosition { top, bottom }

class ShowcaseStep {
  final GlobalKey targetKey;
  final String title;
  final String content;
  final String icon;
  final ShowcasePosition position;

  ShowcaseStep({
    required this.targetKey,
    required this.title,
    required this.content,
    required this.icon,
    this.position = ShowcasePosition.top,
  });
}
