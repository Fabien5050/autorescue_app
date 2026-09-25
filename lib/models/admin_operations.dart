class AdminVehicle {
  const AdminVehicle({
    required this.id,
    required this.driverName,
    required this.driverPhone,
    required this.category,
    required this.makeModel,
    required this.licensePlate,
    required this.color,
  });

  final int id;
  final String driverName;
  final String driverPhone;
  final String category;
  final String makeModel;
  final String licensePlate;
  final String color;

  factory AdminVehicle.fromJson(Map<String, dynamic> json) => AdminVehicle(
        id: json['id'] as int,
        driverName: json['driverName'] as String,
        driverPhone: json['driverPhone'] as String,
        category: json['category'] as String,
        makeModel: json['makeModel'] as String,
        licensePlate: json['licensePlate'] as String,
        color: json['color'] as String,
      );
}

class AdminReport {
  const AdminReport({
    required this.drivers,
    required this.mechanics,
    required this.admins,
    required this.approvedWorkshops,
    required this.pendingWorkshops,
    required this.rejectedWorkshops,
    required this.totalRequests,
    required this.completedRequests,
    required this.cancelledRequests,
    required this.activeRequests,
    required this.successfulPayments,
    required this.pendingPayments,
    required this.failedPayments,
    required this.successfulPaymentValue,
    required this.requestsByStatus,
  });

  final int drivers;
  final int mechanics;
  final int admins;
  final int approvedWorkshops;
  final int pendingWorkshops;
  final int rejectedWorkshops;
  final int totalRequests;
  final int completedRequests;
  final int cancelledRequests;
  final int activeRequests;
  final int successfulPayments;
  final int pendingPayments;
  final int failedPayments;
  final double successfulPaymentValue;
  final Map<String, int> requestsByStatus;

  factory AdminReport.fromJson(Map<String, dynamic> json) => AdminReport(
        drivers: (json['drivers'] as num).toInt(),
        mechanics: (json['mechanics'] as num).toInt(),
        admins: (json['admins'] as num).toInt(),
        approvedWorkshops: (json['approvedWorkshops'] as num).toInt(),
        pendingWorkshops: (json['pendingWorkshops'] as num).toInt(),
        rejectedWorkshops: (json['rejectedWorkshops'] as num).toInt(),
        totalRequests: (json['totalRequests'] as num).toInt(),
        completedRequests: (json['completedRequests'] as num).toInt(),
        cancelledRequests: (json['cancelledRequests'] as num).toInt(),
        activeRequests: (json['activeRequests'] as num).toInt(),
        successfulPayments: (json['successfulPayments'] as num).toInt(),
        pendingPayments: (json['pendingPayments'] as num).toInt(),
        failedPayments: (json['failedPayments'] as num).toInt(),
        successfulPaymentValue: (json['successfulPaymentValue'] as num).toDouble(),
        requestsByStatus: (json['requestsByStatus'] as Map<String, dynamic>).map(
          (String key, dynamic value) => MapEntry(key, (value as num).toInt()),
        ),
      );
}

class AdminAuditLog {
  const AdminAuditLog({required this.eventType, required this.description, required this.status, required this.occurredAt});

  final String eventType;
  final String description;
  final String status;
  final DateTime occurredAt;

  factory AdminAuditLog.fromJson(Map<String, dynamic> json) => AdminAuditLog(
        eventType: json['eventType'] as String,
        description: json['description'] as String,
        status: json['status'] as String,
        occurredAt: DateTime.parse(json['occurredAt'] as String),
      );
}
