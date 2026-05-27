import 'package:flutter/material.dart';
import '../healing_stitch_style.dart';

class EmotionalCheckinDialog extends StatefulWidget {
  final Future<void> Function(String mood, int intensity, String note) onSubmit;

  const EmotionalCheckinDialog({super.key, required this.onSubmit});

  @override
  State<EmotionalCheckinDialog> createState() => _EmotionalCheckinDialogState();
}

class _EmotionalCheckinDialogState extends State<EmotionalCheckinDialog> {
  String? _selectedMood;
  int _selectedIntensity = 5;
  final TextEditingController _noteController = TextEditingController();
  bool _isSubmitting = false;

  final List<Map<String, dynamic>> _moods = [
    {'emoji': '😊', 'label': 'Vui vẻ', 'mood': 'HAPPY', 'intensity': 2},
    {'emoji': '😌', 'label': 'Bình yên', 'mood': 'CALM', 'intensity': 3},
    {'emoji': '😔', 'label': 'Buồn', 'mood': 'SAD', 'intensity': 6},
    {'emoji': '😫', 'label': 'Căng thẳng', 'mood': 'STRESSED', 'intensity': 7},
  ];

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_selectedMood == null) return;
    
    setState(() {
      _isSubmitting = true;
    });

    try {
      await widget.onSubmit(
        _selectedMood!,
        _selectedIntensity,
        _noteController.text.trim(),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: HealingStitchColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: HealingStitchColors.border),
          boxShadow: [healingSoftShadow(0.08)],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Decorative Header Element
              Container(
                height: 8,
                decoration: const BoxDecoration(
                  gradient: HealingStitchColors.brandGradient,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  // Close Button Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: HealingStitchColors.contentBackground,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 20,
                            color: HealingStitchColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  // Text Content
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: HealingStitchColors.paleCoral,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite,
                      color: HealingStitchColors.pink,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Hôm nay bạn cảm thấy thế nào?',
                    textAlign: TextAlign.center,
                    style: healingText(size: 20, weight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Take a moment to check in with yourself.',
                    textAlign: TextAlign.center,
                    style: healingText(
                      size: 14,
                      color: HealingStitchColors.textSoft,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Mood Selection Grid
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: _moods.map((m) {
                      final isSelected = _selectedMood == m['mood'];
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedMood = m['mood'];
                            _selectedIntensity = m['intensity'];
                          });
                        },
                        child: Column(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: isSelected 
                                    ? HealingStitchColors.paleCoral 
                                    : HealingStitchColors.contentBackground,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected 
                                      ? HealingStitchColors.pink.withValues(alpha: 0.3)
                                      : Colors.transparent,
                                  width: 2,
                                ),
                                boxShadow: isSelected 
                                    ? [healingSoftShadow(0.05)]
                                    : [],
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                m['emoji'],
                                style: const TextStyle(fontSize: 28),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              m['label'],
                              style: healingText(
                                size: 12,
                                weight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                color: isSelected 
                                    ? HealingStitchColors.textMain 
                                    : HealingStitchColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Text Area
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Want to share more? (Optional)',
                        style: healingText(
                          size: 12,
                          weight: FontWeight.w700,
                          color: HealingStitchColors.textSoft,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: HealingStitchColors.contentBackground,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          controller: _noteController,
                          maxLines: 3,
                          style: healingText(size: 14),
                          decoration: InputDecoration(
                            hintText: "I'm feeling...",
                            hintStyle: healingText(
                              size: 14,
                              color: HealingStitchColors.textMuted.withValues(alpha: 0.5),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.all(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Call to Action
                  Opacity(
                    opacity: _selectedMood == null ? 0.5 : 1.0,
                    child: IgnorePointer(
                      ignoring: _selectedMood == null || _isSubmitting,
                      child: HealingGradientButton(
                        label: _isSubmitting ? 'Đang lưu...' : 'Lưu Check-in',
                        icon: Icons.check,
                        onTap: _handleSubmit,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  Text(
                    'Your check-ins are private and secure.',
                    style: healingText(
                      size: 11,
                      color: HealingStitchColors.textMuted.withValues(alpha: 0.7),
                    ),
                  ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
