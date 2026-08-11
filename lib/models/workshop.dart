import 'package:flutter/material.dart';

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
    required this.pinAlignment,
    this.reviewCount,
    this.address,
    this.openingHours,
  });

  final String name;
  final String town;
  final double distanceKm;
  final double rating;
  final List<String> services;
  final bool isOpenNow;
  final String phone;

  /// Where this workshop's pin sits on the stylized map surfaces.
  final Alignment pinAlignment;

  final int? reviewCount;
  final String? address;
  final String? openingHours;

  String get distanceLabel => distanceKm < 1
      ? '${(distanceKm * 1000).round()}m away'
      : '${distanceKm.toStringAsFixed(1)}km away';
}

const List<Workshop> sampleWorkshops = <Workshop>[
  Workshop(
    name: 'Buea Central Mechanics',
    town: 'Buea',
    distanceKm: 0.5,
    rating: 4.8,
    reviewCount: 124,
    services: <String>['Tire Service', 'Battery Jump', 'Oil Change', 'Brake Repair', 'Diagnostics'],
    isOpenNow: true,
    phone: '+237670000001',
    pinAlignment: Alignment(-0.3, -0.2),
    address: 'Molyko, Opposite University, Buea, South-West Cameroon',
    openingHours: 'Mon - Fri: 08:00 - 18:00\nSaturday: 09:00 - 15:00',
  ),
  Workshop(
    name: 'Mount Fako Mechanics',
    town: 'Buea',
    distanceKm: 1.2,
    rating: 4.5,
    services: <String>['Engine', 'Suspension'],
    isOpenNow: true,
    phone: '+237670000002',
    pinAlignment: Alignment(0.4, 0.1),
  ),
  Workshop(
    name: 'Molyko Quick Fix',
    town: 'Buea',
    distanceKm: 0.8,
    rating: 4.8,
    services: <String>['Engine', 'Tires', 'Brakes'],
    isOpenNow: true,
    phone: '+237670000003',
    pinAlignment: Alignment(-0.1, 0.35),
  ),
  Workshop(
    name: 'Limbe Central Garage',
    town: 'Limbe',
    distanceKm: 2.4,
    rating: 4.5,
    services: <String>['Electrical', 'AC Repair', 'Battery'],
    isOpenNow: false,
    phone: '+237670000004',
    pinAlignment: Alignment(0.7, -0.4),
  ),
  Workshop(
    name: 'Kumba Expert Auto',
    town: 'Kumba',
    distanceKm: 5.1,
    rating: 4.2,
    services: <String>['Bodywork', 'Paint'],
    isOpenNow: true,
    phone: '+237670000005',
    pinAlignment: Alignment(-0.7, 0.5),
  ),
];

/// Nearest-to-you list used by the Emergency SOS screen — a different cut
/// of the same directory, ranked purely by distance.
const List<Workshop> emergencyNearestWorkshops = <Workshop>[
  Workshop(
    name: "Musa's Auto Repair",
    town: 'Buea',
    distanceKm: 0.8,
    rating: 4.6,
    services: <String>['Towing', 'Engine'],
    isOpenNow: true,
    phone: '+237670000006',
    pinAlignment: Alignment(-0.2, -0.1),
  ),
  Workshop(
    name: 'Kumba Road Rescue',
    town: 'Kumba',
    distanceKm: 1.5,
    rating: 4.3,
    services: <String>['Towing'],
    isOpenNow: true,
    phone: '+237670000007',
    pinAlignment: Alignment(0.3, 0.2),
  ),
  Workshop(
    name: 'Limbe Central Garage',
    town: 'Limbe',
    distanceKm: 3.2,
    rating: 4.5,
    services: <String>['Electrical', 'Battery'],
    isOpenNow: true,
    phone: '+237670000004',
    pinAlignment: Alignment(0.6, -0.3),
  ),
];
