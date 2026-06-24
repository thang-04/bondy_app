import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'hole_painter.dart';
import 'onboarding_tooltip.dart';
import 'showcase_step.dart';

/// Hướng dẫn swipe dạng multi-step.
///
/// Mỗi bước đục lỗ sáng vào phần tử đang giải thích kèm tooltip có nút
/// "Tiếp tục" và "Bỏ qua" — giống hệ thống [OnboardingOverlay].
class SwipeTutorialOverlay extends StatefulWidget {
  /// Key của phần card swiper (bước 1: hướng dẫn quẹt)
  final GlobalKey cardAreaKey;

  /// Key của hàng 4 nút action bên dưới (bước 2: giải thích nút)
  final GlobalKey bottomButtonsKey;

  /// Gọi khi user hoàn thành hoặc bỏ qua tour
  final VoidCallback onDismiss;

  const SwipeTutorialOverlay({
    super.key,
    required this.cardAreaKey,
    required this.bottomButtonsKey,
    required this.onDismiss,
  });

  @override
  State<SwipeTutorialOverlay> createState() => _SwipeTutorialOverlayState();
}

class _SwipeTutorialOverlayState extends State<SwipeTutorialOverlay>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  bool _ready = false; // chờ render objects sẵn sàng
  late AnimationController _handController;
  late Animation<Offset> _handOffset;

  /// Danh sách các bước hướng dẫn — mỗi bước gắn vào 1 GlobalKey
  late final List<_TutorialStep> _steps;

  @override
  void initState() {
    super.initState();

    _steps = [
      _TutorialStep(
        targetKey: widget.cardAreaKey,
        title: 'Quẹt để Khám Phá 👆',
        content:
            'Kéo thẻ sang phải để Thích, sang trái để Bỏ qua, hoặc vuốt lên để Super Like.',
        icon: '💖',
        position: ShowcasePosition.bottom,
        showHandAnimation: true,
      ),
      _TutorialStep(
        targetKey: widget.bottomButtonsKey,
        title: 'Nút Tương Tác Nhanh ⚡',
        content:
            'Bạn cũng có thể bấm trực tiếp để Hoàn tác, Bỏ qua, Super Like hoặc Thích.',
        icon: '🎯',
        position: ShowcasePosition.top,
        showHandAnimation: false,
      ),
    ];

    _handController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    _handOffset = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween<Offset>(
                begin: const Offset(-0.8, 0.0), end: const Offset(0.6, 0.0))
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 70,
      ),
      TweenSequenceItem(
        tween: ConstantTween<Offset>(const Offset(0.6, 0.0)),
        weight: 30,
      ),
    ]).animate(_handController);

    // Đợi 1 frame để render objects của GlobalKey sẵn sàng rồi mới hiển thị
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _ready = true);
      }
    });
  }

  @override
  void dispose() {
    _handController.dispose();
    super.dispose();
  }

  void _goNext() {
    if (_currentStep < _steps.length - 1) {
      setState(() => _currentStep++);
    } else {
      widget.onDismiss();
    }
  }

  void _skip() {
    widget.onDismiss();
  }

  /// Lấy Rect của GlobalKey, trả về null nếu chưa sẵn sàng
  Rect? _getRectForKey(GlobalKey key) {
    final renderBox =
        key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.attached) return null;
    final size = renderBox.size;
    final position = renderBox.localToGlobal(Offset.zero);
    const padding = 8.0;
    return Rect.fromLTWH(
      position.dx - padding,
      position.dy - padding,
      size.width + padding * 2,
      size.height + padding * 2,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Chưa sẵn sàng → chỉ hiện overlay mờ nhẹ (không hiện gì khác)
    if (!_ready) {
      return const SizedBox.shrink();
    }

    final step = _steps[_currentStep];
    final targetRect = _getRectForKey(step.targetKey);
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // Nếu không lấy được vị trí target → dùng vùng trung tâm mặc định
    final effectiveRect = targetRect ??
        Rect.fromCenter(
          center: Offset(screenWidth / 2, screenHeight * 0.4),
          width: screenWidth - 40,
          height: screenHeight * 0.35,
        );

    // Tính vị trí tooltip
    double? tooltipTop;
    double? tooltipBottom;

    if (step.position == ShowcasePosition.top) {
      tooltipBottom = screenHeight - effectiveRect.top + 16;
      // Đảm bảo tooltip không bị đẩy ra ngoài màn hình
      if (tooltipBottom > screenHeight - 100) {
        tooltipBottom = screenHeight * 0.5;
      }
    } else {
      tooltipTop = effectiveRect.bottom + 16;
      // Đảm bảo tooltip không bị đẩy quá xuống dưới
      if (tooltipTop > screenHeight - 150) {
        tooltipTop = screenHeight - 200;
      }
    }

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Lớp phủ mờ đục lỗ sáng
          Positioned.fill(
            child: CustomPaint(
              painter: HolePainter(
                targetRect: effectiveRect,
                borderRadius: 16,
                barrierColor: Colors.black.withValues(alpha: 0.6),
              ),
            ),
          ),

          // Chặn click xuyên qua nền mờ
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {}, // hấp thụ click nền
            ),
          ),

          // Hoạt họa tay quẹt (chỉ ở bước có showHandAnimation)
          if (step.showHandAnimation)
            Positioned(
              left: 0,
              right: 0,
              top: effectiveRect.top + (effectiveRect.height * 0.3),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _handOffset,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(_handOffset.value.dx * 100, 0),
                        child:
                            const Text('👉', style: TextStyle(fontSize: 48)),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildSwipeHint(
                        emoji: '❌',
                        label: '← Bỏ qua',
                        color: const Color(0xFFEF4444),
                      ),
                      const SizedBox(width: 24),
                      _buildSwipeHint(
                        emoji: '💚',
                        label: 'Thích →',
                        color: const Color(0xFF2ECC71),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // Tooltip hướng dẫn có nút Tiếp tục / Bỏ qua
          Positioned(
            left: 20,
            right: 20,
            top: tooltipTop,
            bottom: tooltipBottom,
            child: OnboardingTooltip(
              title: step.title,
              content: step.content,
              icon: step.icon,
              currentStep: _currentStep + 1,
              totalSteps: _steps.length,
              onNext: _goNext,
              onSkip: _skip,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwipeHint({
    required String emoji,
    required String label,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

/// Mô tả một bước hướng dẫn swipe
class _TutorialStep {
  final GlobalKey targetKey;
  final String title;
  final String content;
  final String icon;
  final ShowcasePosition position;
  final bool showHandAnimation;

  _TutorialStep({
    required this.targetKey,
    required this.title,
    required this.content,
    required this.icon,
    required this.position,
    required this.showHandAnimation,
  });
}
