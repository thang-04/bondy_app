import 'package:flutter/material.dart';

import '../healing_stitch_style.dart';

/// Check-in cảm xúc dạng **bottom sheet** — chỉ mở khi user chủ động chạm,
/// không bao giờ tự bật. Gói gọn 3 bước trong cùng một sheet (không nhảy màn):
/// chọn cảm xúc → mức độ → ghi chú tuỳ chọn. (Redesign §5.2)
class EmotionalCheckinSheet extends StatefulWidget {
  /// Trả về `true` qua callback khi submit thành công để màn gọi mở Kết quả.
  final Future<bool> Function(String mood, int intensity, String note) onSubmit;

  /// Cảm xúc chọn sẵn (vd. khi mở từ dải emoji inline trên Home).
  final String? initialMood;

  const EmotionalCheckinSheet({
    super.key,
    required this.onSubmit,
    this.initialMood,
  });

  /// Mở sheet và trả về `true` nếu user đã check-in thành công.
  static Future<bool> show(
    BuildContext context, {
    required Future<bool> Function(String mood, int intensity, String note)
    onSubmit,
    String? initialMood,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => EmotionalCheckinSheet(
        onSubmit: onSubmit,
        initialMood: initialMood,
      ),
    );
    return result ?? false;
  }

  @override
  State<EmotionalCheckinSheet> createState() => _EmotionalCheckinSheetState();
}

class _EmotionalCheckinSheetState extends State<EmotionalCheckinSheet> {
  static const List<Map<String, dynamic>> _moods = [
    {'emoji': '😢', 'label': 'Buồn', 'mood': 'SAD', 'intensity': 6},
    {'emoji': '😰', 'label': 'Lo lắng', 'mood': 'ANXIOUS', 'intensity': 7},
    {'emoji': '😐', 'label': 'Tạm tạm', 'mood': 'NEUTRAL', 'intensity': 5},
    {'emoji': '🙂', 'label': 'Bình yên', 'mood': 'CALM', 'intensity': 3},
    {'emoji': '😊', 'label': 'Vui', 'mood': 'HAPPY', 'intensity': 2},
  ];

  String? _selectedMood;
  double _intensity = 5;
  final TextEditingController _noteController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialMood;
    if (initial != null) {
      final match = _moods.firstWhere(
        (m) => m['mood'] == initial,
        orElse: () => const {},
      );
      if (match.isNotEmpty) {
        _selectedMood = match['mood'] as String;
        _intensity = (match['intensity'] as int).toDouble();
      }
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_selectedMood == null || _isSubmitting) return;
    setState(() => _isSubmitting = true);
    bool ok = false;
    try {
      ok = await widget.onSubmit(
        _selectedMood!,
        _intensity.round(),
        _noteController.text.trim(),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
        Navigator.of(context).pop(ok);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: const BoxDecoration(
          color: HealingStitchColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: HealingStitchColors.border,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Hôm nay bạn thấy thế nào?',
                style: healingText(size: 20, weight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                'Dành một chút cho riêng mình — không có câu trả lời đúng hay sai.',
                style: healingText(
                  size: 13,
                  color: HealingStitchColors.textSoft,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),

              // ① Chọn cảm xúc
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _moods.map((m) {
                  final isSelected = _selectedMood == m['mood'];
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      setState(() {
                        _selectedMood = m['mood'] as String;
                        _intensity = (m['intensity'] as int).toDouble();
                      });
                    },
                    child: Column(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? HealingStitchColors.paleCoral
                                : HealingStitchColors.contentBackground,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? HealingStitchColors.pink.withValues(
                                      alpha: 0.35,
                                    )
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Text(
                            m['emoji'] as String,
                            style: const TextStyle(fontSize: 26),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          m['label'] as String,
                          style: healingText(
                            size: 11,
                            weight: isSelected
                                ? FontWeight.w800
                                : FontWeight.w600,
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
              const SizedBox(height: 22),

              // ② Mức độ
              Row(
                children: [
                  Text(
                    'Mức độ',
                    style: healingText(size: 13, weight: FontWeight.w800),
                  ),
                  const Spacer(),
                  Text(
                    '${_intensity.round()}/10',
                    style: healingText(
                      size: 13,
                      weight: FontWeight.w900,
                      color: HealingStitchColors.pink,
                    ),
                  ),
                ],
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: HealingStitchColors.coral,
                  inactiveTrackColor: HealingStitchColors.border,
                  thumbColor: HealingStitchColors.pink,
                  overlayColor: HealingStitchColors.pink.withValues(alpha: 0.12),
                ),
                child: Slider(
                  value: _intensity,
                  min: 1,
                  max: 10,
                  divisions: 9,
                  label: '${_intensity.round()}',
                  onChanged: _selectedMood == null
                      ? null
                      : (value) => setState(() => _intensity = value),
                ),
              ),
              const SizedBox(height: 8),

              // ③ Ghi chú tuỳ chọn
              Text(
                'Muốn ghi lại gì không? (không bắt buộc)',
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
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TextField(
                  controller: _noteController,
                  maxLines: 3,
                  style: healingText(size: 14),
                  decoration: InputDecoration(
                    hintText: 'Mình đang cảm thấy…',
                    hintStyle: healingText(
                      size: 14,
                      color: HealingStitchColors.textMuted.withValues(
                        alpha: 0.6,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(14),
                  ),
                ),
              ),
              const SizedBox(height: 22),

              Opacity(
                opacity: _selectedMood == null ? 0.5 : 1,
                child: IgnorePointer(
                  ignoring: _selectedMood == null || _isSubmitting,
                  child: HealingGradientButton(
                    label: _isSubmitting ? 'Đang lưu…' : 'Xong',
                    icon: Icons.check_rounded,
                    onTap: _handleSubmit,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: TextButton(
                  onPressed: _isSubmitting
                      ? null
                      : () => Navigator.of(context).pop(false),
                  child: Text(
                    'Bỏ qua hôm nay',
                    style: healingText(
                      size: 13,
                      weight: FontWeight.w700,
                      color: HealingStitchColors.textMuted,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
