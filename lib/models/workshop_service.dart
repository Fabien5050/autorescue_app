import 'package:flutter/material.dart';

/// A single service offered by a workshop, as managed on the owner side.
class WorkshopService {
  WorkshopService({
    this.id,
    required this.name,
    required this.description,
    required this.icon,
    this.price,
    this.available = true,
  });

  /// Backend service id — null until this service has been saved.
  int? id;
  final String name;
  String description;
  final IconData icon;
  String? price;
  bool available;

  factory WorkshopService.fromJson(Map<String, dynamic> json) {
    final String name = json['name'] as String;
    return WorkshopService(
      id: json['id'] as int?,
      name: name,
      description: (json['description'] as String?) ?? '',
      icon: _iconForServiceName(name),
      price: json['price'] as String?,
      available: json['available'] as bool? ?? true,
    );
  }
}

IconData _iconForServiceName(String name) {
  for (final (String catalogueName, IconData icon) in workshopServiceCatalogue) {
    if (catalogueName == name) return icon;
  }
  return Icons.build_outlined;
}

/// Starter demo services for "Buea Demo Auto Workshop".
List<WorkshopService> demoWorkshopServices() => <WorkshopService>[
      WorkshopService(
        name: 'Engine Repair',
        description: 'Major and minor engine repairs',
        icon: Icons.settings_outlined,
        price: 'From 15,000 FCFA',
      ),
      WorkshopService(
        name: 'Brake Repair',
        description: 'Pad replacement, brake fluid, disc servicing',
        icon: Icons.car_repair,
        price: 'From 8,000 FCFA',
      ),
      WorkshopService(
        name: 'Battery Replacement',
        description: 'Testing, charging and battery swap',
        icon: Icons.battery_charging_full,
        price: 'From 5,000 FCFA',
      ),
      WorkshopService(
        name: 'Tyre Repair',
        description: 'Puncture repair, balancing, replacement',
        icon: Icons.album,
        available: false,
      ),
    ];

/// The fixed catalogue offered when adding a new service.
const List<(String, IconData)> workshopServiceCatalogue = <(String, IconData)>[
  ('Engine Repair', Icons.settings_outlined),
  ('Brake Repair', Icons.car_repair),
  ('Electrical Repairs', Icons.electrical_services),
  ('Tyre Repair', Icons.album),
  ('Battery Replacement', Icons.battery_charging_full),
  ('Oil Change', Icons.opacity),
  ('AC Repair', Icons.ac_unit),
  ('Towing', Icons.local_shipping),
  ('Diagnostics', Icons.troubleshoot),
  ('Body Repair', Icons.build),
];
