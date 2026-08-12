/// A driver's roadside-assistance request, mirroring the backend's
/// `AssistanceRequestResponse`.
class AssistanceRequest {
  const AssistanceRequest({
    required this.id,
    required this.driverId,
    required this.driverName,
    required this.driverPhone,
    this.workshopId,
    this.workshopName,
    required this.status,
    this.description,
    required this.driverLatitude,
    required this.driverLongitude,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
  });

  final int id;
  final int driverId;
  final String driverName;
  final String driverPhone;
  final int? workshopId;
  final String? workshopName;
  final String status;
  final String? description;
  final double driverLatitude;
  final double driverLongitude;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;

  factory AssistanceRequest.fromJson(Map<String, dynamic> json) => AssistanceRequest(
    id: json['id'] as int,
    driverId: json['driverId'] as int,
    driverName: json['driverName'] as String,
    driverPhone: json['driverPhone'] as String,
    workshopId: json['workshopId'] as int?,
    workshopName: json['workshopName'] as String?,
    status: json['status'] as String,
    description: json['description'] as String?,
    driverLatitude: (json['driverLatitude'] as num).toDouble(),
    driverLongitude: (json['driverLongitude'] as num).toDouble(),
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
    completedAt: json['completedAt'] == null
        ? null
        : DateTime.parse(json['completedAt'] as String),
  );
}

/// Mirrors the backend's `AssistanceRequest.Status` enum.
enum AssistanceRequestStatus { pending, accepted, enRoute, completed, cancelled }

extension AssistanceRequestStatusWire on AssistanceRequestStatus {
  String get wireName => switch (this) {
    AssistanceRequestStatus.pending => 'PENDING',
    AssistanceRequestStatus.accepted => 'ACCEPTED',
    AssistanceRequestStatus.enRoute => 'EN_ROUTE',
    AssistanceRequestStatus.completed => 'COMPLETED',
    AssistanceRequestStatus.cancelled => 'CANCELLED',
  };
}
