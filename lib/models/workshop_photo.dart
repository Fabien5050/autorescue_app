import 'dart:typed_data';

import '../core/api_config.dart';

/// A single slot in the workshop photo gallery. [bytes] holds a
/// freshly-picked-but-not-yet-uploaded image; [photoUrl] holds a
/// previously-uploaded photo's server URL. [id] is null until persisted.
class WorkshopPhotoItem {
  WorkshopPhotoItem({required this.category, this.bytes, this.id, this.photoUrl});

  final String category;
  Uint8List? bytes;
  int? id;
  String? photoUrl;

  /// [photoUrl] is server-relative (e.g. `/uploads/workshop-photos/x.jpg`);
  /// this resolves it against the backend's base URL for `Image.network`.
  String? get fullPhotoUrl => photoUrl == null ? null : '${ApiConfig.baseUrl}$photoUrl';

  factory WorkshopPhotoItem.fromJson(Map<String, dynamic> json) => WorkshopPhotoItem(
    id: json['id'] as int?,
    category: json['category'] as String,
    photoUrl: json['photoUrl'] as String?,
  );
}

/// The backend has no notion of reserved photo categories — it's just a
/// flat list of (category, url) rows. These four are kept as always-shown
/// placeholder slots in the UI so the gallery still prompts the owner for
/// a sensible starter set of shots.
const List<String> defaultPhotoCategories = <String>[
  'Workshop Exterior',
  'Workshop Interior',
  'Equipment',
  'Mechanics',
];

/// Starter gallery slots for "Buea Demo Auto Workshop".
List<WorkshopPhotoItem> demoWorkshopPhotos() =>
    <WorkshopPhotoItem>[for (final String category in defaultPhotoCategories) WorkshopPhotoItem(category: category)];
