import 'package:flutter/widgets.dart';

/// Clips a rectangle into a ticket-like shape with circular notches
/// on the middle of left and right edges.
class TicketClipper extends CustomClipper<Path> {
  final double borderRadius;
  final double notchRadius;

  const TicketClipper({
    this.borderRadius = 16,
    this.notchRadius = 10,
  });

  @override
  Path getClip(Size size) {
    final r = borderRadius;
    final w = size.width;
    final h = size.height;
    final notchR = notchRadius;

    // Base rounded rect
    final base = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, w, h),
        Radius.circular(r),
      ));

    // Left middle notch circle
    final leftNotch = Path()
      ..addOval(Rect.fromCircle(center: Offset(0, h / 2), radius: notchR));

    // Right middle notch circle
    final rightNotch = Path()
      ..addOval(Rect.fromCircle(center: Offset(w, h / 2), radius: notchR));

    // Subtract notches from the base path
    final withLeft = Path.combine(PathOperation.difference, base, leftNotch);
    final withBoth =
        Path.combine(PathOperation.difference, withLeft, rightNotch);

    return withBoth;
  }

  @override
  bool shouldReclip(TicketClipper oldClipper) {
    return oldClipper.borderRadius != borderRadius ||
        oldClipper.notchRadius != notchRadius;
  }
}


