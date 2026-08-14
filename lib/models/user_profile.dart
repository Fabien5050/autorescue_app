import '../core/api_config.dart';

/// The signed-in user's own account info, mirroring the backend's
/// `UserResponse`.
class UserProfile {
  const UserProfile({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.role,
    this.profilePhotoUrl,
    required this.createdAt,
  });

  final int id;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String role;
  final String? profilePhotoUrl;
  final DateTime createdAt;

  String? get fullProfilePhotoUrl => ApiConfig.resolveFileUrl(profilePhotoUrl);

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: json['id'] as int,
    fullName: json['fullName'] as String,
    email: json['email'] as String,
    phoneNumber: json['phoneNumber'] as String,
    role: json['role'] as String,
    profilePhotoUrl: json['profilePhotoUrl'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}
