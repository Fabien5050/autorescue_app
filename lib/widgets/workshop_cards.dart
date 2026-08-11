import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../models/workshop.dart';
import 'rating_badge.dart';

/// Small square placeholder thumbnail — no bundled workshop photos, so a
/// tinted icon tile stands in for one.
class _Thumbnail extends StatelessWidget {
  const _Thumbnail();

  static const double _size = 52;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        color: AppColors.badgeSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.storefront_outlined, color: AppColors.primaryBlue),
    );
  }
}

/// Compact card used in the map screen's "Workshops Near You" sheet.
class WorkshopMiniCard extends StatelessWidget {
  const WorkshopMiniCard({super.key, required this.workshop, required this.onTap});

  final Workshop workshop;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: <Widget>[
              const _Thumbnail(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
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
                        if (workshop.isOpenNow) ...<Widget>[
                          const SizedBox(width: 6),
                          const TagPill(
                            label: 'OPEN NOW',
                            color: AppColors.success,
                            filled: true,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '★ ${workshop.rating} · ${workshop.distanceLabel}',
                      style: const TextStyle(fontSize: 12, color: AppColors.slate),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.slateLight),
            ],
          ),
        ),
      ),
    );
  }
}

/// Rich card used on the full "Workshops Near You" list screen.
class WorkshopListCard extends StatelessWidget {
  const WorkshopListCard({
    super.key,
    required this.workshop,
    required this.onCall,
    required this.onDetails,
  });

  final Workshop workshop;
  final VoidCallback onCall;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      workshop.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.heading,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${workshop.distanceLabel} · ${workshop.town}',
                      style: const TextStyle(fontSize: 12, color: AppColors.slate),
                    ),
                  ],
                ),
              ),
              RatingBadge(rating: workshop.rating),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              for (final String service in workshop.services) TagPill(label: service),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: FilledButton.icon(
                  onPressed: onCall,
                  icon: const Icon(Icons.call, size: 16),
                  label: const Text('Call'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDetails,
                  icon: const Icon(Icons.arrow_forward, size: 15),
                  label: const Text('Details'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryBlue,
                    side: const BorderSide(color: AppColors.primaryBlue, width: 1.2),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
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
