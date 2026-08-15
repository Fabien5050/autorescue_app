import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../core/app_colors.dart';
import '../models/workshop.dart';
import '../models/workshop_photo.dart';
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
                if (workshop.photos.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 20),
                  const Text(
                    'Photos',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.heading,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _PhotoGallery(photos: workshop.photos),
                ],
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
    final String? coverUrl = workshop.photos.isEmpty ? null : workshop.photos.first.fullPhotoUrl;
    return SizedBox(
      height: 220,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          if (coverUrl != null)
            Image.network(
              coverUrl,
              fit: BoxFit.cover,
              errorBuilder: (BuildContext _, Object _, StackTrace? _) => const _HeroFallback(),
            )
          else
            const _HeroFallback(),
          // Darkens the photo enough that the back/share/favorite buttons
          // stay legible over whatever's underneath.
          if (coverUrl != null)
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[Colors.black45, Colors.transparent],
                  stops: <double>[0, 0.4],
                ),
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

class _HeroFallback extends StatelessWidget {
  const _HeroFallback();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[AppColors.navy, Color(0xFF1E3A5F)],
        ),
      ),
      child: Center(
        child: Icon(Icons.directions_car_filled, size: 90, color: Colors.white24),
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

/// Horizontal scroll strip of the workshop's uploaded photos — tapping one
/// opens it full-screen with swipe-between-photos navigation.
class _PhotoGallery extends StatelessWidget {
  const _PhotoGallery({required this.photos});

  final List<WorkshopPhotoItem> photos;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: photos.length,
        separatorBuilder: (BuildContext _, int _) => const SizedBox(width: 10),
        itemBuilder: (BuildContext context, int index) {
          final String? url = photos[index].fullPhotoUrl;
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: url == null
                  ? null
                  : () => Navigator.of(context).push(MaterialPageRoute<void>(
                        builder: (BuildContext _) => _PhotoViewer(photos: photos, initialIndex: index),
                      )),
              child: SizedBox(
                width: 96,
                height: 96,
                child: url == null
                    ? const ColoredBox(color: AppColors.badgeSoft)
                    : Image.network(
                        url,
                        fit: BoxFit.cover,
                        errorBuilder: (BuildContext _, Object _, StackTrace? _) =>
                            const ColoredBox(color: AppColors.badgeSoft),
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Full-screen, swipeable photo viewer opened from [_PhotoGallery].
class _PhotoViewer extends StatefulWidget {
  const _PhotoViewer({required this.photos, required this.initialIndex});

  final List<WorkshopPhotoItem> photos;
  final int initialIndex;

  @override
  State<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<_PhotoViewer> {
  late final PageController _controller = PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text('${_index + 1} / ${widget.photos.length}'),
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.photos.length,
        onPageChanged: (int i) => setState(() => _index = i),
        itemBuilder: (BuildContext context, int index) {
          final String? url = widget.photos[index].fullPhotoUrl;
          return Center(
            child: InteractiveViewer(
              child: url == null
                  ? const Icon(Icons.broken_image_outlined, color: Colors.white38, size: 64)
                  : Image.network(
                      url,
                      errorBuilder: (BuildContext _, Object _, StackTrace? _) =>
                          const Icon(Icons.broken_image_outlined, color: Colors.white38, size: 64),
                    ),
            ),
          );
        },
      ),
    );
  }
}
