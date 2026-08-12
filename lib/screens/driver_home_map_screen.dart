import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../core/app_colors.dart';
import '../core/location_service.dart';
import '../models/workshop.dart';
import '../services/workshop_api.dart';
import '../widgets/workshop_cards.dart';
import 'workshop_profile_screen.dart';

const List<String> _filterCategories = <String>['Nearby', 'Towing', 'Mechanic', 'Electrician'];

/// Home tab: the live map with nearby workshops and the emergency button.
class DriverHomeMapScreen extends StatefulWidget {
  const DriverHomeMapScreen({
    super.key,
    required this.onEmergencyTap,
    required this.onViewAllWorkshops,
  });

  final VoidCallback onEmergencyTap;
  final VoidCallback onViewAllWorkshops;

  @override
  State<DriverHomeMapScreen> createState() => _DriverHomeMapScreenState();
}

class _DriverHomeMapScreenState extends State<DriverHomeMapScreen> {
  String _activeFilter = _filterCategories.first;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  List<Workshop> _workshops = <Workshop>[];
  double _myLatitude = LocationService.fallbackLatitude;
  double _myLongitude = LocationService.fallbackLongitude;
  bool _hasRealLocation = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final position = await LocationService.getCurrentPosition();
    _hasRealLocation = position != null;
    _myLatitude = position?.latitude ?? LocationService.fallbackLatitude;
    _myLongitude = position?.longitude ?? LocationService.fallbackLongitude;

    final List<Workshop> workshops = await WorkshopApi.listNearby(
      latitude: _myLatitude,
      longitude: _myLongitude,
    );
    if (!mounted) return;
    setState(() {
      _workshops = workshops;
      _loading = false;
    });
  }

  List<Workshop> get _filteredWorkshops {
    List<Workshop> result;
    if (_activeFilter == 'Nearby') {
      result = List<Workshop>.of(_workshops)
        ..sort((Workshop a, Workshop b) => a.distanceKm.compareTo(b.distanceKm));
    } else {
      result = _workshops
          .where((Workshop w) => w.services.any(
                (String s) => s.toLowerCase().contains(_activeFilter.toLowerCase()),
              ))
          .toList();
    }

    final String query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return result;
    return result.where((Workshop w) {
      return w.name.toLowerCase().contains(query) ||
          w.town.toLowerCase().contains(query) ||
          w.services.any((String s) => s.toLowerCase().contains(query));
    }).toList();
  }

  void _openWorkshop(Workshop workshop) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => WorkshopProfileScreen(workshop: workshop)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Workshop> workshops = _filteredWorkshops;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(_myLatitude, _myLongitude),
                      zoom: 13.5,
                    ),
                    myLocationEnabled: _hasRealLocation,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    markers: <Marker>{
                      for (final Workshop w in workshops)
                        if (w.latitude != null && w.longitude != null)
                          Marker(
                            markerId: MarkerId('workshop-${w.id}'),
                            position: LatLng(w.latitude!, w.longitude!),
                            infoWindow: InfoWindow(title: w.name, snippet: w.distanceLabel),
                            onTap: () => _openWorkshop(w),
                          ),
                    },
                  ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Column(
                children: <Widget>[
                  _SearchBar(
                    controller: _searchController,
                    onChanged: (String value) => setState(() => _searchQuery = value),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 34,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _filterCategories.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (BuildContext context, int index) {
                        final String category = _filterCategories[index];
                        final bool selected = category == _activeFilter;
                        return _FilterChip(
                          label: category,
                          selected: selected,
                          onTap: () => setState(() => _activeFilter = category),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 220,
            child: _EmergencyButton(onTap: widget.onEmergencyTap),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _WorkshopsSheet(
              workshops: workshops,
              onWorkshopTap: _openWorkshop,
              onViewAll: widget.onViewAllWorkshops,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      height: 46,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.search, size: 19, color: AppColors.slateLight),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: const TextStyle(fontSize: 13.5, color: AppColors.heading),
              decoration: const InputDecoration(
                hintText: 'Search for workshop...',
                hintStyle: TextStyle(fontSize: 13.5, color: AppColors.slateLight),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            InkWell(
              onTap: () {
                controller.clear();
                onChanged('');
              },
              child: const Icon(Icons.close, size: 18, color: AppColors.slateLight),
            )
          else
            const Icon(Icons.tune, size: 18, color: AppColors.primaryBlue),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primaryBlue : AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: selected ? null : Border.all(color: AppColors.border),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : AppColors.slate,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmergencyButton extends StatelessWidget {
  const _EmergencyButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.emergencyRed,
      borderRadius: BorderRadius.circular(30),
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.emergency_share, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text(
                'EMERGENCY HELP',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkshopsSheet extends StatelessWidget {
  const _WorkshopsSheet({
    required this.workshops,
    required this.onWorkshopTap,
    required this.onViewAll,
  });

  final List<Workshop> workshops;
  final ValueChanged<Workshop> onWorkshopTap;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.34,
      minChildSize: 0.2,
      maxChildSize: 0.75,
      builder: (BuildContext context, ScrollController controller) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppColors.navy.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
            children: <Widget>[
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  const Text(
                    'Workshops Near You',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.heading,
                    ),
                  ),
                  GestureDetector(
                    onTap: onViewAll,
                    child: const Text(
                      'View all',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              if (workshops.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'No workshops found for this filter.',
                    style: TextStyle(fontSize: 12.5, color: AppColors.slate),
                  ),
                )
              else
                for (final Workshop w in workshops)
                  WorkshopMiniCard(workshop: w, onTap: () => onWorkshopTap(w)),
            ],
          ),
        );
      },
    );
  }
}
