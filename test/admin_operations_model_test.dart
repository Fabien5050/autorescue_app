import 'package:flutter_test/flutter_test.dart';
import 'package:autorescue_app/models/admin_operations.dart';

void main() {
  test('parses fleet, report, and audit responses', () {
    final AdminVehicle vehicle = AdminVehicle.fromJson(<String, dynamic>{
      'id': 1,
      'driverName': 'Aline Mbiya',
      'driverPhone': '+237690000002',
      'category': 'SUV',
      'makeModel': 'Toyota RAV4',
      'licensePlate': 'LT 452 AA',
      'color': 'Silver',
    });
    final AdminReport report = AdminReport.fromJson(<String, dynamic>{
      'drivers': 3,
      'mechanics': 2,
      'admins': 1,
      'approvedWorkshops': 2,
      'pendingWorkshops': 1,
      'rejectedWorkshops': 0,
      'totalRequests': 5,
      'completedRequests': 2,
      'cancelledRequests': 1,
      'activeRequests': 2,
      'successfulPayments': 2,
      'pendingPayments': 1,
      'failedPayments': 0,
      'successfulPaymentValue': 9000,
      'requestsByStatus': <String, dynamic>{'PENDING': 1},
    });
    final AdminAuditLog log = AdminAuditLog.fromJson(<String, dynamic>{
      'eventType': 'REQUEST',
      'description': 'Assistance request #4',
      'status': 'PENDING',
      'occurredAt': '2026-09-25T10:00:00Z',
    });

    expect(vehicle.licensePlate, 'LT 452 AA');
    expect(report.successfulPaymentValue, 9000);
    expect(report.requestsByStatus['PENDING'], 1);
    expect(log.eventType, 'REQUEST');
  });
}
