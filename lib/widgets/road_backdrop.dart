import 'package:flutter/material.dart';

import '../core/app_colors.dart';

/// Very low-contrast road-between-trees watermark used behind the splash.
///
/// Painted instead of shipped as an image so it stays sharp on every density
/// and adapts to the screen aspect ratio.
class RoadBackdrop extends StatelessWidget {
  const RoadBackdrop({super.key, this.opacity = 0.06});

  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Opacity(
          opacity: opacity,
          child: CustomPaint(painter: _RoadPainter()),
        ),
      ),
    );
  }
}

class _RoadPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double horizon = h * 0.34;
    final Paint paint = Paint()..style = PaintingStyle.fill;

    // Asphalt: a trapezoid narrowing towards the vanishing point.
    final Path road = Path()
      ..moveTo(w * 0.5 - w * 0.02, horizon)
      ..lineTo(w * 0.5 + w * 0.02, horizon)
      ..lineTo(w * 1.05, h)
      ..lineTo(-w * 0.05, h)
      ..close();
    canvas.drawPath(road, paint..color = AppColors.navy.withValues(alpha: 0.55));

    // Dashed centre line, segments shrink with distance.
    final Paint dash = Paint()..color = Colors.white.withValues(alpha: 0.9);
    double y = h;
    double step = h * 0.13;
    // Fixed iteration cap: `step` decays geometrically and underflows to
    // exactly 0.0 in floating point, which would make `y -= step` a no-op
    // and turn a `while (y > horizon)` loop into an infinite one.
    for (int i = 0; i < 24 && y > horizon + 4; i++) {
      final double t = (y - horizon) / (h - horizon);
      final double halfWidth = (w * 0.014) * t;
      final double segment = step * 0.55;
      final Rect rect = Rect.fromLTRB(
        w * 0.5 - halfWidth,
        (y - segment).clamp(horizon, h),
        w * 0.5 + halfWidth,
        y,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(halfWidth)),
        dash,
      );
      y -= step;
      step *= 0.78;
    }

    // Tree line flanking the road, taller and denser near the viewer.
    final Paint tree = Paint()..color = AppColors.navy.withValues(alpha: 0.75);
    for (int i = 0; i < 7; i++) {
      final double t = i / 6;
      final double baseY = horizon + (h - horizon) * (t * t * 0.95 + 0.05);
      final double scale = 0.12 + t * 0.9;
      _paintTree(canvas, tree, Offset(w * (0.30 - t * 0.34), baseY), h * 0.30 * scale);
      _paintTree(canvas, tree, Offset(w * (0.70 + t * 0.34), baseY), h * 0.30 * scale);
    }
  }

  void _paintTree(Canvas canvas, Paint paint, Offset base, double height) {
    final double width = height * 0.42;
    final Path crown = Path()
      ..moveTo(base.dx, base.dy - height)
      ..lineTo(base.dx + width / 2, base.dy)
      ..lineTo(base.dx - width / 2, base.dy)
      ..close();
    canvas.drawPath(crown, paint);
  }

  @override
  bool shouldRepaint(covariant _RoadPainter oldDelegate) => false;
}
