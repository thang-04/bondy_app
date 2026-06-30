import '../services/ai_service.dart';

class AiSkillDescriptor {
  final String key;
  final String label;
  final String description;

  const AiSkillDescriptor({
    required this.key,
    required this.label,
    required this.description,
  });
}

class AiModeDescriptor {
  final AiChatMode mode;
  final String title;
  final String subtitle;
  final String routeName;
  final String emoji;
  final List<AiSkillDescriptor> skills;
  final Map<String, Object?> routeArguments;

  const AiModeDescriptor({
    required this.mode,
    required this.title,
    required this.subtitle,
    required this.routeName,
    required this.emoji,
    this.skills = const [],
    this.routeArguments = const {},
  });
}

class AiModeCatalog {
  static const datingAdvice = AiSkillDescriptor(
    key: 'dating-advice',
    label: 'Dating advice',
    description: 'Gợi ý mở lời và duy trì trò chuyện.',
  );

  static const profileAnalysis = AiSkillDescriptor(
    key: 'profile-analysis',
    label: 'Profile analysis',
    description: 'Phân tích hồ sơ để cá nhân hóa lời khuyên.',
  );

  static const griefStages = AiSkillDescriptor(
    key: 'grief-stages',
    label: 'Healing stages',
    description: 'Đồng hành cảm xúc và chữa lành nhẹ nhàng.',
  );

  static const zodiac = AiSkillDescriptor(
    key: 'cung-hoang-dao',
    label: 'Cung hoàng đạo',
    description: 'Tra cứu con giáp và cung hoàng đạo.',
  );

  static const compatibility = AiSkillDescriptor(
    key: 'tuong-hop',
    label: 'Tương hợp',
    description: 'Xem xu hướng hợp nhau trong tình yêu.',
  );

  static const datePicking = AiSkillDescriptor(
    key: 'xem-ngay',
    label: 'Xem ngày',
    description: 'Gợi ý ngày tốt cho các kế hoạch.',
  );

  static const natalChart = AiSkillDescriptor(
    key: 'la-so',
    label: 'Lá số',
    description: 'Bình giải lá số khi có ngày giờ sinh.',
  );

  static const tarotSkill = AiSkillDescriptor(
    key: 'tarot',
    label: 'Tarot',
    description: 'Giải nghĩa trải bài tình yêu.',
  );

  static const modes = <AiModeDescriptor>[
    AiModeDescriptor(
      mode: AiChatMode.defaultMode,
      title: 'Hỏi Bondy',
      subtitle: 'Trợ lý AI chung',
      routeName: '/bondy-ai',
      emoji: '🤖',
      routeArguments: {'mode': 'default'},
    ),
    AiModeDescriptor(
      mode: AiChatMode.healing,
      title: 'Chữa lành',
      subtitle: 'Lắng nghe cảm xúc',
      routeName: '/chatbot',
      emoji: '🌿',
      skills: [griefStages],
    ),
    AiModeDescriptor(
      mode: AiChatMode.coach,
      title: 'Love Coach',
      subtitle: 'Gợi ý hẹn hò',
      routeName: '/bondy-ai',
      emoji: '💕',
      skills: [datingAdvice, profileAnalysis],
      routeArguments: {'mode': 'coach'},
    ),
    AiModeDescriptor(
      mode: AiChatMode.plan,
      title: 'Lên kế hoạch',
      subtitle: 'Biến ý tưởng thành bước làm',
      routeName: '/bondy-ai',
      emoji: '🗓️',
      routeArguments: {'mode': 'plan'},
    ),
    AiModeDescriptor(
      mode: AiChatMode.aiTuVi,
      title: 'Tử vi tình yêu',
      subtitle: 'Cung, tuổi và tương hợp',
      routeName: '/zodiac-ai',
      emoji: '🔮',
      skills: [zodiac, compatibility, datePicking, natalChart],
    ),
    AiModeDescriptor(
      mode: AiChatMode.tarot,
      title: 'Tarot',
      subtitle: 'Rút bài và giải nghĩa',
      routeName: '/tarot-reading',
      emoji: '🃏',
      skills: [tarotSkill],
    ),
  ];

  static AiModeDescriptor byMode(AiChatMode mode) {
    return modes.firstWhere(
      (descriptor) => descriptor.mode == mode,
      orElse: () => modes.first,
    );
  }
}
