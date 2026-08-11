import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../widgets/primary_button.dart';

/// Dedicated map picker screen. This paints a mock map — wiring a real one
/// requires the `google_maps_flutter` package plus per-platform API keys,
/// which this project doesn't have configured, and no fake key should be
/// invented. The tap-to-place interaction and the returned (lat, lng) are
/// built so a real map view can be dropped in later without touching the
/// callers.
class WorkshopLocationScreen extends StatefulWidget {
  const WorkshopLocationScreen({
    super.key,
    required this.initialLatitude,
    required this.initialLongitude,
    required this.address,
  });

  final double initialLatitude;
  final double initialLongitude;
  final String address;

  @override
  State<WorkshopLocationScreen> createState() => _WorkshopLocationScreenState();
}

class _WorkshopLocationScreenState extends State<WorkshopLocationScreen> {
  late double _latitude = widget.initialLatitude;
  late double _longitude = widget.initialLongitude;
  Alignment _markerAlignment = Alignment.center;

  void _moveMarker(Offset localPosition, Size size) {
    final double dx = ((localPosition.dx / size.width) * 2 - 1).clamp(-1.0, 1.0);
    final double dy = ((localPosition.dy / size.height) * 2 - 1).clamp(-1.0, 1.0);
    setState(() {
      _markerAlignment = Alignment(dx, dy);
      _latitude = widget.initialLatitude - dy * 0.01;
      _longitude = widget.initialLongitude + dx * 0.01;
    });
  }

  void _confirm() {
    Navigator.of(context).pop((_latitude, _longitude));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              child: Row(
                children: <Widget>[
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, color: AppColors.primaryText),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Row(
                        children: <Widget>[
                          Icon(Icons.search, size: 18, color: AppColors.secondaryText),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Search location',
                              style: TextStyle(fontSize: 13.5, color: AppColors.secondaryText),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final Size size = Size(constraints.maxWidth, constraints.maxHeight);
                  return GestureDetector(
                    onTapUp: (TapUpDetails details) => _moveMarker(details.localPosition, size),
                    child: Stack(
                      fit: StackFit.expand,
                      children: <Widget>[
                        CustomPaint(painter: _MapGridPainter()),
                        const Align(
                          alignment: Alignment.center,
                          child: Icon(Icons.my_location, color: AppColors.secondaryCyan, size: 18),
                        ),
                        Align(
                          alignment: _markerAlignment,
                          child: const Icon(Icons.location_on, color: AppColors.dangerRed, size: 38),
                        ),
                        const Positioned(
                          left: 12,
                          top: 12,
                          child: _MapHint(text: 'Tap the map to move the workshop marker'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
              decoration: const BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: <BoxShadow>[
                  BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, -4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Workshop Location',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.primaryText),
                  ),
                  const SizedBox(height: 4),
                  Text(widget.address, style: const TextStyle(fontSize: 12.5, color: AppColors.secondaryText)),
                  const SizedBox(height: 10),
                  Row(
                    children: <Widget>[
                      Expanded(child: _CoordinateTile(label: 'Latitude', value: _latitude.toStringAsFixed(4))),
                      const SizedBox(width: 10),
                      Expanded(child: _CoordinateTile(label: 'Longitude', value: _longitude.toStringAsFixed(4))),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => setState(() {
                            _markerAlignment = Alignment.center;
                            _latitude = widget.initialLatitude;
                            _longitude = widget.initialLongitude;
                          }),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primaryBlue,
                            side: const BorderSide(color: AppColors.primaryBlue),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                          ),
                          child: const Text('Use This Location'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: PrimaryButton(label: 'Confirm Location', trailingIcon: null, onPressed: _confirm),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapHint extends StatelessWidget {
  const _MapHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: const TextStyle(fontSize: 11, color: Colors.white)),
    );
  }
}

class _CoordinateTile extends StatelessWidget {
  const _CoordinateTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: const TextStyle(fontSize: 10.5, color: AppColors.secondaryText)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primaryText)),
        ],
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFE7EEE7));

    final Paint road = Paint()
      ..color = Colors.white
      ..strokeWidth = 8;
    canvas.drawLine(Offset(0, size.height * 0.35), Offset(size.width, size.height * 0.55), road);
    canvas.drawLine(Offset(size.width * 0.3, 0), Offset(size.width * 0.55, size.height), road);
    canvas.drawLine(Offset(0, size.height * 0.75), Offset(size.width, size.height * 0.68), road);

    final Paint block = Paint()..color = const Color(0xFFD5E4D5);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.05, size.height * 0.08, size.width * 0.22, size.height * 0.16), block);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.68, size.height * 0.62, size.width * 0.25, size.height * 0.2), block);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.15, size.height * 0.55, size.width * 0.18, size.height * 0.14), block);
  }

  @override
  bool shouldRepaint(covariant _MapGridPainter oldDelegate) => false;
}
