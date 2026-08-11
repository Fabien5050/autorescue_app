import 'package:flutter/material.dart';

/// A single service offered by a workshop, as managed on the owner side.
class WorkshopService {
  WorkshopService({
    required this.name,
    required this.description,
    required this.icon,
    this.price,
    this.available = true,
  });

  final String name;
  String description;
  final IconData icon;
  String? price;
  bool available;
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
