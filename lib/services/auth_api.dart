import '../core/api_client.dart';
import '../core/session.dart';

class DriverVehicleInput {
  const DriverVehicleInput({
    required this.category,
    required this.makeModel,
    required this.licensePlate,
    required this.color,
  });

  final String category;
  final String makeModel;
  final String licensePlate;
  final String color;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'category': category,
    'makeModel': makeModel,
    'licensePlate': licensePlate,
    'color': color,
  };
}

class EmergencyContactInput {
  const EmergencyContactInput({
    required this.contactName,
    required this.contactPhone,
  });

  final String contactName;
  final String contactPhone;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'contactName': contactName,
    'contactPhone': contactPhone,
  };
}

/// Calls the backend's `/api/auth/**` endpoints and populates [Session]
/// with the returned token on success.
class AuthApi {
  AuthApi._();

  static Future<void> login({
    required String email,
    required String password,
  }) async {
    final dynamic json = await ApiClient.post('/api/auth/login', <String, dynamic>{
      'email': email,
      'password': password,
    });
    _applySession(json as Map<String, dynamic>);
  }

  static Future<void> registerDriver({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    required DriverVehicleInput vehicle,
    required EmergencyContactInput emergencyContact,
  }) async {
    final dynamic json = await ApiClient.post(
      '/api/auth/register/driver',
      <String, dynamic>{
        'fullName': fullName,
        'email': email,
        'phoneNumber': phoneNumber,
        'password': password,
        'vehicle': vehicle.toJson(),
        'emergencyContact': emergencyContact.toJson(),
      },
    );
    _applySession(json as Map<String, dynamic>);
  }

  static Future<void> registerWorkshop({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    required String workshopName,
    String? nationalIdNumber,
    String? taxIdNumber,
    required String address,
    double? latitude,
    double? longitude,
    required List<String> services,
  }) async {
    final dynamic json = await ApiClient.post(
      '/api/auth/register/workshop',
      <String, dynamic>{
        'fullName': fullName,
        'email': email,
        'phoneNumber': phoneNumber,
        'password': password,
        'workshopName': workshopName,
        'nationalIdNumber': nationalIdNumber,
        'taxIdNumber': taxIdNumber,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'services': services,
      },
    );
    _applySession(json as Map<String, dynamic>);
  }

  static Future<String> forgotPassword(String email) async {
    final dynamic json = await ApiClient.post('/api/auth/forgot-password', <String, dynamic>{
      'email': email,
    });
    return (json as Map<String, dynamic>)['message'] as String;
  }

  static Future<String> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    final dynamic json = await ApiClient.post('/api/auth/reset-password', <String, dynamic>{
      'token': token,
      'newPassword': newPassword,
    });
    return (json as Map<String, dynamic>)['message'] as String;
  }

  static void _applySession(Map<String, dynamic> json) {
    Session.instance.update(
      token: json['token'] as String,
      userId: json['userId'] as int,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      workshopId: json['workshopId'] as int?,
    );
  }
}
