import 'dart:typed_data';

/// A single slot in the workshop photo gallery. [bytes] is null until the
/// owner picks an image for that slot.
class WorkshopPhotoItem {
  WorkshopPhotoItem({required this.category, this.bytes});

  final String category;
  Uint8List? bytes;
}

/// Starter gallery slots for "Buea Demo Auto Workshop".
List<WorkshopPhotoItem> demoWorkshopPhotos() => <WorkshopPhotoItem>[
      WorkshopPhotoItem(category: 'Workshop Exterior'),
      WorkshopPhotoItem(category: 'Workshop Interior'),
      WorkshopPhotoItem(category: 'Equipment'),
      WorkshopPhotoItem(category: 'Mechanics'),
    ];
