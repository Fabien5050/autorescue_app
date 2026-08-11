import 'package:flutter/material.dart';

import '../core/app_colors.dart';

/// Static map-style placeholder with a coordinate readout and a
/// "set location" action.
///
/// This is a painted stand-in, not a real map — wiring an actual map
/// requires the `google_maps_flutter` package plus per-platform API keys,
/// which this project doesn't have configured. [onSetLocation] is the hook
/// to swap in a real map picker later.
class MapLocationPreview extends StatelessWidget {
  const MapLocationPreview({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.onSetLocation,
  });

  final double latitude;
  final double longitude;
  final VoidCallback onSetLocation;

  String get _coordinateLabel {
    final String latHemisphere = latitude >= 0 ? 'N' : 'S';
    final String lngHemisphere = longitude >= 0 ? 'E' : 'W';
    return '${latitude.abs().toStringAsFixed(4)}°$latHemisphere, '
        '${longitude.abs().toStringAsFixed(4)}°$lngHemisphere';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 120,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                CustomPaint(painter: _MapGridPainter()),
                const Align(
                  alignment: Alignment(-0.2, -0.1),
                  child: Icon(Icons.location_on, color: AppColors.burntOrange, size: 30),
                ),
                const Align(
                  alignment: Alignment(0.45, 0.35),
                  child: Icon(Icons.location_on, color: AppColors.burntOrange, size: 22),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _coordinateLabel,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AppColors.slate,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onSetLocation,
            icon: const Icon(Icons.my_location, size: 16, color: AppColors.burntOrange),
            label: const Text('Set Physical Location on Map'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.burntOrange,
              side: const BorderSide(color: AppColors.burntOrange, width: 1.3),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFE7EEE7));

    final Paint road = Paint()
      ..color = Colors.white
      ..strokeWidth = 6;
    canvas.drawLine(Offset(0, size.height * 0.35), Offset(size.width, size.height * 0.55), road);
    canvas.drawLine(Offset(size.width * 0.3, 0), Offset(size.width * 0.55, size.height), road);

    final Paint block = Paint()..color = const Color(0xFFD5E4D5);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.05, size.height * 0.05, size.width * 0.18, size.height * 0.2), block);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.7, size.height * 0.65, size.width * 0.22, size.height * 0.25), block);
  }

  @override
  bool shouldRepaint(covariant _MapGridPainter oldDelegate) => false;
}
