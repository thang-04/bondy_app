import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class SurveyIntroGraphic extends StatefulWidget {
  const SurveyIntroGraphic({super.key});

  @override
  State<SurveyIntroGraphic> createState() => _SurveyIntroGraphicState();
}

class _SurveyIntroGraphicState extends State<SurveyIntroGraphic>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    // Float up and down by 10 pixels
    _animation = Tween<double>(
      begin: 0,
      end: -10,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value),
          child: SizedBox(
            width: 256,
            height: 256,
            child: CustomPaint(painter: _GraphicPainter()),
          ),
        );
      },
    );
  }
}

class _GraphicPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Coordinate system based on 0,0 to 200,200 viewBox
    final double s = size.width / 200.0;
    canvas.save();
    canvas.scale(s, s);

    // Faint subtle circle in the back
    final Paint circle1Paint = Paint()
      ..color = BondyColors.textHint.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(100, 100), 90, circle1Paint);

    // Gradient heart shape
    final Paint heartPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFE79688), Color(0xFFFF3399)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(20, 25, 160, 155))
      ..style = PaintingStyle.fill;

    final Path heartPath = Path()
      ..moveTo(100, 180)
      ..cubicTo(40, 130, 20, 90, 20, 60)
      ..arcToPoint(const Offset(90, 60), radius: const Radius.circular(35))
      ..lineTo(100, 70)
      ..lineTo(110, 60)
      ..arcToPoint(const Offset(180, 60), radius: const Radius.circular(35))
      ..cubicTo(180, 90, 160, 130, 100, 180)
      ..close();
    canvas.drawPath(heartPath, heartPaint);

    // Simple curved trace line
    final Path dashedArc = Path()
      ..moveTo(60, 60)
      ..quadraticBezierTo(100, 20, 140, 60);

    canvas.drawPath(
      dashedArc,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.4)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Floating particles (circles)
    canvas.drawCircle(
      const Offset(100, 40),
      4,
      Paint()..color = Colors.white.withValues(alpha: 0.8),
    );
    canvas.drawCircle(
      const Offset(160, 50),
      8,
      Paint()..color = const Color(0xFFE797A3).withValues(alpha: 0.6),
    );
    canvas.drawCircle(
      const Offset(40, 120),
      6,
      Paint()..color = const Color(0xFFCC99CC).withValues(alpha: 0.6),
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
