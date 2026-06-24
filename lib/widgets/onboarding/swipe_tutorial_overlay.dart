import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'hole_painter.dart';

class SwipeTutorialOverlay extends StatefulWidget {
  final GlobalKey bottomButtonsKey;
  final VoidCallback onDismiss;

  const SwipeTutorialOverlay({
    super.key,
    required this.bottomButtonsKey,
    required this.onDismiss,
  });

  @override
  State<SwipeTutorialOverlay> createState() => _SwipeTutorialOverlayState();
}

class _SwipeTutorialOverlayState extends State<SwipeTutorialOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _handOffsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    _handOffsetAnimation = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween<Offset>(begin: const Offset(-0.8, 0.0), end: const Offset(0.6, 0.0))
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 70,
      ),
      TweenSequenceItem(
        tween: ConstantTween<Offset>(const Offset(0.6, 0.0)),
        weight: 30,
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final renderBox = widget.bottomButtonsKey.currentContext?.findRenderObject() as RenderBox?;
    Rect targetRect = Rect.zero;

    if (renderBox != null) {
      final size = renderBox.size;
      final position = renderBox.localToGlobal(Offset.zero);
      targetRect = Rect.fromLTWH(
        position.dx - 8,
        position.dy - 8,
        size.width + 16,
        size.height + 16,
      );
    }

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Vẽ nền đen mờ đục lỗ sáng cho 4 nút dưới cùng
          Positioned.fill(
            child: CustomPaint(
              painter: HolePainter(
                targetRect: targetRect,
                borderRadius: 16,
                barrierColor: Colors.black.withOpacity(0.75),
              ),
            ),
          ),

          // Chặn tương tác click bên dưới
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
            ),
          ),

          // Hướng dẫn 2 bên cánh quẹt trái/phải
          Positioned(
            top: MediaQuery.of(context).size.height * 0.35,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Trái (Bỏ qua)
                _buildDirectionIndicator(
                  emoji: '❌',
                  label: 'Quẹt Trái\nBỏ qua',
                  color: const Color(0xFFEF4444),
                ),
                
                // Phải (Thích)
                _buildDirectionIndicator(
                  emoji: '💚',
                  label: 'Quẹt Phải\nGửi Thích',
                  color: const Color(0xFF2ECC71),
                ),
              ],
            ),
          ),

          // Hoạt họa cử chỉ ở trung tâm
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 40),
                AnimatedBuilder(
                  animation: _handOffsetAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(_handOffsetAnimation.value.dx * 100, 0),
                      child: const Text('👉', style: TextStyle(fontSize: 48)),
                    );
                  },
                ),
                const SizedBox(height: 10),
                Text(
                  'Kéo sang phải để Thích',
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFFFFAA66),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),

          // Text hướng dẫn tiêu đề chính ở trên
          Positioned(
            top: 80,
            left: 20,
            right: 20,
            child: Column(
              children: [
                Text(
                  'Hướng dẫn Quẹt Kết Nối',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Khám phá và kết nối cực kỳ đơn giản',
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFFC0C0C5),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          // Tooltip hướng dẫn 4 nút tương tác nhanh ở dưới lỗ đục
          if (renderBox != null)
            Positioned(
              left: 20,
              right: 20,
              bottom: MediaQuery.of(context).size.height - targetRect.top + 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A24),
                  border: Border.all(color: const Color(0xFFFF6B6B).withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Nút tương tác nhanh',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Bạn cũng có thể bấm trực tiếp để Hoàn tác, Bỏ qua, Super Like hoặc Thích.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFFD0D0D6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Nút "Bắt đầu khám phá" dưới cùng
          Positioned(
            bottom: 40,
            left: 30,
            right: 30,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: const Color(0xFFFF6B6B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                  side: BorderSide.none,
                ),
                elevation: 5,
              ),
              onPressed: widget.onDismiss,
              child: Text(
                'Bắt đầu khám phá',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectionIndicator({
    required String emoji,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        border: Border.all(color: color.withOpacity(0.6), width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      width: 85,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              color: color.withOpacity(0.9),
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
