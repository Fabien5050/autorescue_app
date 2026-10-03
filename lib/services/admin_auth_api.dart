import '../core/api_client.dart';
import '../core/session.dart';

/// Calls the backend's `/api/admin/auth/**` two-step login endpoints.
/// Forgot/reset-password for admins reuses [AuthApi] directly — that flow
/// is role-agnostic on the backend, so there's nothing admin-specific to
/// wrap here.
class AdminAuthApi {
  AdminAuthApi._();

  /// Step 1 — checks the password and (on success) emails a 6-digit code.
  /// Doesn't touch [Session]; that only happens once [verifyOtp] succeeds.
  static Future<String> login({
    required String email,
    required String password,
  }) async {
    final dynamic json = await ApiClient.post('/api/admin/auth/login', <String, dynamic>{
      'email': email,
      'password': password,
    });
    return (json as Map<String, dynamic>)['message'] as String;
  }

  static Future<String> resendOtp(String email) async {
    final dynamic json = await ApiClient.post('/api/admin/auth/resend-otp', <String, dynamic>{
      'email': email,
    });
    return (json as Map<String, dynamic>)['message'] as String;
  }

  /// Step 2 — on success, populates [Session] the same way a regular login
  /// would, with `role == 'ADMIN'`.
  static Future<void> verifyOtp({
    required String email,
    required String code,
  }) async {
    final dynamic json = await ApiClient.post('/api/admin/auth/verify-otp', <String, dynamic>{
      'email': email,
      'code': code,
    });
    final Map<String, dynamic> map = json as Map<String, dynamic>;
    final dynamic rawUserId = map['userId'];
    final dynamic rawWorkshopId = map['workshopId'];

    final int userId = rawUserId is num ? rawUserId.toInt() : int.parse(rawUserId.toString());
    final int? workshopId = rawWorkshopId == null
        ? null
        : (rawWorkshopId is num ? rawWorkshopId.toInt() : int.tryParse(rawWorkshopId.toString()));

    Session.instance.update(
      token: map['token'].toString(),
      userId: userId,
      fullName: map['fullName']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      role: map['role']?.toString() ?? '',
      workshopId: workshopId,
    );
  }
}
