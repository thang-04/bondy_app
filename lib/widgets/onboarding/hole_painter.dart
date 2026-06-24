import 'package:flutter/material.dart';

class HolePainter extends CustomPainter {
  final Rect targetRect;
  final double borderRadius;
  final Color barrierColor;

  HolePainter({
    required this.targetRect,
    this.borderRadius = 12.0,
    this.barrierColor = Colors.black54,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = barrierColor
      ..style = PaintingStyle.fill;

    // Vẽ lớp nền phủ mờ toàn bộ canvas
    final backgroundPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // Vẽ vùng lỗ đục sáng
    final holePath = Path();
    if (borderRadius > 0) {
      holePath.addRRect(RRect.fromRectAndRadius(targetRect, Radius.circular(borderRadius)));
    } else {
      holePath.addOval(targetRect);
    }

    // Đục lỗ bằng cách lấy phần hiệu (difference)
    final finalPath = Path.combine(PathOperation.difference, backgroundPath, holePath);
    canvas.drawPath(finalPath, paint);
  }

  @override
  bool shouldRepaint(covariant HolePainter oldDelegate) {
    return oldDelegate.targetRect != targetRect ||
        oldDelegate.borderRadius != borderRadius ||
        oldDelegate.barrierColor != barrierColor;
  }
}
