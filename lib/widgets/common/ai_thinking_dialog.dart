import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../screens/healing/healing_stitch_style.dart';
import '../../theme/app_theme.dart';
import 'bondy_widgets.dart';

/// Popup "AI đang suy nghĩ" hiển thị trong lúc chờ AI trả lời.
///
/// Chặn tương tác (barrier + [PopScope]) và tự đóng khi câu trả lời đầu tiên
/// về. Chữ trạng thái đổi dần theo giây để giảm cảm giác chờ.
class AiThinkingDialog extends StatefulWidget {
  /// Danh sách chữ trạng thái (tối đa 4 nấc, đổi dần theo giây). Nếu bỏ trống
  /// dùng [_defaultMessages].
  final List<String>? messages;

  const AiThinkingDialog({super.key, this.messages});

  @override
  State<AiThinkingDialog> createState() => _AiThinkingDialogState();
}

class _AiThinkingDialogState extends State<AiThinkingDialog>
    with SingleTickerProviderStateMixin {
  static const List<String> _defaultMessages = <String>[
    'Bondy đang suy nghĩ…',
    'Đang soạn câu trả lời cho bạn…',
    'Sắp xong rồi…',
    'Chờ mình thêm chút nhé…',
  ];

  late final AnimationController _dotsController;
  Timer? _messageTimer;
  late final List<String> _messages;
  int _messageIndex = 0;

  @override
  void initState() {
    super.initState();
    _messages = (widget.messages != null && widget.messages!.isNotEmpty)
        ? widget.messages!
        : _defaultMessages;
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
    _startMessageRotation();
  }

  void _startMessageRotation() {
    _messageTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final seconds = timer.tick;
      final tier = switch (seconds) {
        < 3 => 0,
        < 8 => 1,
        < 20 => 2,
        _ => 3,
      };
      final clamped = tier.clamp(0, _messages.length - 1);
      if (clamped != _messageIndex) {
        setState(() => _messageIndex = clamped);
      }
    });
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 48),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(BondyRadius.lg),
            boxShadow: [bondySoftShadow(0.12)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                decoration: const BoxDecoration(
                  color: HealingStitchColors.paleCoral,
                  borderRadius: BorderRadius.all(Radius.circular(BondyRadius.full)),
                ),
                child: _buildDots(),
              ),
              const SizedBox(height: 20),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Text(
                  _messages[_messageIndex],
                  key: ValueKey<int>(_messageIndex),
                  textAlign: TextAlign.center,
                  style: bondyText(
                    size: 14,
                    weight: FontWeight.w600,
                    color: HealingStitchColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDots() {
    return AnimatedBuilder(
      animation: _dotsController,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List<Widget>.generate(3, (i) {
            // Mỗi chấm lệch pha 0.2 để tạo hiệu ứng nhảy so le.
            final phase = (_dotsController.value + i * 0.2) % 1.0;
            final bounce = math.sin(phase * math.pi).clamp(0.0, 1.0);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Transform.translate(
                offset: Offset(0, -6 * bounce),
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: HealingStitchColors.coral
                        .withValues(alpha: 0.4 + 0.6 * bounce),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

/// Điều khiển show/hide popup [AiThinkingDialog] an toàn (idempotent).
///
/// Mỗi màn chat giữ một instance và gọi [show] khi bắt đầu gửi tin, [hide]
/// khi có câu trả lời đầu tiên và trong khối `finally`.
class AiThinkingController {
  bool _visible = false;

  bool get isVisible => _visible;

  void show(BuildContext context, {List<String>? messages}) {
    if (_visible) return;
    _visible = true;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (_) => AiThinkingDialog(messages: messages),
    ).then((_) => _visible = false);
  }

  void hide(BuildContext context) {
    if (!_visible) return;
    _visible = false;
    Navigator.of(context, rootNavigator: true).pop();
  }
}
