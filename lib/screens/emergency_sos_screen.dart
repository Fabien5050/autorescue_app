import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/api_client.dart';
import '../core/app_colors.dart';
import '../core/location_service.dart';
import '../models/assistance_request.dart';
import '../models/call_token.dart';
import '../models/workshop.dart';
import '../services/assistance_request_api.dart';
import '../services/workshop_api.dart';
import '../widgets/open_street_map_view.dart';
import 'call_screen.dart';
import 'workshop_profile_screen.dart';

/// SOS tab: fastest path to sharing location and calling or requesting assistance
/// from a specific chosen workshop.
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
  final Set<int> _requestingWorkshopIds = <int>{};

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
    final List<Workshop> nearby = await WorkshopApi.listNearby(
      latitude: _driverLatitude,
      longitude: _driverLongitude,
    );
    if (nearby.isNotEmpty) return nearby;
    return WorkshopApi.listAll(fromLatitude: _driverLatitude, fromLongitude: _driverLongitude);
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

  Future<void> _requestAssistance(Workshop workshop, {String? description}) async {
    if (workshop.id == null) return;
    final int workshopId = workshop.id!;
    setState(() => _requestingWorkshopIds.add(workshopId));
    try {
      final AssistanceRequest request = await AssistanceRequestApi.create(
        workshopId: workshopId,
        driverLatitude: _driverLatitude,
        driverLongitude: _driverLongitude,
        description: description,
      );
      if (!mounted) return;
      _showSnack('Emergency request sent to ${workshop.name}');
      // Opens workshop detail page paired with active request ID
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => WorkshopProfileScreen(workshop: workshop, requestId: request.id),
        ),
      );
    } on ApiException catch (error) {
      if (mounted) _showSnack(error.message, isError: true);
    } finally {
      if (mounted) setState(() => _requestingWorkshopIds.remove(workshop.id));
    }
  }

  void _showRequestModal(Workshop workshop) {
    final TextEditingController descriptionController = TextEditingController();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            MediaQuery.of(sheetContext).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: <Widget>[
                  const Icon(Icons.storefront, color: AppColors.primaryBlue, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      workshop.name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.heading),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Distance: ${workshop.distanceLabel} • ${workshop.town}',
                style: const TextStyle(fontSize: 12.5, color: AppColors.slate),
              ),
              const SizedBox(height: 18),
              const Text(
                'Breakdown Description (Optional)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.heading),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                style: const TextStyle(fontSize: 13.5),
                decoration: InputDecoration(
                  hintText: 'e.g., Flat tire on highway, engine overheating, battery dead...',
                  hintStyle: const TextStyle(fontSize: 13, color: AppColors.slateLight),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    _requestAssistance(workshop, description: descriptionController.text.trim());
                  },
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: Text('Send Emergency Request to ${workshop.name}'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSelectWorkshopSheet(List<Workshop> nearby) {
    if (nearby.isEmpty) {
      _showSnack('No nearby workshops found right now.', isError: true);
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'Select Workshop to Send Request',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.heading),
              ),
              const SizedBox(height: 4),
              const Text('Choose which workshop you want to send your location to:', style: TextStyle(fontSize: 12.5, color: AppColors.slate)),
              const SizedBox(height: 14),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: nearby.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (BuildContext context, int index) {
                    final Workshop w = nearby[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppColors.border),
                      ),
                      leading: const CircleAvatar(
                        backgroundColor: AppColors.badgeSoft,
                        child: Icon(Icons.storefront, color: AppColors.primaryBlue, size: 20),
                      ),
                      title: Text(w.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      subtitle: Text('${w.distanceLabel} • ${w.town}', style: const TextStyle(fontSize: 12, color: AppColors.slate)),
                      trailing: const Icon(Icons.chevron_right, color: AppColors.primaryBlue),
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        _showRequestModal(w);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _dial(String phoneNumber, String label) async {
    final Uri uri = Uri(scheme: 'tel', path: phoneNumber);
    final bool launched = await launchUrl(uri);
    if (!launched && mounted) {
      _showSnack('Could not start a call to $label', isError: true);
    }
  }

  void _callContact(String label, String phoneNumber) => _dial(phoneNumber, label);

  void _callWorkshop(Workshop workshop) {
    final CallToken token = CallToken(
      appId: '1f10928230b3438096f4dd71a1fa9300',
      channel: 'workshop_${workshop.id}',
      token: '',
      uid: 0,
    );
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (BuildContext _) => CallScreen(
        token: token,
        otherPartyName: workshop.name,
        otherPartyPhotoUrl: workshop.photos.isNotEmpty ? workshop.photos.first.fullPhotoUrl : null,
      ),
    ));
  }

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
                        hasRealLocation: _hasRealLocation,
                        onTap: () => _showSelectWorkshopSheet(nearby),
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
                        'Select a workshop to call or send an emergency request',
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
                            isBusy: _requestingWorkshopIds.contains(nearby[i].id),
                            onCall: () => _callWorkshop(nearby[i]),
                            onRequest: () => _showSelectWorkshopSheet(nearby),
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
                              : OpenStreetMapView(
                                  center: LatLng(_driverLatitude, _driverLongitude),
                                  zoom: 15,
                                  markers: <Marker>[
                                    if (_hasRealLocation)
                                      Marker(
                                        point: LatLng(_driverLatitude, _driverLongitude),
                                        width: 32,
                                        height: 32,
                                        child: const Icon(
                                          Icons.my_location,
                                          color: AppColors.primaryBlue,
                                          size: 28,
                                        ),
                                      ),
                                    for (final Workshop w in nearby)
                                      if (w.latitude != null && w.longitude != null)
                                        Marker(
                                          point: LatLng(w.latitude!, w.longitude!),
                                          width: 140,
                                          height: 60,
                                          child: GestureDetector(
                                            onTap: () => _callWorkshop(w),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: <Widget>[
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.navy,
                                                    borderRadius: BorderRadius.circular(6),
                                                    boxShadow: <BoxShadow>[
                                                      BoxShadow(
                                                        color: Colors.black.withValues(alpha: 0.25),
                                                        blurRadius: 6,
                                                        offset: const Offset(0, 2),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Text(
                                                    w.name,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 10.5,
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                                const Icon(
                                                  Icons.location_on,
                                                  color: AppColors.burntOrange,
                                                  size: 32,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                  ],
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
      child: const Row(
        children: <Widget>[
          Icon(Icons.warning_amber_rounded, color: AppColors.emergencyRed, size: 22),
          SizedBox(width: 10),
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
                    color: AppColors.emergencyRed,
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
    required this.hasRealLocation,
  });

  final VoidCallback onTap;
  final bool hasRealLocation;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primaryBlue,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            children: <Widget>[
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.my_location, color: Colors.white, size: 22),
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
                    ? 'Tap to select a nearby workshop and send emergency alert'
                    : 'Location unavailable — tap to select workshop',
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
    required this.onRequest,
    this.isBusy = false,
  });

  final Workshop workshop;
  final bool urgent;
  final VoidCallback onCall;
  final VoidCallback onRequest;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
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
              Expanded(
                child: Text(
                  workshop.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.heading,
                  ),
                ),
              ),
              Text(
                workshop.distanceLabel,
                style: const TextStyle(fontSize: 12, color: AppColors.slate, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onCall,
                  icon: const Icon(Icons.call, size: 15),
                  label: const Text('CALL'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryBlue,
                    side: const BorderSide(color: AppColors.primaryBlue),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: isBusy ? null : onRequest,
                  icon: isBusy
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send_rounded, size: 15),
                  label: Text(isBusy ? 'Sending…' : 'REQUEST'),
                  style: FilledButton.styleFrom(
                    backgroundColor: urgent ? AppColors.emergencyRed : AppColors.primaryBlue,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
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
