import '../core/api_client.dart';
import '../models/assistance_request.dart';

class AssistanceRequestApi {
  AssistanceRequestApi._();

  static Future<AssistanceRequest> create({
    int? workshopId,
    String? description,
    required double driverLatitude,
    required double driverLongitude,
  }) async {
    final dynamic json = await ApiClient.post('/api/requests', <String, dynamic>{
      'workshopId': workshopId,
      'description': description,
      'driverLatitude': driverLatitude,
      'driverLongitude': driverLongitude,
    });
    return AssistanceRequest.fromJson(json as Map<String, dynamic>);
  }

  /// The signed-in driver's own requests, newest first.
  static Future<List<AssistanceRequest>> listMine() async {
    final dynamic json = await ApiClient.get('/api/requests/me');
    return (json as List<dynamic>)
        .map((dynamic e) => AssistanceRequest.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<List<AssistanceRequest>> listForMyWorkshop({
    AssistanceRequestStatus? status,
  }) async {
    final String query = status == null ? '' : '?status=${status.wireName}';
    final dynamic json = await ApiClient.get('/api/workshops/me/requests$query');
    return (json as List<dynamic>)
        .map((dynamic e) => AssistanceRequest.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<AssistanceRequest> updateStatus({
    required int requestId,
    required AssistanceRequestStatus status,
  }) async {
    final dynamic json = await ApiClient.patch(
      '/api/requests/$requestId/status',
      <String, dynamic>{'status': status.wireName},
    );
    return AssistanceRequest.fromJson(json as Map<String, dynamic>);
  }

  /// Live tracking — called periodically by the driver's app while a
  /// request is active.
  static Future<AssistanceRequest> updateLocation({
    required int requestId,
    required double driverLatitude,
    required double driverLongitude,
  }) async {
    final dynamic json = await ApiClient.patch(
      '/api/requests/$requestId/location',
      <String, dynamic>{'driverLatitude': driverLatitude, 'driverLongitude': driverLongitude},
    );
    return AssistanceRequest.fromJson(json as Map<String, dynamic>);
  }
}
