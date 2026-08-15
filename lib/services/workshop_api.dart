import '../core/api_client.dart';
import '../core/session.dart';
import '../models/day_hours.dart';
import '../models/workshop.dart';
import '../models/workshop_availability_status.dart';
import '../models/workshop_owner_profile.dart';
import '../models/workshop_photo.dart';
import '../models/workshop_service.dart';

/// The subset of `WorkshopResponse` the app currently needs client-side.
class MyWorkshopSummary {
  const MyWorkshopSummary({required this.id, required this.verificationStatus});

  final int id;
  final String verificationStatus;
}

/// Document types accepted by `POST /api/workshops/me/documents`, mirroring
/// the backend's `WorkshopDocument.DocumentType` enum.
enum WorkshopDocumentType { businessCertificate, ownerIdFront, ownerIdBack, facePhoto }

extension on WorkshopDocumentType {
  String get wireName => switch (this) {
    WorkshopDocumentType.businessCertificate => 'BUSINESS_CERTIFICATE',
    WorkshopDocumentType.ownerIdFront => 'OWNER_ID_FRONT',
    WorkshopDocumentType.ownerIdBack => 'OWNER_ID_BACK',
    WorkshopDocumentType.facePhoto => 'FACE_PHOTO',
  };
}

class WorkshopApi {
  WorkshopApi._();

  static Future<MyWorkshopSummary> getMine() async {
    final dynamic json = await ApiClient.get('/api/workshops/me');
    final Map<String, dynamic> map = json as Map<String, dynamic>;
    return MyWorkshopSummary(
      id: map['id'] as int,
      verificationStatus: map['verificationStatus'] as String,
    );
  }

  /// Fetches the signed-in owner's full workshop and overwrites
  /// [demoWorkshopOwnerProfile] in place so every screen sharing that
  /// singleton sees the refreshed data.
  static Future<void> refreshMyProfile() async {
    final dynamic json = await ApiClient.get('/api/workshops/me');
    demoWorkshopOwnerProfile.applyFromJson(
      json as Map<String, dynamic>,
      ownerEmail: Session.instance.email ?? '',
    );
  }

  static Future<void> updateProfile({
    required String name,
    required String description,
    required String phone,
    required String whatsapp,
    required String emergencyContact,
    required String address,
    double? latitude,
    double? longitude,
    required bool open24Hours,
  }) async {
    final dynamic json = await ApiClient.put('/api/workshops/me', <String, dynamic>{
      'name': name,
      'description': description,
      'phone': phone,
      'whatsapp': whatsapp,
      'emergencyContact': emergencyContact,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'open24Hours': open24Hours,
    });
    demoWorkshopOwnerProfile.applyFromJson(
      json as Map<String, dynamic>,
      ownerEmail: Session.instance.email ?? '',
    );
  }

  static Future<void> updateAvailability({
    required WorkshopAvailabilityStatus status,
    required bool activeForRequests,
  }) async {
    final dynamic json = await ApiClient.patch(
      '/api/workshops/me/availability',
      <String, dynamic>{
        'availabilityStatus': status.name.toUpperCase(),
        'activeForRequests': activeForRequests,
      },
    );
    demoWorkshopOwnerProfile.applyFromJson(
      json as Map<String, dynamic>,
      ownerEmail: Session.instance.email ?? '',
    );
  }

  static Future<WorkshopService> addService({
    required String name,
    String? description,
    String? price,
    bool available = true,
  }) async {
    final dynamic json = await ApiClient.post('/api/workshops/me/services', <String, dynamic>{
      'name': name,
      'description': description,
      'price': price,
      'available': available,
    });
    return WorkshopService.fromJson(json as Map<String, dynamic>);
  }

  static Future<WorkshopService> updateService({
    required int serviceId,
    required String name,
    String? description,
    String? price,
    bool available = true,
  }) async {
    final dynamic json = await ApiClient.put('/api/workshops/me/services/$serviceId', <String, dynamic>{
      'name': name,
      'description': description,
      'price': price,
      'available': available,
    });
    return WorkshopService.fromJson(json as Map<String, dynamic>);
  }

  static Future<void> deleteService(int serviceId) async {
    await ApiClient.delete('/api/workshops/me/services/$serviceId');
  }

  static Future<void> replaceHours(List<DayHours> hours) async {
    final dynamic json = await ApiClient.putList(
      '/api/workshops/me/hours',
      <Map<String, dynamic>>[
        for (final DayHours day in hours)
          <String, dynamic>{
            'dayOfWeek': dayOfWeekFor(day.day),
            'isOpen': day.isOpen,
            'openTime': day.isOpen ? timeOfDayToWire(day.openTime) : null,
            'closeTime': day.isOpen ? timeOfDayToWire(day.closeTime) : null,
          },
      ],
    );
    demoWorkshopOwnerProfile.applyFromJson(
      json as Map<String, dynamic>,
      ownerEmail: Session.instance.email ?? '',
    );
  }

  static Future<WorkshopPhotoItem> addPhoto({
    required String category,
    required List<int> fileBytes,
    required String fileName,
  }) async {
    final dynamic json = await ApiClient.postMultipart(
      '/api/workshops/me/photos?category=${Uri.encodeQueryComponent(category)}',
      fields: const <String, String>{},
      fileBytes: fileBytes,
      fileName: fileName,
    );
    return WorkshopPhotoItem.fromJson(json as Map<String, dynamic>);
  }

  static Future<void> deletePhoto(int photoId) async {
    await ApiClient.delete('/api/workshops/me/photos/$photoId');
  }

  /// A single workshop's full details — used by the driver to review a
  /// workshop before calling/messaging its owner on an active request.
  /// [fromLatitude]/[fromLongitude] are only for the distance label; pass
  /// the request's own driver coordinates if you have them.
  static Future<Workshop> getById(
    int id, {
    double fromLatitude = 0,
    double fromLongitude = 0,
  }) async {
    final dynamic json = await ApiClient.get('/api/workshops/$id');
    return Workshop.fromJson(
      json as Map<String, dynamic>,
      fromLatitude: fromLatitude,
      fromLongitude: fromLongitude,
    );
  }

  /// Nearby workshops for the driver-side SOS screen.
  static Future<List<Workshop>> listNearby({
    required double latitude,
    required double longitude,
    double radiusKm = 25,
  }) async {
    final dynamic json = await ApiClient.get(
      '/api/workshops?lat=$latitude&lng=$longitude&radiusKm=$radiusKm',
    );
    return (json as List<dynamic>)
        .map(
          (dynamic e) => Workshop.fromJson(
            e as Map<String, dynamic>,
            fromLatitude: latitude,
            fromLongitude: longitude,
          ),
        )
        .toList();
  }

  /// Every approved workshop, unfiltered by distance — the fallback when a
  /// nearby search comes back empty (driver in an area with no nearby
  /// coverage yet) so the list/map never just goes dead. Distances are
  /// computed against [fromLatitude]/[fromLongitude] same as [listNearby],
  /// they just aren't used to filter which workshops come back.
  static Future<List<Workshop>> listAll({
    required double fromLatitude,
    required double fromLongitude,
  }) async {
    final dynamic json = await ApiClient.get('/api/workshops');
    return (json as List<dynamic>)
        .map(
          (dynamic e) => Workshop.fromJson(
            e as Map<String, dynamic>,
            fromLatitude: fromLatitude,
            fromLongitude: fromLongitude,
          ),
        )
        .toList();
  }

  static Future<void> uploadDocument({
    required WorkshopDocumentType type,
    required List<int> fileBytes,
    required String fileName,
  }) {
    return ApiClient.postMultipart(
      '/api/workshops/me/documents?type=${type.wireName}',
      fields: const <String, String>{},
      fileBytes: fileBytes,
      fileName: fileName,
    );
  }
}
