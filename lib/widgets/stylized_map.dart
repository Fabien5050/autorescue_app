import 'package:flutter/material.dart';

import '../core/app_colors.dart';

/// A single marker on a [StylizedMap].
class MapPin {
  const MapPin({
    required this.alignment,
    this.color = AppColors.primaryBlue,
    this.icon = Icons.location_on,
    this.size = 26,
    this.pulsing = false,
  });

  final Alignment alignment;
  final Color color;
  final IconData icon;
  final double size;
  final bool pulsing;
}

/// Painted stand-in for a real map surface (roads, blocks, pins).
///
/// This project has no `google_maps_flutter` dependency or per-platform API
/// keys configured, so every "map" in the app is this lightweight painter
/// instead — swap it for a real map widget once those are set up.
class StylizedMap extends StatelessWidget {
  const StylizedMap({
    super.key,
    this.pins = const <MapPin>[],
    this.height = 160,
    this.borderRadius = 16,
  });

  final List<MapPin> pins;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            CustomPaint(painter: _MapPainter()),
            for (final MapPin pin in pins)
              Align(
                alignment: pin.alignment,
                child: pin.pulsing
                    ? _PulsingPin(pin: pin)
                    : Icon(pin.icon, color: pin.color, size: pin.size),
              ),
          ],
        ),
      ),
    );
  }
}

class _PulsingPin extends StatefulWidget {
  const _PulsingPin({required this.pin});

  final MapPin pin;

  @override
  State<_PulsingPin> createState() => _PulsingPinState();
}

class _PulsingPinState extends State<_PulsingPin>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, _) {
        final double t = _controller.value;
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: <Widget>[
            Opacity(
              opacity: (1 - t).clamp(0.0, 1.0),
              child: Container(
                width: widget.pin.size * (1.4 + t * 1.6),
                height: widget.pin.size * (1.4 + t * 1.6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.pin.color.withValues(alpha: 0.25),
                ),
              ),
            ),
            Icon(widget.pin.icon, color: widget.pin.color, size: widget.pin.size),
          ],
        );
      },
    );
  }
}

class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFE7EEE7));

    final Paint road = Paint()
      ..color = Colors.white
      ..strokeWidth = 6;
    canvas.drawLine(
      Offset(0, size.height * 0.3),
      Offset(size.width, size.height * 0.5),
      road,
    );
    canvas.drawLine(
      Offset(size.width * 0.25, 0),
      Offset(size.width * 0.5, size.height),
      road,
    );
    canvas.drawLine(
      Offset(size.width * 0.65, 0),
      Offset(size.width * 0.85, size.height),
      road,
    );

    final Paint block = Paint()..color = const Color(0xFFD5E4D5);
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.05, size.height * 0.08, size.width * 0.16, size.height * 0.18),
      block,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.72, size.height * 0.6, size.width * 0.2, size.height * 0.28),
      block,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.35, size.height * 0.65, size.width * 0.14, size.height * 0.16),
      block,
    );
  }

  @override
  bool shouldRepaint(covariant _MapPainter oldDelegate) => false;
}
