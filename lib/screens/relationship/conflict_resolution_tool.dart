import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../healing/healing_stitch_style.dart';
import '../../services/chat_service.dart';
import '../../services/api_client.dart';
import '../../services/relationship_service.dart';
import '../../widgets/common/bondy_feedback.dart';

class ConflictResolutionTool extends StatefulWidget {
  const ConflictResolutionTool({super.key});

  @override
  State<ConflictResolutionTool> createState() => _ConflictResolutionToolState();
}

class _ConflictResolutionToolState extends State<ConflictResolutionTool> {
  final ApiClient _apiClient = ApiClient();
  late final ChatService _chatService = ChatService(_apiClient);
  final RelationshipService _relationshipService = RelationshipService();

  String? _chatId;
  String? _selectedCategory = 'Giao tiếp';
  double _severity = 6.0;
  final TextEditingController _noteController = TextEditingController();

  bool _submitting = false;
  bool _sent = false;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Giao tiếp', 'icon': Icons.chat_bubble_outline},
    {'name': 'Tài chính', 'icon': Icons.attach_money},
    {'name': 'Việc nhà', 'icon': Icons.home_outlined},
    {'name': 'Gia đình', 'icon': Icons.family_restroom},
    {'name': 'Khác', 'icon': Icons.more_horiz},
  ];

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      _chatId = args['chatId'] as String?;
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    if (_chatId != null) return;
    try {
      final dash = await _relationshipService.getDashboard();
      final partnerId = dash.partnerId;
      if (partnerId == null) return;

      final chats = await _chatService.listChats();
      for (final chat in chats) {
        if (chat.otherUser.id == partnerId) {
          setState(() {
            _chatId = chat.id;
          });
          break;
        }
      }
    } catch (_) {}
  }

  String _getEmoji(double value) {
    if (value <= 3) return '😌'; // Nhẹ nhàng
    if (value <= 7) return '😕'; // Khó chịu
    return '😰'; // Gay gắt
  }

  String _getSeverityLabel(double value) {
    if (value <= 3) return 'Khó chịu nhẹ';
    if (value <= 7) return 'Căng thẳng';
    return 'Gay gắt / Nghiêm trọng';
  }

  Future<void> _submitReport() async {
    final chatId = _chatId;
    if (chatId == null) {
      BondyFeedback.showError(
        context,
        'Không tìm thấy phòng chat của hai bạn để gửi thông tin.',
      );
      return;
    }

    final detail = _noteController.text.trim();
    if (detail.isEmpty) {
      BondyFeedback.showError(context, 'Vui lòng nhập chi tiết vấn đề.');
      return;
    }

    setState(() => _submitting = true);

    final messageContent =
        '💔 [Báo cáo mâu thuẫn]\n'
        '• Vấn đề: $_selectedCategory\n'
        '• Mức độ nghiêm trọng: ${_severity.toInt()}/10 (${_getSeverityLabel(_severity)})\n'
        '• Chi tiết: $detail';

    try {
      await _chatService.sendMessage(chatId, messageContent);
      setState(() {
        _sent = true;
      });
      if (mounted) {
        BondyFeedback.showSuccess(
          context,
          'Đã gửi thông tin mâu thuẫn vào chat.',
        );
      }
    } catch (e) {
      if (mounted) {
        BondyFeedback.showError(
          context,
          e,
          fallback: 'Không gửi được thông tin.',
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HealingStitchColors.creamBackground,
      appBar: AppBar(
        backgroundColor: HealingStitchColors.creamBackground,
        elevation: 0,
        leading: HealingIconButton(
          icon: Icons.arrow_back,
          onTap: () => Navigator.pop(context),
        ),
        title: Text(
          'Giải quyết mâu thuẫn',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: HealingStitchColors.textMain,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner chính
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFFF8C61),
                    Color(0xFFFF6B95),
                    Color(0xFF9F6BFF),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6B95).withValues(alpha: 0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chúng mình đang có vấn đề?',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Đừng lo lắng. Hãy bình tĩnh chia sẻ cảm xúc để cùng nhau giải quyết nhé.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.9),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            if (!_sent) ...[
              // Bước 1: Chọn danh mục
              _buildStepTitle('1', 'Vấn đề nằm ở đâu?'),
              const SizedBox(height: 12),
              SizedBox(
                height: 96,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final isSelected = _selectedCategory == cat['name'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 12, bottom: 8),
                      child: GestureDetector(
                        onTap: () => setState(
                          () => _selectedCategory = cat['name'] as String?,
                        ),
                        child: Container(
                          width: 88,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFFFF2F2)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFFF6B95)
                                  : HealingStitchColors.border,
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: isSelected ? 0.04 : 0.01,
                                ),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                cat['icon'] as IconData,
                                color: isSelected
                                    ? const Color(0xFFFF6B95)
                                    : HealingStitchColors.textMuted,
                                size: 24,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                cat['name'] as String,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: isSelected
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: isSelected
                                      ? const Color(0xFFFF6B95)
                                      : HealingStitchColors.textMain,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Bước 2: Mức độ nghiêm trọng
              _buildStepTitle('2', 'Mức độ nghiêm trọng?'),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: HealingStitchColors.border),
                  boxShadow: [healingSoftShadow(0.03)],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Mức độ',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: HealingStitchColors.textMuted,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              '${_severity.toInt()}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFFFF6B95),
                              ),
                            ),
                            Text(
                              ' / 10',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: HealingStitchColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: const Color(0xFFFF6B95),
                        inactiveTrackColor: Colors.grey.shade100,
                        thumbColor: Colors.white,
                        overlayColor: const Color(
                          0xFFFF6B95,
                        ).withValues(alpha: 0.1),
                        trackHeight: 6,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 12,
                        ),
                      ),
                      child: Slider(
                        value: _severity,
                        min: 1.0,
                        max: 10.0,
                        divisions: 9,
                        onChanged: (val) {
                          setState(() {
                            _severity = val;
                          });
                        },
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Khó chịu nhẹ ${_getEmoji(_severity)}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: HealingStitchColors.textMuted,
                          ),
                        ),
                        Text(
                          'Gay gắt / Nghiêm trọng',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: HealingStitchColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Bước 3: Chi tiết
              _buildStepTitle('3', 'Chi tiết vấn đề'),
              const SizedBox(height: 12),
              TextField(
                controller: _noteController,
                maxLines: 4,
                style: GoogleFonts.plusJakartaSans(fontSize: 14),
                decoration: InputDecoration(
                  hintText:
                      'Hãy kể lại ngắn gọn chuyện gì đã xảy ra... (Mình cảm thấy thế nào?)',
                  hintStyle: GoogleFonts.plusJakartaSans(
                    color: Colors.grey.shade400,
                    fontSize: 13,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: Color(0xFFFF6B95)),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 24),

              // Button Gửi
              Container(
                width: double.infinity,
                height: 54,
                decoration: BoxDecoration(
                  gradient: _submitting
                      ? null
                      : const LinearGradient(
                          colors: [Color(0xFFFF8C61), Color(0xFFFF6B95)],
                        ),
                  color: _submitting ? Colors.grey.shade300 : null,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: _submitting
                      ? []
                      : [
                          BoxShadow(
                            color: const Color(
                              0xFFFF6B95,
                            ).withValues(alpha: 0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                ),
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submitReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _submitting
                            ? 'Đang gửi...'
                            : 'Gửi thông tin cho đối phương',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.send, color: Colors.white, size: 16),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ] else ...[
              // Đã gửi - hiển thị Gợi ý làm dịu căng thẳng
              Center(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFF2F2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        color: Color(0xFFFF6B95),
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Đã chia sẻ thông tin',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: HealingStitchColors.textMain,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Mâu thuẫn của hai bạn đã được lưu vào phòng chat.\nHãy cùng xem các gợi ý gỡ rối bên dưới nhé.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: HealingStitchColors.textMuted,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),
              Text(
                'Gợi ý làm dịu căng thẳng',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: HealingStitchColors.textMain,
                ),
              ),
              const SizedBox(height: 16),

              // Card 1
              _buildSootheCard(
                title: 'Hành động hạ nhiệt',
                description:
                    'Dành 15 phút không gian riêng cho mỗi người để bình tĩnh lại.',
                icon: Icons.self_improvement,
                iconColor: Colors.blue.shade600,
                bgColor: const Color(0xFFF0F7FF),
                onTap: () {},
              ),
              const SizedBox(height: 12),

              // Card 2
              _buildSootheCardWithImage(
                title: 'Ý tưởng buổi hẹn làm lành',
                description: 'Cùng nhau nấu một bữa tối đơn giản tại nhà.',
                imageUrl:
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuCe9_8xPNChB0ziiGL1SV3AjErGmre_Nr-WFLdCKDpx_QSLUVfuRbTDdbNjrJdwNEUVmJyTmMDn_iIU21d-ECoHw9q9l0NRvsjZ0PXSeK7TImcUvjjHkCsH_2KR6A42GhMgJgzPB0jH8GWAslS6U8IP3XRxtNPSpe_i6Ua2UxjdVZRfwEt4kI3wHQOO9yHdyz9vafk1srcIcxRz5BGjHLqGRYHXnIqq1TT0QJemZVii5fNKsVPyYNPMCJrpTcqD9Ow8Vgsta1AM-oV1',
                onTap: () {},
              ),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    'Quay lại Góc mối quan hệ',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: HealingStitchColors.textMain,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStepTitle(String stepNum, String title) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: Color(0xFFFFF2F2),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            stepNum,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: const Color(0xFFFF6B95),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: HealingStitchColors.textMain,
          ),
        ),
      ],
    );
  }

  Widget _buildSootheCard({
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: HealingStitchColors.border),
        boxShadow: [healingSoftShadow(0.03)],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: iconColor, size: 28),
        ),
        title: Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: HealingStitchColors.textMain,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            description,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: HealingStitchColors.textSoft,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        trailing: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSootheCardWithImage({
    required String title,
    required String description,
    required String imageUrl,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: HealingStitchColors.border),
        boxShadow: [healingSoftShadow(0.03)],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
          clipBehavior: Clip.antiAlias,
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const Icon(Icons.restaurant),
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: HealingStitchColors.textMain,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            description,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: HealingStitchColors.textSoft,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        trailing: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.favorite, size: 16, color: Colors.pinkAccent),
        ),
        onTap: onTap,
      ),
    );
  }
}
