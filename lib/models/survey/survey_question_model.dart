class SurveyOption {
  final String id;
  final String title;
  final String? subtitle;
  final String? emoji;
  final String? code;

  const SurveyOption({
    required this.id,
    required this.title,
    this.subtitle,
    this.emoji,
    this.code,
  });

  factory SurveyOption.fromJson(Map<String, dynamic> json) {
    var label = json['optionLabel']?.toString() ?? '';
    String? currentEmoji;

    if (label.isNotEmpty && label.runes.first > 255) {
      currentEmoji = String.fromCharCode(label.runes.first);
      label = label.substring(currentEmoji.length).trim();
    }

    return SurveyOption(
      id: json['id']?.toString() ?? '',
      code: json['optionCode']?.toString(),
      title: label,
      subtitle: json['description']?.toString(),
      emoji: currentEmoji,
    );
  }
}

class SurveyQuestion {
  final String id;
  final String title;
  final String subtitle;
  final List<SurveyOption> options;
  final bool isSlider;
  final String type;
  final bool isMultipleChoice;
  final bool isRequired;
  final double? minValue;
  final double? maxValue;

  const SurveyQuestion({
    required this.id,
    required this.title,
    required this.subtitle,
    this.options = const [],
    this.isSlider = false,
    this.type = 'CHOICE',
    this.isMultipleChoice = false,
    this.isRequired = false,
    this.minValue,
    this.maxValue,
  });

  factory SurveyQuestion.fromJson(Map<String, dynamic> json) {
    final optionsList = json['options'] as List? ?? const [];
    final parsedOptions = optionsList
        .map(
          (option) =>
              SurveyOption.fromJson((option as Map).cast<String, dynamic>()),
        )
        .toList();
    final questionType = json['questionType']?.toString() ?? 'CHOICE';

    return SurveyQuestion(
      id: json['id']?.toString() ?? '',
      title: json['questionText']?.toString() ?? '',
      subtitle: json['description']?.toString() ?? '',
      options: parsedOptions,
      isSlider: questionType == 'SLIDER' || questionType == 'SCALE',
      type: questionType,
      isMultipleChoice: json['isMultipleChoice'] == true,
      isRequired: json['isRequired'] == true,
      minValue: json['minValue'] != null
          ? (json['minValue'] as num).toDouble()
          : null,
      maxValue: json['maxValue'] != null
          ? (json['maxValue'] as num).toDouble()
          : null,
    );
  }
}
