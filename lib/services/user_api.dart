import '../core/api_client.dart';
import '../models/user_profile.dart';

class UserApi {
  UserApi._();

  static Future<UserProfile> getMe() async {
    final dynamic json = await ApiClient.get('/api/users/me');
    return UserProfile.fromJson(json as Map<String, dynamic>);
  }

  static Future<UserProfile> updateProfile({
    required String fullName,
    required String phoneNumber,
  }) async {
    final dynamic json = await ApiClient.put('/api/users/me', <String, dynamic>{
      'fullName': fullName,
      'phoneNumber': phoneNumber,
    });
    return UserProfile.fromJson(json as Map<String, dynamic>);
  }

  static Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await ApiClient.put('/api/users/me/password', <String, dynamic>{
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }

  static Future<UserProfile> uploadProfilePhoto({
    required List<int> fileBytes,
    required String fileName,
  }) async {
    final dynamic json = await ApiClient.postMultipart(
      '/api/users/me/photo',
      fields: const <String, String>{},
      fileBytes: fileBytes,
      fileName: fileName,
    );
    return UserProfile.fromJson(json as Map<String, dynamic>);
  }
}
