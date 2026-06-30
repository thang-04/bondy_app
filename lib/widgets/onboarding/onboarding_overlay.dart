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
    const maxTargetLookupAttempts = 5;
    var targetLookupAttempts = 0;
    var showedAnyStep = false;
    var isActive = true;

    void remove({bool deactivate = false}) {
      _overlayEntry?.remove();
      _overlayEntry = null;
      if (deactivate) {
        isActive = false;
      }
    }

    void renderStep() {
      if (!isActive || !context.mounted) return;
      remove();

      if (currentStepIndex >= steps.length) {
        if (showedAnyStep) {
          isActive = false;
          onCompleted?.call();
        }
        return;
      }

      final step = steps[currentStepIndex];
      final renderObject = step.targetKey.currentContext?.findRenderObject();
      final renderBox = renderObject is RenderBox ? renderObject : null;

      if (renderBox == null || !renderBox.attached || renderBox.size.isEmpty) {
        if (targetLookupAttempts < maxTargetLookupAttempts) {
          targetLookupAttempts++;
          WidgetsBinding.instance.addPostFrameCallback((_) => renderStep());
          return;
        }

        targetLookupAttempts = 0;
        if (currentStepIndex < steps.length - 1) {
          currentStepIndex++;
          renderStep();
        } else {
          currentStepIndex = steps.length;
          renderStep();
        }
        return;
      }

      targetLookupAttempts = 0;
      showedAnyStep = true;
      final size = renderBox.size;
      Offset position;
      final overlayRenderObject = overlayState.context.findRenderObject();
      if (overlayRenderObject is RenderBox && overlayRenderObject.attached) {
        try {
          position = renderBox.localToGlobal(
            Offset.zero,
            ancestor: overlayRenderObject,
          );
        } catch (_) {
          position = renderBox.localToGlobal(Offset.zero);
        }
      } else {
        position = renderBox.localToGlobal(Offset.zero);
      }
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
          final mediaQuery = MediaQuery.of(context);
          final overlaySize =
              overlayRenderObject is RenderBox &&
                  overlayRenderObject.attached &&
                  !overlayRenderObject.size.isEmpty
              ? overlayRenderObject.size
              : mediaQuery.size;
          final screenWidth = overlaySize.width;
          final screenHeight = overlaySize.height;
          const horizontalMargin = 20.0;
          final tooltipWidth = (screenWidth - horizontalMargin * 2)
              .clamp(0.0, screenWidth)
              .toDouble();

          const estimatedTooltipHeight = 176.0;
          final safeTop = mediaQuery.padding.top + 16.0;
          final safeBottom = mediaQuery.padding.bottom + 16.0;
          final availableTooltipHeight = screenHeight - safeTop - safeBottom;
          final maxTooltipHeight = availableTooltipHeight > 0
              ? availableTooltipHeight
              : screenHeight;
          final maxTooltipTop =
              screenHeight - safeBottom - estimatedTooltipHeight;
          final clampedMaxTooltipTop = maxTooltipTop < safeTop
              ? safeTop
              : maxTooltipTop;
          final aboveTargetTop = position.dy - estimatedTooltipHeight - 12.0;
          final belowTargetTop = position.dy + size.height + 12.0;
          double preferredTooltipTop;
          if (step.position == ShowcasePosition.top) {
            preferredTooltipTop = aboveTargetTop >= safeTop
                ? aboveTargetTop
                : belowTargetTop;
          } else {
            preferredTooltipTop =
                belowTargetTop + estimatedTooltipHeight <=
                    screenHeight - safeBottom
                ? belowTargetTop
                : aboveTargetTop;
          }
          final tooltipTop = preferredTooltipTop
              .clamp(safeTop, clampedMaxTooltipTop)
              .toDouble();

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

                // Chặn click xuyên qua nền mờ & Cho phép chạm để chuyển bước
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      if (currentStepIndex < steps.length - 1) {
                        currentStepIndex++;
                        renderStep();
                      } else {
                        remove(deactivate: true);
                        onCompleted?.call();
                      }
                    },
                  ),
                ),

                // Bong bóng tooltip
                Positioned(
                  left: horizontalMargin,
                  width: tooltipWidth,
                  top: tooltipTop,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: maxTooltipHeight),
                    child: SingleChildScrollView(
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
                            remove(deactivate: true);
                            onCompleted?.call();
                          }
                        },
                        onSkip: () {
                          remove(deactivate: true);
                          onSkipped?.call();
                        },
                      ),
                    ),
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
