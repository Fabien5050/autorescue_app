class AdminDocumentItem {
  const AdminDocumentItem({
    required this.documentType,
    required this.fileUrl,
  });

  final String documentType;
  final String fileUrl;

  factory AdminDocumentItem.fromJson(Map<String, dynamic> json) {
    return AdminDocumentItem(
      documentType: json['documentType'] as String,
      fileUrl: json['fileUrl'] as String,
    );
  }
}

class AdminWorkshopSummary {
  const AdminWorkshopSummary({
    required this.id,
    required this.name,
    this.description,
    this.ownerName,
    this.ownerEmail,
    this.phone,
    this.whatsapp,
    this.emergencyContact,
    this.nationalIdNumber,
    this.taxIdNumber,
    required this.address,
    this.services = const <String>[],
    required this.verificationStatus,
    required this.createdAt,
    this.documents = const <AdminDocumentItem>[],
    this.photos = const <String>[],
  });

  final int id;
  final String name;
  final String? description;
  final String? ownerName;
  final String? ownerEmail;
  final String? phone;
  final String? whatsapp;
  final String? emergencyContact;
  final String? nationalIdNumber;
  final String? taxIdNumber;
  final String? address;
  final List<String> services;
  final String verificationStatus;
  final DateTime createdAt;
  final List<AdminDocumentItem> documents;
  final List<String> photos;

  factory AdminWorkshopSummary.fromJson(Map<String, dynamic> json) {
    return AdminWorkshopSummary(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      ownerName: json['ownerName'] as String?,
      ownerEmail: json['ownerEmail'] as String?,
      phone: json['phone'] as String?,
      whatsapp: json['whatsapp'] as String?,
      emergencyContact: json['emergencyContact'] as String?,
      nationalIdNumber: json['nationalIdNumber'] as String?,
      taxIdNumber: json['taxIdNumber'] as String?,
      address: json['address'] as String?,
      services: (json['services'] as List<dynamic>?)?.map((dynamic e) => e.toString()).toList() ?? <String>[],
      verificationStatus: json['verificationStatus'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      documents: (json['documents'] as List<dynamic>?)
              ?.map((dynamic e) => AdminDocumentItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          <AdminDocumentItem>[],
      photos: (json['photos'] as List<dynamic>?)?.map((dynamic e) => e.toString()).toList() ?? <String>[],
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
      recentApplications: (json['recentApplications'] as List<dynamic>?)
              ?.map((dynamic e) => AdminWorkshopSummary.fromJson(e as Map<String, dynamic>))
              .toList() ??
          <AdminWorkshopSummary>[],
    );
  }
}
