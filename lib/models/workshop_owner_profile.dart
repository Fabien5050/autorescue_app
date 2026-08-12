import 'day_hours.dart';
import 'workshop_availability_status.dart';
import 'workshop_photo.dart';
import 'workshop_service.dart';

/// Full profile for the signed-in workshop owner — this is the mutable,
/// owner-editable counterpart to the read-only [Workshop] shown to drivers.
///
/// Held as a single in-memory instance for this demo build; nothing here
/// is persisted or synced to a backend yet.
class WorkshopOwnerProfile {
  WorkshopOwnerProfile({
    this.id,
    required this.name,
    required this.ownerName,
    required this.description,
    required this.phone,
    required this.whatsapp,
    required this.emergencyContact,
    required this.email,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.rating,
    required this.reviewCount,
    required this.isVerified,
    required this.availabilityStatus,
    required this.activeForRequests,
    required this.services,
    required this.operatingHours,
    required this.open24Hours,
    required this.photos,
  });

  int? id;
  String name;
  String ownerName;
  String description;
  String phone;
  String whatsapp;
  String emergencyContact;
  String email;
  String address;
  double latitude;
  double longitude;
  double rating;
  int reviewCount;
  bool isVerified;
  WorkshopAvailabilityStatus availabilityStatus;
  bool activeForRequests;
  List<WorkshopService> services;
  List<DayHours> operatingHours;
  bool open24Hours;
  List<WorkshopPhotoItem> photos;

  /// Overwrites every field in place from a `GET /api/workshops/me`
  /// response, so every screen already holding a reference to this
  /// singleton sees the refreshed data without re-fetching themselves.
  /// [ownerEmail] comes from the session, not the workshop response —
  /// there's no backend field/endpoint for editing it.
  void applyFromJson(Map<String, dynamic> json, {required String ownerEmail}) {
    id = json['id'] as int;
    name = json['name'] as String;
    ownerName = (json['ownerName'] as String?) ?? ownerName;
    description = (json['description'] as String?) ?? '';
    phone = (json['phone'] as String?) ?? '';
    whatsapp = (json['whatsapp'] as String?) ?? '';
    emergencyContact = (json['emergencyContact'] as String?) ?? '';
    email = ownerEmail;
    address = (json['address'] as String?) ?? '';
    latitude = (json['latitude'] as num?)?.toDouble() ?? 0;
    longitude = (json['longitude'] as num?)?.toDouble() ?? 0;
    rating = (json['rating'] as num?)?.toDouble() ?? 0;
    reviewCount = json['reviewCount'] as int? ?? 0;
    isVerified = json['verificationStatus'] == 'APPROVED';
    availabilityStatus = WorkshopAvailabilityStatus.values.firstWhere(
      (WorkshopAvailabilityStatus s) =>
          s.name.toUpperCase() == json['availabilityStatus'],
      orElse: () => WorkshopAvailabilityStatus.closed,
    );
    activeForRequests = json['activeForRequests'] as bool? ?? false;
    open24Hours = json['open24Hours'] as bool? ?? false;
    services = (json['services'] as List<dynamic>? ?? <dynamic>[])
        .map((dynamic e) => WorkshopService.fromJson(e as Map<String, dynamic>))
        .toList();
    operatingHours = DayHours.listFromJson(json['operatingHours'] as List<dynamic>? ?? <dynamic>[]);
    photos = (json['photos'] as List<dynamic>? ?? <dynamic>[])
        .map((dynamic e) => WorkshopPhotoItem.fromJson(e as Map<String, dynamic>))
        .toList();
    for (final String category in defaultPhotoCategories) {
      if (!photos.any((WorkshopPhotoItem p) => p.category == category)) {
        photos.add(WorkshopPhotoItem(category: category));
      }
    }
  }
}

/// Singleton demo profile shared by every workshop-owner screen in this
/// build — a clearly-labeled placeholder, not a real business.
final WorkshopOwnerProfile demoWorkshopOwnerProfile = WorkshopOwnerProfile(
  name: 'Buea Demo Auto Workshop',
  ownerName: 'Samuel Etonde',
  description:
      'Full-service auto repair garage serving Molyko and the University '
      'of Buea area. Specializing in engine diagnostics and roadside '
      'assistance.',
  phone: '+237 670 000 001',
  whatsapp: '+237 670 000 001',
  emergencyContact: '+237 670 000 099',
  email: 'demo.workshop@example.com',
  address: 'Molyko, Opposite University, Buea, South-West Cameroon',
  latitude: 4.1550,
  longitude: 9.2415,
  rating: 4.8,
  reviewCount: 124,
  isVerified: true,
  availabilityStatus: WorkshopAvailabilityStatus.available,
  activeForRequests: true,
  services: demoWorkshopServices(),
  operatingHours: demoWeeklyHours(),
  open24Hours: false,
  photos: demoWorkshopPhotos(),
);
