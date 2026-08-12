import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/app_colors.dart';
import '../../widgets/primary_button.dart';

/// Dedicated map picker screen — tap anywhere to move the workshop marker.
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
  GoogleMapController? _mapController;

  void _moveMarker(LatLng position) {
    setState(() {
      _latitude = position.latitude;
      _longitude = position.longitude;
    });
  }

  void _resetToInitial() {
    setState(() {
      _latitude = widget.initialLatitude;
      _longitude = widget.initialLongitude;
    });
    _mapController?.animateCamera(
      CameraUpdate.newLatLng(LatLng(widget.initialLatitude, widget.initialLongitude)),
    );
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
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(_latitude, _longitude),
                      zoom: 16,
                    ),
                    onMapCreated: (GoogleMapController controller) => _mapController = controller,
                    onTap: _moveMarker,
                    zoomControlsEnabled: false,
                    markers: <Marker>{
                      Marker(
                        markerId: const MarkerId('workshop-location'),
                        position: LatLng(_latitude, _longitude),
                        draggable: true,
                        onDragEnd: _moveMarker,
                      ),
                    },
                  ),
                  const Positioned(
                    left: 12,
                    top: 12,
                    child: _MapHint(text: 'Tap the map or drag the pin to move the workshop marker'),
                  ),
                ],
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
                          onPressed: _resetToInitial,
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
