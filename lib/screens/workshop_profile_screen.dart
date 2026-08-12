import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../core/app_colors.dart';
import '../models/workshop.dart';
import '../widgets/rating_badge.dart';

IconData _iconForService(String service) {
  final String s = service.toLowerCase();
  if (s.contains('tire')) return Icons.album;
  if (s.contains('battery')) return Icons.battery_charging_full;
  if (s.contains('oil')) return Icons.opacity;
  if (s.contains('brake')) return Icons.car_repair;
  if (s.contains('diagnostic')) return Icons.troubleshoot;
  if (s.contains('electrical')) return Icons.electrical_services;
  if (s.contains('ac')) return Icons.ac_unit;
  if (s.contains('bodywork')) return Icons.build;
  if (s.contains('paint')) return Icons.format_paint;
  if (s.contains('tow')) return Icons.local_shipping;
  if (s.contains('suspension')) return Icons.height;
  if (s.contains('engine')) return Icons.settings;
  return Icons.build_circle_outlined;
}

/// Full detail page for a single workshop, reached from the map, the
/// workshops list, or the SOS nearest-workshops list.
class WorkshopProfileScreen extends StatelessWidget {
  const WorkshopProfileScreen({super.key, required this.workshop});

  final Workshop workshop;

  void _call(BuildContext context) {
    // Hook a real tel: launcher (e.g. url_launcher) in here.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.navy,
        behavior: SnackBarBehavior.floating,
        content: Text('Calling ${workshop.name}…'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _call(context),
        backgroundColor: AppColors.primaryBlue,
        icon: const Icon(Icons.call, color: Colors.white),
        label: const Text('Call Workshop', style: TextStyle(color: Colors.white)),
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          _Hero(workshop: workshop),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 90),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        workshop.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.heading,
                        ),
                      ),
                    ),
                    if (workshop.isOpenNow)
                      const TagPill(label: 'OPEN NOW', color: AppColors.success, filled: false),
                  ],
                ),
                const SizedBox(height: 6),
                RatingBadge(rating: workshop.rating, reviewCount: workshop.reviewCount),
                const SizedBox(height: 18),
                _InfoCard(
                  icon: Icons.place_outlined,
                  title: 'Location',
                  body: workshop.address ?? '${workshop.town}, South-West Cameroon',
                ),
                const SizedBox(height: 12),
                _InfoCard(
                  icon: Icons.schedule_outlined,
                  title: 'Opening Hours',
                  body: workshop.openingHours ?? 'Mon - Sat: 08:00 - 18:00',
                ),
                const SizedBox(height: 20),
                const Text(
                  'Services Provided',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.heading,
                  ),
                ),
                const SizedBox(height: 10),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 2.6,
                  children: <Widget>[
                    for (final String service in workshop.services)
                      _ServiceTile(icon: _iconForService(service), label: service),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Location Preview',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.heading,
                  ),
                ),
                const SizedBox(height: 10),
                if (workshop.latitude != null && workshop.longitude != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      height: 160,
                      width: double.infinity,
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: LatLng(workshop.latitude!, workshop.longitude!),
                          zoom: 15,
                        ),
                        zoomControlsEnabled: false,
                        markers: <Marker>{
                          Marker(
                            markerId: const MarkerId('workshop-location'),
                            position: LatLng(workshop.latitude!, workshop.longitude!),
                          ),
                        },
                      ),
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

class _Hero extends StatelessWidget {
  const _Hero({required this.workshop});

  final Workshop workshop;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[AppColors.navy, Color(0xFF1E3A5F)],
              ),
            ),
            child: const Center(
              child: Icon(Icons.directions_car_filled, size: 90, color: Colors.white24),
            ),
          ),
          Positioned(
            top: 44,
            left: 16,
            child: _HeroIconButton(
              icon: Icons.arrow_back,
              onTap: () {
                if (Navigator.of(context).canPop()) Navigator.of(context).pop();
              },
            ),
          ),
          Positioned(
            top: 44,
            right: 16,
            child: Row(
              children: <Widget>[
                _HeroIconButton(icon: Icons.share_outlined, onTap: () {}),
                const SizedBox(width: 10),
                _HeroIconButton(icon: Icons.favorite_border, onTap: () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroIconButton extends StatelessWidget {
  const _HeroIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.35),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 19, color: AppColors.primaryBlue),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.heading,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  body,
                  style: const TextStyle(fontSize: 12.5, height: 1.4, color: AppColors.slate),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.badgeSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 18, color: AppColors.primaryBlue),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.heading,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
