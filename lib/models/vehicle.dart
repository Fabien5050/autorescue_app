/// A driver's registered vehicle, mirroring the backend's
/// `VehicleResponse`. Created once at registration; this is the only view
/// into it afterward.
class Vehicle {
  const Vehicle({
    required this.id,
    required this.category,
    required this.makeModel,
    required this.licensePlate,
    required this.color,
  });

  final int id;
  final String category;
  final String makeModel;
  final String licensePlate;
  final String color;

  factory Vehicle.fromJson(Map<String, dynamic> json) => Vehicle(
    id: json['id'] as int,
    category: json['category'] as String,
    makeModel: json['makeModel'] as String,
    licensePlate: json['licensePlate'] as String,
    color: json['color'] as String,
  );
}

/// Same options offered at driver registration — kept here too so the edit
/// screen's dropdown always matches a value the vehicle could actually have
/// been registered with.
const List<String> vehicleCategories = <String>[
  'Sedan',
  'SUV',
  'Hatchback',
  'Pickup Truck',
  'Motorcycle',
  'Van',
];
