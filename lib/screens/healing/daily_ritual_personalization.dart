enum PostCheckinAction {
  stabilize,
  exercise,
  journal,
  continuePlan,
  browseContent,
}

class DailyRitualModel {
  final PostCheckinAction action;
  final String heroTitle;
  final String ctaLabel;
  final String firstItemTitle;
  final String secondItemTitle;
  final String firstItemSubtitle;
  final String secondItemSubtitle;

  const DailyRitualModel({
    required this.action,
    required this.heroTitle,
    required this.ctaLabel,
    required this.firstItemTitle,
    required this.secondItemTitle,
    required this.firstItemSubtitle,
    required this.secondItemSubtitle,
  });
}

class HealingDailyArgs {
  final String mood;
  final int intensity;

  const HealingDailyArgs({required this.mood, required this.intensity});
}

const String stabilizeQuickActionsRoute = '/healing/stabilize-quick-actions';
const String reflectionRoute = '/healing/reflection-complete';
const String continueJourneyRoute = '/healing/daily';

DailyRitualModel buildDailyRitualModel({
  required String mood,
  required int intensity,
}) {
  if (intensity >= 7) {
    return const DailyRitualModel(
      action: PostCheckinAction.stabilize,
      heroTitle: 'Mình tạm ổn định trước nhé',
      ctaLabel: 'Ổn định ngay',
      firstItemTitle: 'Thở hộp 2 phút',
      firstItemSubtitle: 'Giảm nhịp tim và đưa chú ý về hiện tại',
      secondItemTitle: 'Thả lỏng cơ thể 3 phút',
      secondItemSubtitle: 'Xả căng ở vai, hàm và bàn tay',
    );
  }

  if (intensity >= 4) {
    return const DailyRitualModel(
      action: PostCheckinAction.exercise,
      heroTitle: 'Dành vài phút cho bản thân',
      ctaLabel: 'Bắt đầu bài tập',
      firstItemTitle: 'Thở sâu 5 phút',
      firstItemSubtitle: 'Ổn định tâm trí trước khi phản hồi',
      secondItemTitle: 'Reflection có hướng dẫn',
      secondItemSubtitle: 'Ghi lại điều mình đang cần hôm nay',
    );
  }

  final normalizedMood = mood.toUpperCase();
  if (normalizedMood == 'OK' || normalizedMood == 'CALM') {
    return const DailyRitualModel(
      action: PostCheckinAction.continuePlan,
      heroTitle: 'Giữ nhịp ổn định',
      ctaLabel: 'Tiếp tục nhẹ nhàng',
      firstItemTitle: 'Nhật ký biết ơn 3 phút',
      firstItemSubtitle: 'Neo lại những điều đang nâng đỡ bạn',
      secondItemTitle: 'Bài đọc phát triển nhẹ',
      secondItemSubtitle: 'Một góc nhìn nhỏ để đi tiếp chậm rãi',
    );
  }

  return const DailyRitualModel(
    action: PostCheckinAction.journal,
    heroTitle: 'Giữ nhịp ổn định',
    ctaLabel: 'Tiếp tục nhẹ nhàng',
    firstItemTitle: 'Thở sâu 3 phút',
    firstItemSubtitle: 'Làm dịu hệ thần kinh trước',
    secondItemTitle: 'Viết lại cảm xúc hiện tại',
    secondItemSubtitle: 'Gọi tên cảm xúc để nó bớt mơ hồ',
  );
}

String resolveRoute(PostCheckinAction action) => switch (action) {
  PostCheckinAction.stabilize => stabilizeQuickActionsRoute,
  PostCheckinAction.exercise => '/healing/exercise-detail',
  PostCheckinAction.journal => '/chatbot',
  PostCheckinAction.continuePlan => '/healing/plan',
  PostCheckinAction.browseContent => '/content',
};

PostCheckinAction resolveActionForMood({
  required String mood,
  required int intensity,
}) {
  return buildDailyRitualModel(mood: mood, intensity: intensity).action;
}
