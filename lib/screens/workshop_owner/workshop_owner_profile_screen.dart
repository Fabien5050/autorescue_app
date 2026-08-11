import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../models/day_hours.dart';
import '../../models/workshop_owner_profile.dart';
import '../../models/workshop_photo.dart';
import '../../models/workshop_service.dart';
import '../../widgets/availability_status_pill.dart';
import '../../widgets/photo_grid_tile.dart';
import '../../widgets/rating_badge.dart';
import 'edit_workshop_screen.dart';
import 'workshop_gallery_screen.dart';

/// "Profile" tab — read-only view of the workshop's public profile, with
/// an "Edit Profile" entry point into [EditWorkshopScreen]. Mirrors the
/// reference layout's "View Profile" panel using this project's palette.
class WorkshopOwnerProfileScreen extends StatefulWidget {
  const WorkshopOwnerProfileScreen({super.key});

  @override
  State<WorkshopOwnerProfileScreen> createState() => _WorkshopOwnerProfileScreenState();
}

class _WorkshopOwnerProfileScreenState extends State<WorkshopOwnerProfileScreen> {
  final WorkshopOwnerProfile _profile = demoWorkshopOwnerProfile;

  Future<void> _editProfile() async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const EditWorkshopScreen()));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            _CoverHeader(profile: _profile, onEdit: _editProfile),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          _profile.name,
                          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.primaryText),
                        ),
                      ),
                      if (_profile.isVerified) const Icon(Icons.verified, size: 18, color: AppColors.primaryBlue),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: <Widget>[
                      RatingBadge(rating: _profile.rating, reviewCount: _profile.reviewCount),
                      const SizedBox(width: 8),
                      AvailabilityStatusPill(status: _profile.availabilityStatus, dense: true),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _InfoRow(icon: Icons.place_outlined, text: _profile.address),
                  const SizedBox(height: 10),
                  _InfoRow(icon: Icons.call_outlined, text: _profile.phone),
                  const SizedBox(height: 20),
                  const Text(
                    'Operating Hours',
                    style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.primaryText),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: _profile.open24Hours
                        ? const Text('Open 24 Hours', style: TextStyle(fontSize: 13, color: AppColors.primaryText))
                        : Column(
                            children: <Widget>[
                              for (final DayHours day in _profile.operatingHours)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 3),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      Text(day.day, style: const TextStyle(fontSize: 12.5, color: AppColors.primaryText)),
                                      Text(day.label(context), style: const TextStyle(fontSize: 12.5, color: AppColors.secondaryText)),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Services Offered',
                    style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.primaryText),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      for (final WorkshopService service in _profile.services)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: service.available ? AppColors.badgeSoft : AppColors.background,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            service.name,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: service.available ? AppColors.primaryBlue : AppColors.secondaryText,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      const Text(
                        'Photo Gallery',
                        style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.primaryText),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(builder: (_) => const WorkshopGalleryScreen()),
                        ),
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 84,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _profile.photos.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (BuildContext context, int index) {
                        final WorkshopPhotoItem photo = _profile.photos[index];
                        return SizedBox(
                          width: 84,
                          child: PhotoGridTile(photo: photo, onTap: () {}, onDelete: () {}),
                        );
                      },
                    ),
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

class _CoverHeader extends StatelessWidget {
  const _CoverHeader({required this.profile, required this.onEdit});

  final WorkshopOwnerProfile profile;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[AppColors.primaryBlue, AppColors.secondaryCyan],
              ),
            ),
            child: Center(child: Icon(Icons.storefront, size: 64, color: Colors.white24)),
          ),
          Positioned(
            right: 14,
            bottom: 14,
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                onTap: onEdit,
                borderRadius: BorderRadius.circular(20),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(Icons.edit_outlined, size: 15, color: AppColors.primaryBlue),
                      SizedBox(width: 6),
                      Text('Edit Profile', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.primaryBlue)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, size: 17, color: AppColors.secondaryCyan),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 12.5, height: 1.4, color: AppColors.secondaryText))),
      ],
    );
  }
}
