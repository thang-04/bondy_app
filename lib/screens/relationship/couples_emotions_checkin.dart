import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../healing/healing_stitch_style.dart';
import '../../viewmodels/relationship/relationship_viewmodel.dart';
import '../../widgets/common/bondy_feedback.dart';

class CouplesEmotionsCheckin extends StatefulWidget {
  const CouplesEmotionsCheckin({super.key});

  @override
  State<CouplesEmotionsCheckin> createState() => _CouplesEmotionsCheckinState();
}

class _CouplesEmotionsCheckinState extends State<CouplesEmotionsCheckin> {
  String? _selectedEmoji;
  final TextEditingController _noteController = TextEditingController();
  late final RelationshipViewModel _viewModel;
  bool _submitting = false;

  final List<Map<String, String>> _emotions = [
    {'emoji': '😊', 'label': 'Hạnh phúc', 'bg': '0xFFFFF5F5'},
    {'emoji': '😐', 'label': 'Bình thường', 'bg': '0xFFF7F7F7'},
    {'emoji': '😢', 'label': 'Buồn', 'bg': '0xFFF0F7FF'},
    {'emoji': '😰', 'label': 'Áp lực', 'bg': '0xFFFFF0F0'},
  ];

  @override
  void initState() {
    super.initState();
    _viewModel = context.read<RelationshipViewModel>();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Widget _buildProgressBar() {
    return Container(
      width: 64,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(2),
      ),
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: 0.33,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF6B6B), Color(0xFFE056FD)],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Widget _buildSmartCoachCard() {
    final showCoach = _selectedEmoji == '😢' || _selectedEmoji == '😰';
    if (!showCoach) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF6B6B), Color(0xFFE056FD)],
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.all(1),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(23),
          ),
          padding: const EdgeInsets.all(20),
          child: Stack(
            children: [
              const Positioned(
                right: -20,
                top: -20,
                child: Opacity(
                  opacity: 0.05,
                  child: Icon(Icons.spa, size: 120, color: Color(0xFFE056FD)),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFFF6B6B), Color(0xFFE056FD)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.smart_toy_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bondy Coach',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFE056FD),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Thấy bạn đang ${_selectedEmoji == '😰' ? 'áp lực' : 'buồn'}, Bondy gợi ý một lời hỏi thăm nhẹ nhàng để bạn gửi đi.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: HealingStitchColors.textMain,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: () {
                            Navigator.of(context).pushNamed('/chatbot');
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade100),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.lightbulb_outline,
                                  color: Color(0xFFE056FD),
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Xem gợi ý',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: HealingStitchColors.textMain,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
        title: Column(
          children: [
            Text(
              'Check-in cảm xúc',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: HealingStitchColors.textMuted,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            _buildProgressBar(),
          ],
        ),
        centerTitle: true,
        actions: const [SizedBox(width: 48)],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Hôm nay bạn\ncảm thấy thế nào?',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: HealingStitchColors.textMain,
                        height: 1.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Lắng nghe bản thân và chia sẻ nhé',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: HealingStitchColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Lưới cảm xúc 2x2
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 1.15,
                        ),
                    itemCount: _emotions.length,
                    itemBuilder: (context, index) {
                      final emotion = _emotions[index];
                      final isSelected = _selectedEmoji == emotion['emoji'];
                      final colorHex = int.parse(emotion['bg']!);
                      final tileColor = Color(colorHex);

                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedEmoji = emotion['emoji']),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : tileColor,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.05,
                                      ),
                                      blurRadius: 20,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : [],
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFFF6B6B)
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Stack(
                            children: [
                              if (isSelected)
                                const Positioned(
                                  top: 12,
                                  right: 12,
                                  child: Icon(
                                    Icons.check_circle,
                                    color: Color(0xFFFF6B6B),
                                    size: 20,
                                  ),
                                ),
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      emotion['emoji']!,
                                      style: const TextStyle(fontSize: 36),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      emotion['label']!,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: HealingStitchColors.textMain,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  // Smart Coach Suggestions Card
                  _buildSmartCoachCard(),

                  const SizedBox(height: 32),
                  Text(
                    'Ghi chú thêm',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: HealingStitchColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Stack(
                    children: [
                      TextField(
                        controller: _noteController,
                        maxLines: 3,
                        style: GoogleFonts.plusJakartaSans(fontSize: 14),
                        decoration: InputDecoration(
                          hintText:
                              'Có chuyện gì cụ thể đang làm bạn bận tâm không?...',
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
                            borderSide: const BorderSide(
                              color: Color(0xFFFF9A9E),
                            ),
                          ),
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: Icon(
                          Icons.edit_note,
                          color: Colors.grey.shade400,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            child: Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: _selectedEmoji == null || _submitting
                    ? null
                    : const LinearGradient(
                        colors: [Color(0xFFFF6B6B), Color(0xFFE056FD)],
                      ),
                color: _selectedEmoji == null || _submitting
                    ? Colors.grey.shade300
                    : null,
                borderRadius: BorderRadius.circular(20),
                boxShadow: _selectedEmoji == null || _submitting
                    ? []
                    : [
                        BoxShadow(
                          color: const Color(
                            0xFFE056FD,
                          ).withValues(alpha: 0.25),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
              ),
              child: ElevatedButton(
                onPressed: _selectedEmoji == null || _submitting
                    ? null
                    : () async {
                        setState(() => _submitting = true);
                        try {
                          final mood =
                              '${_selectedEmoji!} ${_emotions.firstWhere((e) => e['emoji'] == _selectedEmoji)['label']}';
                          await _viewModel.submitCheckin(
                            mood,
                            note: _noteController.text.trim(),
                          );
                          if (!context.mounted) return;
                          Navigator.pushNamed(
                            context,
                            '/relationship/confirmed',
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          BondyFeedback.showError(context, e);
                        } finally {
                          if (mounted) setState(() => _submitting = false);
                        }
                      },
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
                      _submitting ? 'Đang gửi...' : 'Chia sẻ với người ấy',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
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
          ),
        ],
      ),
    );
  }
}
