import 'package:flutter/material.dart';

import '../core/app_colors.dart';

/// Small "★ 4.8" pill used on workshop cards and profile headers.
class RatingBadge extends StatelessWidget {
  const RatingBadge({super.key, required this.rating, this.reviewCount});

  final double rating;
  final int? reviewCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.badgeSoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF59E0B)),
          const SizedBox(width: 3),
          Text(
            reviewCount != null
                ? '${rating.toStringAsFixed(1)} ($reviewCount)'
                : rating.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.heading,
            ),
          ),
        ],
      ),
    );
  }
}

/// Generic soft pill for tags like "Nearby", "Towing", "OPEN NOW".
class TagPill extends StatelessWidget {
  const TagPill({
    super.key,
    required this.label,
    this.color = AppColors.primaryBlue,
    this.filled = false,
  });

  final String label;
  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: filled ? color : AppColors.badgeSoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: filled ? Colors.white : color,
        ),
      ),
    );
  }
}
