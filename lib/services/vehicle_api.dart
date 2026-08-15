import '../core/api_client.dart';
import '../models/vehicle.dart';

class VehicleApi {
  VehicleApi._();

  static Future<Vehicle> getMine() async {
    final dynamic json = await ApiClient.get('/api/vehicles/me');
    return Vehicle.fromJson(json as Map<String, dynamic>);
  }

  static Future<Vehicle> updateMine({
    required String category,
    required String makeModel,
    required String licensePlate,
    required String color,
  }) async {
    final dynamic json = await ApiClient.put('/api/vehicles/me', <String, dynamic>{
      'category': category,
      'makeModel': makeModel,
      'licensePlate': licensePlate,
      'color': color,
    });
    return Vehicle.fromJson(json as Map<String, dynamic>);
  }
}
