class AdminWorkshopSummary {
  const AdminWorkshopSummary({
    required this.id,
    required this.name,
    required this.address,
    required this.verificationStatus,
    required this.createdAt,
  });

  final int id;
  final String name;
  final String? address;
  final String verificationStatus;
  final DateTime createdAt;

  factory AdminWorkshopSummary.fromJson(Map<String, dynamic> json) {
    return AdminWorkshopSummary(
      id: json['id'] as int,
      name: json['name'] as String,
      address: json['address'] as String?,
      verificationStatus: json['verificationStatus'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class AdminDashboardSummary {
  const AdminDashboardSummary({
    required this.activeRequests,
    required this.totalWorkshops,
    required this.pendingVerifications,
    required this.totalUsers,
    required this.resolvedToday,
    required this.recentApplications,
  });

  final int activeRequests;
  final int totalWorkshops;
  final int pendingVerifications;
  final int totalUsers;
  final int resolvedToday;
  final List<AdminWorkshopSummary> recentApplications;

  factory AdminDashboardSummary.fromJson(Map<String, dynamic> json) {
    return AdminDashboardSummary(
      activeRequests: json['activeRequests'] as int,
      totalWorkshops: json['totalWorkshops'] as int,
      pendingVerifications: json['pendingVerifications'] as int,
      totalUsers: json['totalUsers'] as int,
      resolvedToday: json['resolvedToday'] as int,
      recentApplications: (json['recentApplications'] as List<dynamic>)
          .map((dynamic e) => AdminWorkshopSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
