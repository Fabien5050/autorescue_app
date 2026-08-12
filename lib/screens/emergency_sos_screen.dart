import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/api_client.dart';
import '../core/app_colors.dart';
import '../core/location_service.dart';
import '../models/workshop.dart';
import '../services/assistance_request_api.dart';
import '../services/workshop_api.dart';

/// SOS tab: fastest path to sharing location and calling the nearest help.
class EmergencySosScreen extends StatefulWidget {
  const EmergencySosScreen({super.key});

  @override
  State<EmergencySosScreen> createState() => _EmergencySosScreenState();
}

class _EmergencySosScreenState extends State<EmergencySosScreen> {
  late Future<List<Workshop>> _nearby;
  double _driverLatitude = LocationService.fallbackLatitude;
  double _driverLongitude = LocationService.fallbackLongitude;
  bool _hasRealLocation = false;
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    _nearby = _loadNearby();
  }

  Future<List<Workshop>> _loadNearby() async {
    final position = await LocationService.getCurrentPosition();
    _hasRealLocation = position != null;
    _driverLatitude = position?.latitude ?? LocationService.fallbackLatitude;
    _driverLongitude = position?.longitude ?? LocationService.fallbackLongitude;
    return WorkshopApi.listNearby(latitude: _driverLatitude, longitude: _driverLongitude);
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError ? const Color(0xFFDC2626) : AppColors.navy,
        behavior: SnackBarBehavior.floating,
        content: Text(message),
      ),
    );
  }

  Future<void> _requestAssistance(Workshop workshop) async {
    try {
      await AssistanceRequestApi.create(
        workshopId: workshop.id,
        driverLatitude: _driverLatitude,
        driverLongitude: _driverLongitude,
      );
      if (mounted) _showSnack('Request sent to ${workshop.name}');
    } on ApiException catch (error) {
      if (mounted) _showSnack(error.message, isError: true);
    }
  }

  Future<void> _shareLocation(List<Workshop> nearby) async {
    if (nearby.isEmpty) {
      _showSnack('No nearby workshops found right now.', isError: true);
      return;
    }
    setState(() => _isSharing = true);
    await _requestAssistance(nearby.first);
    if (mounted) setState(() => _isSharing = false);
  }

  Future<void> _dial(String phoneNumber, String label) async {
    final Uri uri = Uri(scheme: 'tel', path: phoneNumber);
    final bool launched = await launchUrl(uri);
    if (!launched && mounted) {
      _showSnack('Could not start a call to $label', isError: true);
    }
  }

  void _callContact(String label, String phoneNumber) => _dial(phoneNumber, label);

  void _callWorkshop(Workshop workshop) => _dial(workshop.phone, workshop.name);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FutureBuilder<List<Workshop>>(
          future: _nearby,
          builder: (BuildContext context, AsyncSnapshot<List<Workshop>> snapshot) {
            final List<Workshop> nearby = snapshot.data ?? const <Workshop>[];
            final bool loading = snapshot.connectionState != ConnectionState.done;

            return ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                const _EmergencyHeader(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _ShareLocationCard(
                        isBusy: _isSharing,
                        hasRealLocation: _hasRealLocation,
                        onTap: () => _shareLocation(nearby),
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        'Nearest Workshops',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.heading,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Tap call for immediate assistance',
                        style: TextStyle(fontSize: 12, color: AppColors.slate),
                      ),
                      const SizedBox(height: 12),
                      if (loading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (snapshot.hasError)
                        Text(
                          snapshot.error is ApiException
                              ? (snapshot.error! as ApiException).message
                              : 'Failed to load nearby workshops.',
                          style: const TextStyle(fontSize: 12.5, color: AppColors.slate),
                        )
                      else if (nearby.isEmpty)
                        const Text(
                          'No workshops found nearby.',
                          style: TextStyle(fontSize: 12.5, color: AppColors.slate),
                        )
                      else
                        for (int i = 0; i < nearby.length; i++) ...<Widget>[
                          _NearestWorkshopRow(
                            workshop: nearby[i],
                            urgent: i == 0,
                            onCall: () => _callWorkshop(nearby[i]),
                          ),
                          if (i != nearby.length - 1) const SizedBox(height: 10),
                        ],
                      const SizedBox(height: 20),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: SizedBox(
                          height: 150,
                          width: double.infinity,
                          child: loading
                              ? const Center(child: CircularProgressIndicator())
                              : GoogleMap(
                                  initialCameraPosition: CameraPosition(
                                    target: LatLng(_driverLatitude, _driverLongitude),
                                    zoom: 15,
                                  ),
                                  myLocationEnabled: _hasRealLocation,
                                  myLocationButtonEnabled: false,
                                  zoomControlsEnabled: false,
                                ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Center(
                        child: Text(
                          'YOUR LOCATION',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                            color: AppColors.slate,
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        'Other Emergency Contacts',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.heading,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: _ContactPill(
                              icon: Icons.local_police_outlined,
                              label: 'Police (117)',
                              onTap: () => _callContact('Police', '117'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _ContactPill(
                              icon: Icons.medical_services_outlined,
                              label: 'Ambulance (119)',
                              onTap: () => _callContact('Ambulance', '119'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _EmergencyHeader extends StatelessWidget {
  const _EmergencyHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      color: const Color(0xFFFEF2F2),
      child: Row(
        children: <Widget>[
          const Icon(Icons.warning_amber_rounded, color: AppColors.emergencyRed, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'EMERGENCY HELP',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.emergencyRed,
                  ),
                ),
                Text(
                  'SOUTH-WEST CAMEROON REGION',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: AppColors.emergencyRed.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShareLocationCard extends StatelessWidget {
  const _ShareLocationCard({
    required this.onTap,
    required this.isBusy,
    required this.hasRealLocation,
  });

  final VoidCallback onTap;
  final bool isBusy;
  final bool hasRealLocation;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primaryBlue,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: isBusy ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
          child: Column(
            children: <Widget>[
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: isBusy
                    ? const Padding(
                        padding: EdgeInsets.all(13),
                        child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                      )
                    : const Icon(Icons.my_location, color: Colors.white, size: 22),
              ),
              const SizedBox(height: 10),
              const Text(
                'SHARE MY LOCATION',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                hasRealLocation
                    ? 'Using your current location'
                    : 'Location unavailable — using an approximate area',
                style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.85)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NearestWorkshopRow extends StatelessWidget {
  const _NearestWorkshopRow({
    required this.workshop,
    required this.urgent,
    required this.onCall,
  });

  final Workshop workshop;
  final bool urgent;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) {
    final Color callColor = urgent ? AppColors.emergencyRed : AppColors.primaryBlue;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    if (workshop.isOpenNow)
                      Container(
                        width: 7,
                        height: 7,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                    Flexible(
                      child: Text(
                        workshop.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.heading,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  workshop.distanceLabel,
                  style: const TextStyle(fontSize: 12, color: AppColors.slate),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Material(
            color: callColor,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: onCall,
              borderRadius: BorderRadius.circular(10),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(Icons.call, size: 15, color: Colors.white),
                    SizedBox(width: 6),
                    Text(
                      'CALL',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactPill extends StatelessWidget {
  const _ContactPill({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.badgeSoft,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(icon, size: 16, color: AppColors.primaryBlue),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryBlue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
