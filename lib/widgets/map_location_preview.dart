import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../core/app_colors.dart';
import 'open_street_map_view.dart';

/// Small static map preview with a coordinate readout and a "set location"
/// action that opens the full interactive picker.
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
            child: IgnorePointer(
              child: OpenStreetMapView(
                center: LatLng(latitude, longitude),
                zoom: 15,
                interactive: false,
                markers: <Marker>[
                  Marker(
                    point: LatLng(latitude, longitude),
                    child: const Icon(Icons.location_on, color: AppColors.burntOrange, size: 36),
                  ),
                ],
              ),
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
