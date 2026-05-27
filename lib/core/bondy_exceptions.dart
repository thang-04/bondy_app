class QuotaExceededException implements Exception {
  final String message;
  const QuotaExceededException([
    this.message =
        'Bạn đã hết lượt like hôm nay. Hãy nâng cấp Premium để tiếp tục.',
  ]);
  @override
  String toString() => message;
}

/// Thrown when the server refuses a swipe because the user has not completed
/// the daily emotional check-in (Healing Gate). The screen should redirect to
/// the healing daily check-in instead of swallowing the error.
///
/// BUG-B01: server now enforces this on /api/swipes (was UI-only before).
class HealingGateRequiredException implements Exception {
  final String message;
  final DateTime? lastCheckinAt;
  const HealingGateRequiredException({
    this.message =
        'Hãy hoàn thành check-in cảm xúc hôm nay trước khi kết nối người mới.',
    this.lastCheckinAt,
  });
  @override
  String toString() => message;
}
