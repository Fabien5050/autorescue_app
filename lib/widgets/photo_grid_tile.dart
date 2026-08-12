import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../models/workshop_photo.dart';

/// One square in the workshop photo gallery grid. Shows the picked image
/// (with a delete overlay) or, when empty, an upload placeholder for its
/// category that opens the picker on tap.
class PhotoGridTile extends StatelessWidget {
  const PhotoGridTile({
    super.key,
    required this.photo,
    required this.onTap,
    required this.onDelete,
  });

  final WorkshopPhotoItem photo;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final bool hasImage = photo.bytes != null || photo.fullPhotoUrl != null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Material(
        color: AppColors.background,
        child: InkWell(
          onTap: onTap,
          child: AspectRatio(
            aspectRatio: 1,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                if (photo.bytes != null)
                  Image.memory(photo.bytes!, fit: BoxFit.cover)
                else if (photo.fullPhotoUrl != null)
                  Image.network(photo.fullPhotoUrl!, fit: BoxFit.cover)
                else
                  DecoratedBox(
                    decoration: BoxDecoration(border: Border.all(color: AppColors.border)),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        const Icon(Icons.add_photo_alternate_outlined, color: AppColors.secondaryText, size: 26),
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            photo.category,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 11, color: AppColors.secondaryText),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (hasImage)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Material(
                      color: Colors.black.withValues(alpha: 0.45),
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: onDelete,
                        customBorder: const CircleBorder(),
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(Icons.close, size: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                if (hasImage)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      color: Colors.black.withValues(alpha: 0.45),
                      child: Text(
                        photo.category,
                        style: const TextStyle(fontSize: 10.5, color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The trailing "+ Add Photo" tile, visually distinct from category slots.
class AddPhotoTile extends StatelessWidget {
  const AddPhotoTile({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Material(
        color: AppColors.badgeSoft,
        child: InkWell(
          onTap: onTap,
          child: const AspectRatio(
            aspectRatio: 1,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(Icons.add_circle_outline, color: AppColors.primaryBlue, size: 26),
                SizedBox(height: 6),
                Text(
                  'Add Photo',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryBlue),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
