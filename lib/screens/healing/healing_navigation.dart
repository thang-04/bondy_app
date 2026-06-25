import 'package:flutter/material.dart';

import '../../models/healing/healing_models.dart';
import '../../services/healing/healing_service.dart';

const healingHomeRoute = '/home/healing';
const healingArticleDetailRoute = '/healing/article-detail';
const healingExerciseDetailRoute = '/healing/exercise-detail';
const healingCourseDetailRoute = '/healing/course-detail';
const healingPlanRoute = '/healing/plan';
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

  // RITUAL không còn màn riêng — phân giải về màn Đọc/Audio chuẩn (Redesign §5.6).
  if (item.type.toUpperCase() == 'RITUAL') {
    openRitualContent(context, item.id);
    return;
  }

  Navigator.of(
    context,
  ).pushNamed(routeForHealingContent(item), arguments: item.id);
}

/// Mở nội dung RITUAL bằng **màn chuẩn**: phân giải ritual → audio (Màn Audio)
/// nếu có `audioContentId`, ngược lại → bài đọc (Màn Đọc) qua `readingContentId`.
/// Trả về kết quả pop (`true` = đã hoàn thành) để caller cập nhật tiến trình lộ
/// trình. Thay cho 2 màn `ritual_*_detail` trùng lặp đã bị gỡ. (Redesign §5.6)
Future<bool?> openRitualContent(
  BuildContext context,
  String ritualId, {
  bool planMode = false,
  HealingDataSource? service,
}) async {
  if (ritualId.isEmpty) return null;
  final svc = service ?? HealingService();
  HealingRitual? ritual;
  try {
    ritual = await svc.fetchRitual(ritualId);
  } catch (_) {
    ritual = null;
  }
  if (!context.mounted) return null;

  final audioId = ritual?.audioContentId;
  if (audioId != null && audioId.isNotEmpty) {
    return Navigator.of(context).pushNamed<bool>(
      healingAudioPlayerRoute,
      arguments: {'audioId': audioId, 'planMode': planMode},
    );
  }

  final readingId = ritual?.readingContentId;
  final articleId = (readingId != null && readingId.isNotEmpty)
      ? readingId
      : ritualId;
  return Navigator.of(
    context,
  ).pushNamed<bool>(healingArticleDetailRoute, arguments: articleId);
}
