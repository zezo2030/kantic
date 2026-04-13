import 'package:flutter/material.dart';

/// A thin vertical dashed divider, height must be constrained by parent.
class DashedDivider extends StatelessWidget {
  final double dashLength;
  final double dashGap;
  final double thickness;
  final Color color;

  const DashedDivider({
    super.key,
    this.dashLength = 4,
    this.dashGap = 4,
    this.thickness = 1,
    this.color = const Color(0xFFE5E7EB),
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedPainter(
        dashLength: dashLength,
        dashGap: dashGap,
        thickness: thickness,
        color: color,
      ),
    );
  }
}

class _DashedPainter extends CustomPainter {
  final double dashLength;
  final double dashGap;
  final double thickness;
  final Color color;

  _DashedPainter({
    required this.dashLength,
    required this.dashGap,
    required this.thickness,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    double y = 0;
    final x = size.width / 2;
    while (y < size.height) {
      final endY = (y + dashLength).clamp(0.0, size.height).toDouble();
      canvas.drawLine(Offset(x, y), Offset(x, endY), paint);
      y += dashLength + dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.dashGap != dashGap ||
        oldDelegate.dashLength != dashLength ||
        oldDelegate.thickness != thickness;
  }
}


