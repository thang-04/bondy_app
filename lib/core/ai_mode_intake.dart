import '../services/ai_service.dart';

enum AiIntakeFieldType { text, multiline, choice }

class AiIntakeOption {
  final String value;
  final String label;

  const AiIntakeOption({required this.value, required this.label});
}

class AiIntakeField {
  final String key;
  final String label;
  final String hint;
  final AiIntakeFieldType type;
  final bool required;
  final List<AiIntakeOption> options;

  const AiIntakeField({
    required this.key,
    required this.label,
    required this.hint,
    this.type = AiIntakeFieldType.text,
    this.required = false,
    this.options = const [],
  });
}

class AiModeIntakeConfig {
  final AiChatMode mode;
  final String title;
  final String subtitle;
  final String submitLabel;
  final List<AiIntakeField> fields;

  const AiModeIntakeConfig({
    required this.mode,
    required this.title,
    required this.subtitle,
    required this.submitLabel,
    required this.fields,
  });

  static bool requiresIntake(AiChatMode mode) => mode != AiChatMode.defaultMode;

  static AiModeIntakeConfig byMode(AiChatMode mode) {
    switch (mode) {
      case AiChatMode.aiTuVi:
        return zodiac;
      case AiChatMode.tarot:
        return tarot;
      case AiChatMode.healing:
        return healing;
      case AiChatMode.coach:
        return coach;
      case AiChatMode.plan:
        return plan;
      case AiChatMode.defaultMode:
        return defaultMode;
    }
  }

  static const defaultMode = AiModeIntakeConfig(
    mode: AiChatMode.defaultMode,
    title: 'Hỏi Bondy',
    subtitle: 'Vào chat ngay với trợ lý AI chung.',
    submitLabel: 'Bắt đầu chat',
    fields: [],
  );

  static const zodiac = AiModeIntakeConfig(
    mode: AiChatMode.aiTuVi,
    title: 'Tử vi tình yêu',
    subtitle: 'Nhập thông tin nền để AI xem đúng câu hỏi hơn.',
    submitLabel: 'Bắt đầu xem',
    fields: [
      AiIntakeField(
        key: 'intent',
        label: 'Bạn muốn xem gì?',
        hint: 'Chọn một chủ đề',
        type: AiIntakeFieldType.choice,
        required: true,
        options: [
          AiIntakeOption(value: 'compatibility', label: 'Độ hợp nhau'),
          AiIntakeOption(value: 'daily-love', label: 'Tình duyên hôm nay'),
          AiIntakeOption(value: 'date-picking', label: 'Ngày tốt hẹn hò'),
          AiIntakeOption(value: 'natal-love', label: 'Lá số tình yêu'),
        ],
      ),
      AiIntakeField(
        key: 'birthDate',
        label: 'Ngày sinh của bạn',
        hint: 'VD: 1995-05-12',
        required: true,
      ),
      AiIntakeField(
        key: 'birthTime',
        label: 'Giờ sinh',
        hint: 'VD: 08:30, có thể bỏ trống',
      ),
      AiIntakeField(
        key: 'relationshipStatus',
        label: 'Tình trạng hiện tại',
        hint: 'VD: đang tìm hiểu, đang yêu, mới chia tay...',
      ),
      AiIntakeField(
        key: 'partnerBirthInfo',
        label: 'Thông tin người kia',
        hint: 'Ngày sinh, tuổi hoặc con giáp nếu có',
      ),
      AiIntakeField(
        key: 'question',
        label: 'Câu hỏi cụ thể',
        hint: 'VD: Chúng mình có hợp nhau không?',
        type: AiIntakeFieldType.multiline,
        required: true,
      ),
    ],
  );

  static const tarot = AiModeIntakeConfig(
    mode: AiChatMode.tarot,
    title: 'Tarot tình yêu',
    subtitle: 'Đặt câu hỏi trước khi rút bài để trải bài có ngữ cảnh.',
    submitLabel: 'Rút bài',
    fields: [
      AiIntakeField(
        key: 'spread',
        label: 'Kiểu trải bài',
        hint: 'Chọn cách rút bài',
        type: AiIntakeFieldType.choice,
        required: true,
        options: [
          AiIntakeOption(value: 'one-card', label: '1 lá nhanh'),
          AiIntakeOption(value: 'three-card-love', label: '3 lá tình yêu'),
          AiIntakeOption(value: 'choice', label: 'Giữa hai lựa chọn'),
        ],
      ),
      AiIntakeField(
        key: 'relationshipStatus',
        label: 'Tình trạng hiện tại',
        hint: 'VD: đang độc thân, đang tìm hiểu, đang yêu...',
      ),
      AiIntakeField(
        key: 'question',
        label: 'Câu hỏi cho trải bài',
        hint: 'VD: Mình nên tiếp tục mối quan hệ này không?',
        type: AiIntakeFieldType.multiline,
        required: true,
      ),
    ],
  );

  static const healing = AiModeIntakeConfig(
    mode: AiChatMode.healing,
    title: 'Chữa lành',
    subtitle: 'Cho Bondy biết cảm xúc hiện tại trước khi tâm sự.',
    submitLabel: 'Bắt đầu tâm sự',
    fields: [
      AiIntakeField(
        key: 'mood',
        label: 'Hôm nay bạn thấy thế nào?',
        hint: 'Chọn cảm xúc gần nhất',
        type: AiIntakeFieldType.choice,
        required: true,
        options: [
          AiIntakeOption(value: 'sad', label: 'Buồn'),
          AiIntakeOption(value: 'anxious', label: 'Lo lắng'),
          AiIntakeOption(value: 'angry', label: 'Tức giận'),
          AiIntakeOption(value: 'empty', label: 'Trống rỗng'),
        ],
      ),
      AiIntakeField(
        key: 'need',
        label: 'Bạn cần điều gì?',
        hint: 'Chọn cách Bondy nên hỗ trợ',
        type: AiIntakeFieldType.choice,
        required: true,
        options: [
          AiIntakeOption(value: 'listen', label: 'Lắng nghe'),
          AiIntakeOption(value: 'calm', label: 'Giúp bình tĩnh'),
          AiIntakeOption(value: 'journal', label: 'Viết nhật ký'),
          AiIntakeOption(value: 'gentle-advice', label: 'Lời khuyên nhẹ'),
        ],
      ),
      AiIntakeField(
        key: 'context',
        label: 'Chuyện đang làm bạn nặng lòng',
        hint: 'Kể ngắn gọn điều đang xảy ra',
        type: AiIntakeFieldType.multiline,
        required: true,
      ),
    ],
  );

  static const coach = AiModeIntakeConfig(
    mode: AiChatMode.coach,
    title: 'Love Coach',
    subtitle: 'Nhập mục tiêu và ngữ cảnh để gợi ý đúng hơn.',
    submitLabel: 'Nhận gợi ý',
    fields: [
      AiIntakeField(
        key: 'goal',
        label: 'Mục tiêu của bạn',
        hint: 'Chọn điều bạn cần',
        type: AiIntakeFieldType.choice,
        required: true,
        options: [
          AiIntakeOption(value: 'opener', label: 'Mở lời'),
          AiIntakeOption(value: 'continue-chat', label: 'Tiếp tục chat'),
          AiIntakeOption(value: 'handle-silence', label: 'Xử lý im lặng'),
          AiIntakeOption(value: 'ask-date', label: 'Hẹn gặp'),
        ],
      ),
      AiIntakeField(
        key: 'tone',
        label: 'Tone mong muốn',
        hint: 'VD: vui vẻ, tinh tế, thẳng thắn...',
      ),
      AiIntakeField(
        key: 'context',
        label: 'Ngữ cảnh/Đoạn chat',
        hint: 'Dán đoạn chat hoặc mô tả match nếu có',
        type: AiIntakeFieldType.multiline,
      ),
    ],
  );

  static const plan = AiModeIntakeConfig(
    mode: AiChatMode.plan,
    title: 'Lên kế hoạch',
    subtitle: 'Nhập mục tiêu để AI chia thành bước có thể làm.',
    submitLabel: 'Tạo kế hoạch',
    fields: [
      AiIntakeField(
        key: 'goal',
        label: 'Mục tiêu',
        hint: 'VD: lên lịch hẹn cuối tuần',
        type: AiIntakeFieldType.multiline,
        required: true,
      ),
      AiIntakeField(
        key: 'timeframe',
        label: 'Thời hạn',
        hint: 'VD: trong 2 ngày, cuối tuần này...',
      ),
      AiIntakeField(
        key: 'constraints',
        label: 'Ràng buộc',
        hint: 'VD: ngân sách, địa điểm, thời gian rảnh...',
        type: AiIntakeFieldType.multiline,
      ),
    ],
  );
}

class AiModeIntakeDraft {
  final AiChatMode mode;
  final Map<String, String> values;

  const AiModeIntakeDraft({required this.mode, required this.values});

  String get destinationRoute {
    switch (mode) {
      case AiChatMode.aiTuVi:
        return '/zodiac-ai';
      case AiChatMode.tarot:
        return '/tarot-reading';
      case AiChatMode.healing:
        return '/chatbot';
      case AiChatMode.coach:
      case AiChatMode.plan:
      case AiChatMode.defaultMode:
        return '/bondy-ai';
    }
  }

  String get displayMessage {
    switch (mode) {
      case AiChatMode.aiTuVi:
        return 'Bắt đầu xem tử vi tình yêu';
      case AiChatMode.tarot:
        return 'Bắt đầu trải bài tarot';
      case AiChatMode.healing:
        return 'Bắt đầu tâm sự với Bondy';
      case AiChatMode.coach:
        return 'Cần Love Coach gợi ý';
      case AiChatMode.plan:
        return 'Tạo kế hoạch với Bondy';
      case AiChatMode.defaultMode:
        return _value('question', fallback: 'Hỏi Bondy');
    }
  }

  List<String> get summaryLines {
    final labels = _summaryLabels(mode);
    return labels.entries
        .map((entry) => MapEntry(entry.value, _summaryValue(entry.key)))
        .where((entry) => entry.value.isNotEmpty)
        .map((entry) => '${entry.key}: ${entry.value}')
        .toList();
  }

  String buildInitialMessage() {
    // Với mode tarot, gửi thẳng tin nhắn tiếng Việt tự nhiên
    // để AI backend nhận diện đúng intent mà không bị confuse bởi metadata
    if (mode == AiChatMode.tarot) {
      final lines = _promptLines(mode);
      return lines.where((l) => l.trim().isNotEmpty).join('\n');
    }
    final lines = <String>[
      'Mode: ${mode.apiValue}',
      'User provided intake context before chat.',
      ..._promptLines(mode),
      'Please answer in Vietnamese and use the selected mode behavior.',
    ];
    return lines.where((line) => line.trim().isNotEmpty).join('\n');
  }

  List<String> _promptLines(AiChatMode mode) {
    switch (mode) {
      case AiChatMode.aiTuVi:
        return [
          'Intent: ${_value('intent')}',
          'User birth date: ${_value('birthDate')}',
          'User birth time: ${_value('birthTime', fallback: 'unknown')}',
          'Relationship status: ${_value('relationshipStatus', fallback: 'unknown')}',
          'Partner birth info: ${_value('partnerBirthInfo', fallback: 'unknown')}',
          'Question: ${_value('question')}',
        ];
      case AiChatMode.tarot:
        final spread = _value('spread');
        final spreadLabel = spread == 'one-card'
            ? '1 lá nhanh'
            : spread == 'three-card-love'
                ? '3 lá tình yêu (Quá khứ – Hiện tại – Tương lai)'
                : 'Giữa hai lựa chọn';
        final status = _value('relationshipStatus', fallback: '');
        final question = _value('question');
        final statusLine =
            status.isNotEmpty ? ' Tình trạng hiện tại: $status.' : '';
        return [
          'Tôi muốn xem Tarot.$statusLine Kiểu trải bài: $spreadLabel. Câu hỏi của tôi: $question. Hãy bắt đầu đọc bài Tarot cho tôi theo câu hỏi này.',
        ];
      case AiChatMode.healing:
        return [
          'Mood: ${_value('mood')}',
          'Support need: ${_value('need')}',
          'Context: ${_value('context')}',
        ];
      case AiChatMode.coach:
        return [
          'Goal: ${_value('goal')}',
          'Tone: ${_value('tone', fallback: 'natural')}',
          'Context: ${_value('context', fallback: 'none')}',
        ];
      case AiChatMode.plan:
        return [
          'Goal: ${_value('goal')}',
          'Timeframe: ${_value('timeframe', fallback: 'flexible')}',
          'Constraints: ${_value('constraints', fallback: 'none')}',
        ];
      case AiChatMode.defaultMode:
        return ['Question: ${_value('question')}'];
    }
  }

  String _value(String key, {String fallback = ''}) {
    final value = values[key]?.trim() ?? '';
    return value.isEmpty ? fallback : value;
  }

  String _summaryValue(String key) {
    final rawValue = _value(key);
    if (rawValue.isEmpty) return '';

    final config = AiModeIntakeConfig.byMode(mode);
    for (final field in config.fields) {
      if (field.key != key || field.type != AiIntakeFieldType.choice) continue;
      for (final option in field.options) {
        if (option.value == rawValue) return option.label;
      }
    }
    return rawValue;
  }

  static Map<String, String> _summaryLabels(AiChatMode mode) {
    switch (mode) {
      case AiChatMode.aiTuVi:
        return const {
          'intent': 'Chủ đề',
          'birthDate': 'Ngày sinh',
          'birthTime': 'Giờ sinh',
          'relationshipStatus': 'Tình trạng',
          'partnerBirthInfo': 'Người kia',
          'question': 'Câu hỏi',
        };
      case AiChatMode.tarot:
        return const {
          'spread': 'Kiểu trải bài',
          'relationshipStatus': 'Tình trạng',
          'question': 'Câu hỏi',
        };
      case AiChatMode.healing:
        return const {
          'mood': 'Cảm xúc',
          'need': 'Cần hỗ trợ',
          'context': 'Ngữ cảnh',
        };
      case AiChatMode.coach:
        return const {
          'goal': 'Mục tiêu',
          'tone': 'Tone',
          'context': 'Ngữ cảnh',
        };
      case AiChatMode.plan:
        return const {
          'goal': 'Mục tiêu',
          'timeframe': 'Thời hạn',
          'constraints': 'Ràng buộc',
        };
      case AiChatMode.defaultMode:
        return const {'question': 'Câu hỏi'};
    }
  }
}
