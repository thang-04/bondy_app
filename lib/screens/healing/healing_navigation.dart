import 'package:flutter/material.dart';

import '../../models/healing/healing_models.dart';

const healingHomeRoute = '/home/healing';
const healingArticleDetailRoute = '/healing/article-detail';
const healingExerciseDetailRoute = '/healing/exercise-detail';
const healingCourseDetailRoute = '/healing/course-detail';
const healingPlanRoute = '/healing/plan';
const healingDailyRoute = '/healing/daily';
const healingReflectionCompleteRoute = '/healing/reflection-complete';
const healingAudioPlayerRoute = '/healing/audio-player';

String routeForHealingContent(HealingContentPreview item) {
  return switch (item.type.toUpperCase()) {
    'ARTICLE' => healingArticleDetailRoute,
    'EXERCISE' => healingExerciseDetailRoute,
    'COURSE' => healingCourseDetailRoute,
    'AUDIO' => healingAudioPlayerRoute,
    _ => healingArticleDetailRoute,
  };
}

void openHealingContent(
  BuildContext context,
  HealingContentPreview? item, {
  String fallbackRoute = healingArticleDetailRoute,
}) {
  if (item == null || item.id.isEmpty) {
    Navigator.of(context).pushNamed(fallbackRoute);
    return;
  }

  Navigator.of(context).pushNamed(routeForHealingContent(item), arguments: item.id);
}
