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
