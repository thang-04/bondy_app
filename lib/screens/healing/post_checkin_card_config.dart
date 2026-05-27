class PostCheckinCardConfig {
  final String topMessage;
  final String primaryCtaLabel;
  final int maxCardsAboveFold;
  final List<String> _prioritizedCards;

  List<String> get prioritizedCards => _prioritizedCards;

  static const String moodAnxious = 'ANXIOUS';
  static const String moodStressed = 'STRESSED';
  static const String moodSad = 'SAD';
  static const String moodAngry = 'ANGRY';
  static const String moodCalm = 'CALM';
  static const String moodNeutral = 'NEUTRAL';

  static const String cardBreathing = 'BREATHING';
  static const String cardGrounding = 'GROUNDING';
  static const String cardSoothingAudio = 'SOOTHING_AUDIO';

  static const String cardSelfCompassion = 'SELF_COMPASSION_REFLECTION';
  static const String cardJournalPrompt = 'JOURNAL_PROMPT';
  static const String cardRecoveryReading = 'RECOVERY_READING';

  static const String cardPauseProtocol = 'PAUSE_PROTOCOL_90S';
  static const String cardBodyRelease = 'BODY_RELEASE';
  static const String cardBoundaryReflection = 'BOUNDARY_REFLECTION';

  static const String cardMiniHabit = 'MINI_HABIT';
  static const String cardCourseStep = 'COURSE_STEP';
  static const String cardConnectGently = 'CONNECT_GENTLY';

  PostCheckinCardConfig({
    required this.topMessage,
    required this.primaryCtaLabel,
    required this.maxCardsAboveFold,
    required List<String> prioritizedCards,
  }) : _prioritizedCards = List.unmodifiable(prioritizedCards);

  factory PostCheckinCardConfig.fromMood({
    required String mood,
    required int intensity,
  }) {
    final isHighIntensity = intensity >= 7;
    final maxCardsAboveFold = isHighIntensity ? 2 : 3;

    switch (mood) {
      case moodAnxious:
      case moodStressed:
        return PostCheckinCardConfig(
          topMessage: 'Ổn định nhịp thở trước',
          primaryCtaLabel: 'Bắt đầu ổn định',
          maxCardsAboveFold: maxCardsAboveFold,
          prioritizedCards: const [
            cardBreathing,
            cardGrounding,
            cardSoothingAudio,
          ],
        );
      case moodSad:
        return PostCheckinCardConfig(
          topMessage: 'Nhẹ nhàng với bản thân',
          primaryCtaLabel: 'Viết 3 phút',
          maxCardsAboveFold: maxCardsAboveFold,
          prioritizedCards: const [
            cardSelfCompassion,
            cardJournalPrompt,
            cardRecoveryReading,
          ],
        );
      case moodAngry:
        return PostCheckinCardConfig(
          topMessage: 'Xả căng trước khi phản hồi',
          primaryCtaLabel: 'Hạ nhiệt ngay',
          maxCardsAboveFold: maxCardsAboveFold,
          prioritizedCards: const [
            cardPauseProtocol,
            cardBodyRelease,
            cardBoundaryReflection,
          ],
        );
      case moodCalm:
      case moodNeutral:
      default:
        return PostCheckinCardConfig(
          topMessage: 'Giữ đà hồi phục',
          primaryCtaLabel: 'Tiếp tục hành trình',
          maxCardsAboveFold: maxCardsAboveFold,
          prioritizedCards: const [
            cardMiniHabit,
            cardCourseStep,
            cardConnectGently,
          ],
        );
    }
  }
}
