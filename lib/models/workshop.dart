import 'dart:math' as math;

import 'workshop_photo.dart';

/// A certified workshop as shown across the driver dashboard's map, list,
/// profile, and SOS screens.
class Workshop {
  const Workshop({
    required this.name,
    required this.town,
    required this.distanceKm,
    required this.rating,
    required this.services,
    required this.isOpenNow,
    required this.phone,
    this.id,
    this.latitude,
    this.longitude,
    this.reviewCount,
    this.address,
    this.openingHours,
    this.photos = const <WorkshopPhotoItem>[],
  });

  /// Backend workshop id — populated when built from a real
  /// `GET /api/workshops` response.
  final int? id;

  final String name;
  final String town;
  final double distanceKm;
  final double rating;
  final List<String> services;
  final bool isOpenNow;
  final String phone;

  /// Null only if the backend hasn't had a location set for this workshop
  /// yet — real workshops always have one once registered.
  final double? latitude;
  final double? longitude;

  final int? reviewCount;
  final String? address;
  final String? openingHours;

  /// Only populated when built from `GET /api/workshops/{id}` (the driver's
  /// workshop-detail view) — the list/nearby endpoints don't include the
  /// full photo gallery.
  final List<WorkshopPhotoItem> photos;

  String get distanceLabel => distanceKm < 1
      ? '${(distanceKm * 1000).round()}m away'
      : '${distanceKm.toStringAsFixed(1)}km away';

  /// Builds a [Workshop] from a `WorkshopResponse` JSON body, computing
  /// distance client-side (the backend doesn't return one) via the
  /// haversine formula against the caller's current coordinates.
  factory Workshop.fromJson(
    Map<String, dynamic> json, {
    required double fromLatitude,
    required double fromLongitude,
  }) {
    final double? lat = (json['latitude'] as num?)?.toDouble();
    final double? lng = (json['longitude'] as num?)?.toDouble();
    return Workshop(
      id: json['id'] as int,
      name: json['name'] as String,
      town: (json['address'] as String?) ?? '',
      distanceKm: lat == null || lng == null
          ? 0
          : _haversineKm(fromLatitude, fromLongitude, lat, lng),
      latitude: lat,
      longitude: lng,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: json['reviewCount'] as int?,
      services: (json['services'] as List<dynamic>? ?? <dynamic>[])
          .map((dynamic e) => (e as Map<String, dynamic>)['name'] as String)
          .toList(),
      isOpenNow: json['availabilityStatus'] == 'AVAILABLE',
      phone: (json['phone'] as String?) ?? '',
      address: json['address'] as String?,
      photos: (json['photos'] as List<dynamic>? ?? <dynamic>[])
          .map((dynamic e) => WorkshopPhotoItem.fromJson(e as Map<String, dynamic>))
          .where((WorkshopPhotoItem p) => p.photoUrl != null)
          .toList(),
    );
  }
}

double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
  const double earthRadiusKm = 6371;
  final double dLat = _degToRad(lat2 - lat1);
  final double dLon = _degToRad(lon2 - lon1);
  final double a =
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_degToRad(lat1)) *
          math.cos(_degToRad(lat2)) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);
  final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return earthRadiusKm * c;
}

double _degToRad(double deg) => deg * (math.pi / 180);
