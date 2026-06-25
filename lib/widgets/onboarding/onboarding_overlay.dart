import 'package:flutter/material.dart';
import 'showcase_step.dart';
import 'hole_painter.dart';
import 'onboarding_tooltip.dart';

class OnboardingOverlay {
  static OverlayEntry? _overlayEntry;

  static void show(
    BuildContext context, {
    required List<ShowcaseStep> steps,
    VoidCallback? onCompleted,
    VoidCallback? onSkipped,
  }) {
    if (steps.isEmpty) return;

    int currentStepIndex = 0;
    final overlayState = Overlay.of(context);

    void remove() {
      _overlayEntry?.remove();
      _overlayEntry = null;
    }

    void renderStep() {
      remove();

      final step = steps[currentStepIndex];
      final renderBox = step.targetKey.currentContext?.findRenderObject() as RenderBox?;
      
      if (renderBox == null) {
        // Bỏ qua bước nếu widget chưa sẵn sàng hiển thị trên màn hình
        if (currentStepIndex < steps.length - 1) {
          currentStepIndex++;
          renderStep();
        } else {
          onCompleted?.call();
        }
        return;
      }

      final size = renderBox.size;
      final position = renderBox.localToGlobal(Offset.zero);
      // Padding xung quanh lỗ đục sáng để tạo khoảng thở rộng hơn widget
      const double padding = 6.0;
      final targetRect = Rect.fromLTWH(
        position.dx - padding,
        position.dy - padding,
        size.width + padding * 2,
        size.height + padding * 2,
      );

      _overlayEntry = OverlayEntry(
        builder: (context) {
          final screenWidth = MediaQuery.of(context).size.width;
          final tooltipWidth = screenWidth - 40; // margin 20px mỗi bên

          // Tính toán vị trí hiển thị của Tooltip dựa theo cấu hình và vị trí widget
          double? tooltipTop;
          double? tooltipBottom;

          if (step.position == ShowcasePosition.top) {
            tooltipBottom = MediaQuery.of(context).size.height - position.dy + 12;
          } else {
            tooltipTop = position.dy + size.height + 12;
          }

          return Material(
            color: Colors.transparent,
            child: Stack(
              children: [
                // Lớp phủ mờ vẽ lỗ đục sáng
                Positioned.fill(
                  child: CustomPaint(
                    painter: HolePainter(
                      targetRect: targetRect,
                      borderRadius: 16,
                    ),
                  ),
                ),
                
                // Chặn click xuyên qua nền mờ
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {}, // hấp thụ tất cả click
                  ),
                ),

                // Bong bóng tooltip
                Positioned(
                  left: 20,
                  width: tooltipWidth,
                  top: tooltipTop,
                  bottom: tooltipBottom,
                  child: OnboardingTooltip(
                    title: step.title,
                    content: step.content,
                    icon: step.icon,
                    currentStep: currentStepIndex + 1,
                    totalSteps: steps.length,
                    onNext: () {
                      if (currentStepIndex < steps.length - 1) {
                        currentStepIndex++;
                        renderStep();
                      } else {
                        remove();
                        onCompleted?.call();
                      }
                    },
                    onSkip: () {
                      remove();
                      onSkipped?.call();
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );

      overlayState.insert(_overlayEntry!);
    }

    renderStep();
  }
}
