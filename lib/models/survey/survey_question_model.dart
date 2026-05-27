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
    // Tách emoji từ optionLabel nếu dạng: "💑 Đang trong mối quan hệ"
    // Hoặc tạm thời dùng emoji tĩnh nếu không có cách parse
    String label = json['optionLabel'] ?? '';
    String? currentEmoji;
    
    // Logic parse emoji đơn giản (nếu ký tự đầu là emoji)
    if (label.isNotEmpty && label.runes.first > 255) {
      currentEmoji = String.fromCharCode(label.runes.first);
      label = label.substring(currentEmoji.length).trim();
    }

    return SurveyOption(
      id: json['id'] ?? '',
      code: json['optionCode'],
      title: label,
      subtitle: json['description'],
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
    var optionsList = json['options'] as List? ?? [];
    List<SurveyOption> parsedOptions = 
        optionsList.map((o) => SurveyOption.fromJson(o)).toList();

    String qType = json['questionType'] ?? 'CHOICE';

    return SurveyQuestion(
      id: json['id'] ?? '',
      title: json['questionText'] ?? '',
      subtitle: json['description'] ?? '',
      options: parsedOptions,
      isSlider: qType == 'SLIDER' || qType == 'SCALE',
      type: qType,
      isMultipleChoice: json['isMultipleChoice'] ?? false,
      isRequired: json['isRequired'] ?? false,
      minValue: json['minValue'] != null ? (json['minValue'] as num).toDouble() : null,
      maxValue: json['maxValue'] != null ? (json['maxValue'] as num).toDouble() : null,
    );
  }
}

// Giả lập danh sách câu hỏi tĩnh từ API/Database
class MockSurveyData {
  static const List<SurveyQuestion> questions = [
    SurveyQuestion(
      id: 'q1',
      title: 'Tình trạng yêu đương hiện tại của bạn là gì?',
      subtitle: 'Giúp chúng tôi tìm người phù hợp nhất với bạn.',
      options: [
        SurveyOption(id: 'q1_opt1', title: 'Độc thân và sẵn sàng', subtitle: 'Tôi đang tìm kiếm một nửa của mình', emoji: '💚'),
        SurveyOption(id: 'q1_opt2', title: 'Mới chia tay', subtitle: 'Cần thời gian chữa lành', emoji: '💔'),
        SurveyOption(id: 'q1_opt3', title: 'Đang trong mối quan hệ', subtitle: 'Chỉ tìm bạn bè thôi', emoji: '💑'),
        SurveyOption(id: 'q1_opt4', title: 'Chưa chắc chắn', subtitle: 'Để xem sao đã nhé', emoji: '🤔'),
      ],
    ),
    SurveyQuestion(
      id: 'q2',
      title: 'Mối tình gần nhất của bạn\nkết thúc bao lâu rồi?',
      subtitle: 'Để chúng tôi hiểu tiến trình chữa lành của bạn.',
      options: [
        SurveyOption(id: 'q2_opt1', title: 'Dưới 3 tháng', subtitle: 'Vết thương còn khá mới', emoji: '🩹'),
        SurveyOption(id: 'q2_opt2', title: '3 - 6 tháng', subtitle: 'Đang trong giai đoạn phục hồi', emoji: '🌱'),
        SurveyOption(id: 'q2_opt3', title: '6 tháng - 1 năm', subtitle: 'Đã ổn định trở lại', emoji: '🌿'),
        SurveyOption(id: 'q2_opt4', title: 'Hơn 1 năm', subtitle: 'Hoàn toàn sẵn sàng cho khởi đầu mới', emoji: '🌳'),
        SurveyOption(id: 'q2_opt5', title: 'Chưa từng yêu', subtitle: 'Tôi đang tìm kiếm mối tình đầu', emoji: '🤍'),
      ],
    ),
    SurveyQuestion(
      id: 'q3',
      title: 'Bạn đang tìm kiếm\nđiều gì ở Bondy?',
      subtitle: 'Mục tiêu rõ ràng giúp kết nối hiệu quả hơn.',
      options: [
        SurveyOption(id: 'q3_opt1', title: 'Người yêu nghiêm túc', subtitle: 'Muốn xây dựng mối quan hệ lâu dài', emoji: '💍'),
        SurveyOption(id: 'q3_opt2', title: 'Tìm hiểu nhẹ nhàng', subtitle: 'Hẹn hò xem hợp không đã', emoji: '☕'),
        SurveyOption(id: 'q3_opt3', title: 'Bạn bè chia sẻ', subtitle: 'Cần người trò chuyện, thấu hiểu', emoji: '🤝'),
        SurveyOption(id: 'q3_opt4', title: 'Cố vấn tình cảm (Chữa lành)', subtitle: 'Tôi đang gặp khó khăn tâm lý', emoji: '🧘'),
      ],
    ),
    SurveyQuestion(
        id: 'q4',
        title: 'Trạng thái cảm xúc\nhiện tại của bạn?',
        subtitle: 'Bondy sẽ điều chỉnh cách tiếp cận phù hợp.',
        options: [
          SurveyOption(id: 'q4_opt1', title: 'Hạnh phúc, tích cực', subtitle: 'Tôi tràn đầy năng lượng', emoji: '✨'),
          SurveyOption(id: 'q4_opt2', title: 'Bình thường, ổn định', subtitle: 'Mọi thứ đang trôi qua nhẹ nhàng', emoji: '😌'),
          SurveyOption(id: 'q4_opt3', title: 'Hơi cô đơn', subtitle: 'Cần một người để chia sẻ', emoji: '🌧️'),
          SurveyOption(id: 'q4_opt4', title: 'Đang mang tổn thương', subtitle: 'Tôi cần được chữa lành', emoji: '🩹'),
        ]
    ),
    SurveyQuestion(
        id: 'q5',
        title: 'Bạn thường bị thu hút\nbởi người như thế nào?',
        subtitle: 'Có thể chọn nhiều tiêu chí quan trọng nhất.',
        options: [
          SurveyOption(id: 'q5_opt1', title: 'Hài hước, vui vẻ', subtitle: 'Luôn làm tôi cười', emoji: '😄'),
          SurveyOption(id: 'q5_opt2', title: 'Lắng nghe, thấu cảm', subtitle: 'Hiểu được cảm xúc của tôi', emoji: '👂'),
          SurveyOption(id: 'q5_opt3', title: 'Bảo vệ, trưởng thành', subtitle: 'Cho tôi cảm giác an toàn', emoji: '🛡️'),
          SurveyOption(id: 'q5_opt4', title: 'Thông minh, sâu sắc', subtitle: 'Có những cuộc trò chuyện chất lượng', emoji: '🧠'),
        ]
    ),
    SurveyQuestion(
        id: 'q6',
        title: 'Mức độ sẵn sàng bắt đầu\nmột mối quan hệ mới?',
        subtitle: 'Kéo thanh trượt để thể hiện mức độ của bạn.',
        isSlider: true,
    ),
    SurveyQuestion(
        id: 'q7',
        title: 'Kỳ vọng lớn nhất\ncủa bạn khi dùng App?',
        subtitle: 'Bondy tập trung vào giá trị tinh thần.',
        options: [
          SurveyOption(id: 'q7_opt1', title: 'Tìm được "The One"', subtitle: 'Người sẽ đi cùng tôi lâu dài', emoji: '💘'),
          SurveyOption(id: 'q7_opt2', title: 'Được chữa lành tổn thương', subtitle: 'Vượt qua nỗi buồn quá khứ', emoji: '❤️‍🩹'),
          SurveyOption(id: 'q7_opt3', title: 'Mở rộng vòng tròn xã hội', subtitle: 'Có thêm những người bạn chất lượng', emoji: '🌐'),
          SurveyOption(id: 'q7_opt4', title: 'Hiểu rõ bản thân hơn', subtitle: 'Qua các bài test và trò chuyện', emoji: '🔍'),
        ]
    ),
    SurveyQuestion(
        id: 'q8',
        title: 'Phong cách giao tiếp\nưa thích của bạn?',
        subtitle: 'Cách bạn tương tác với mọi người.',
        options: [
          SurveyOption(id: 'q8_opt1', title: 'Chủ động, cởi mở', subtitle: 'Thích bắt chuyện và nắm quyền chủ động', emoji: '🚀'),
          SurveyOption(id: 'q8_opt2', title: 'Từ tốn, thận trọng', subtitle: 'Cần thời gian để mở lòng', emoji: '🐢'),
          SurveyOption(id: 'q8_opt3', title: 'Linh hoạt', subtitle: 'Tùy đối tượng và hoàn cảnh', emoji: '🌊'),
          SurveyOption(id: 'q8_opt4', title: 'Lắng nghe nhiều hơn', subtitle: 'Thích nghe người khác chia sẻ', emoji: '🎧'),
        ]
    ),
    SurveyQuestion(
        id: 'q9',
        title: 'Cách bạn muốn\nBondy kết nối bạn?',
        subtitle: 'Trải nghiệm cá nhân hóa dành riêng cho bạn.',
        options: [
          SurveyOption(id: 'q9_opt1', title: 'Ghép đôi tự động', subtitle: 'Dựa trên thuật toán tương thích cao nhất', emoji: '⚡'),
          SurveyOption(id: 'q9_opt2', title: 'Cùng làm bài Test', subtitle: 'Nói chuyện sau khi thấy hợp kết quả', emoji: '📝'),
          SurveyOption(id: 'q9_opt3', title: 'Qua Chatbot hỗ trợ', subtitle: 'Chatbot dẫn dắt câu chuyện ban đầu', emoji: '🤖'),
          SurveyOption(id: 'q9_opt4', title: 'Để tôi tự tìm kiếm', subtitle: 'Lướt xem hồ sơ thủ công', emoji: '👀'),
        ]
    ),
  ];
}
