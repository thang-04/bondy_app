import 'package:flutter/material.dart';

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
  final RelationshipViewModel _viewModel = RelationshipViewModel();
  bool _submitting = false;

  @override
  void dispose() {
    _noteController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  final List<Map<String, String>> _emotions = [
    {'emoji': '😊', 'label': 'Hạnh phúc'},
    {'emoji': '😌', 'label': 'Bình yên'},
    {'emoji': '🥰', 'label': 'Yêu thương'},
    {'emoji': '🤩', 'label': 'Hào hứng'},
    {'emoji': '😕', 'label': 'Bối rối'},
    {'emoji': '😢', 'label': 'Buồn bã'},
    {'emoji': '😤', 'label': 'Căng thẳng'},
    {'emoji': '😰', 'label': 'Lo lắng'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HealingStitchColors.warmBackground,
      appBar: AppBar(
        backgroundColor: HealingStitchColors.warmBackground,
        elevation: 0,
        leading: HealingIconButton(
          icon: Icons.close,
          onTap: () => Navigator.pop(context),
        ),
        title: Text(
          'Check-in cảm xúc',
          style: healingText(size: 16, weight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hiện tại bạn đang cảm thấy như thế nào?',
                    style: healingText(size: 22, weight: FontWeight.w800, height: 1.3),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Cùng chia sẻ với đối phương để thấu hiểu nhau hơn nhé.',
                    style: healingText(size: 15, color: HealingStitchColors.textMuted),
                  ),
                  const SizedBox(height: 32),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.9,
                    ),
                    itemCount: _emotions.length,
                    itemBuilder: (context, index) {
                      final emotion = _emotions[index];
                      final isSelected = _selectedEmoji == emotion['emoji'];
                      return GestureDetector(
                        onTap: () => setState(() => _selectedEmoji = emotion['emoji']),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFFFE5E5) : const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? const Color(0xFFFF5252) : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                emotion['emoji']!,
                                style: const TextStyle(fontSize: 32),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                emotion['label']!,
                                style: healingText(
                                  size: 12,
                                  weight: FontWeight.w600,
                                  color: isSelected
                                      ? HealingStitchColors.coral
                                      : HealingStitchColors.textMain,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Để lại lời nhắn (tùy chọn)',
                    style: healingText(size: 16, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _noteController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Hôm nay tớ thấy...',
                      filled: true,
                      fillColor: HealingStitchColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: _selectedEmoji == null || _submitting
                    ? null
                    : HealingStitchColors.warmGradient,
                color: _selectedEmoji == null || _submitting
                    ? HealingStitchColors.border
                    : null,
                borderRadius: BorderRadius.circular(16),
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
                          Navigator.pushNamed(context, '/relationship/confirmed');
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
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  _submitting ? 'Đang gửi...' : 'Chia sẻ cảm xúc',
                  style: healingText(
                    weight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
