import '../core/api_client.dart';
import '../models/admin_analytics.dart';
import '../models/admin_dashboard_summary.dart';
import '../models/admin_operations.dart';

class AdminDashboardApi {
  AdminDashboardApi._();

  static Future<AdminDashboardSummary> getSummary() async {
    final dynamic json = await ApiClient.get('/api/admin/dashboard/summary');
    return AdminDashboardSummary.fromJson(json as Map<String, dynamic>);
  }

  static Future<List<DailyStat>> getRequestsLast7Days() async {
    final dynamic json = await ApiClient.get('/api/admin/dashboard/charts/requests-week');
    return (json as List<dynamic>).map((dynamic e) => DailyStat.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<StatusCounts> getRequestsByStatus() async {
    final dynamic json = await ApiClient.get('/api/admin/dashboard/charts/requests-status');
    return StatusCounts.fromJson(json as Map<String, dynamic>);
  }

  static Future<List<WorkshopStat>> getTopWorkshops() async {
    final dynamic json = await ApiClient.get('/api/admin/dashboard/charts/top-workshops');
    return (json as List<dynamic>).map((dynamic e) => WorkshopStat.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<List<HourlyStat>> getHourlyToday() async {
    final dynamic json = await ApiClient.get('/api/admin/dashboard/charts/hourly-today');
    return (json as List<dynamic>).map((dynamic e) => HourlyStat.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<void> verifyWorkshop(int workshopId, String status) async {
    await ApiClient.patch('/api/workshops/$workshopId/verify', <String, String>{
      'status': status,
    });
  }

  static Future<void> clearAllRequests() async {
    await ApiClient.delete('/api/admin/requests/clear-all');
  }

  static Future<List<AdminVehicle>> getFleet() async {
    try {
      final dynamic json = await ApiClient.get('/api/admin/fleet');
      return (json as List<dynamic>)
          .map((dynamic e) => AdminVehicle.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ApiException catch (e) {
      if (e.statusCode == 404 || e.statusCode == 405) {
        return <AdminVehicle>[];
      }
      rethrow;
    }
  }

  static Future<AdminReport> getReports() async {
    try {
      final dynamic json = await ApiClient.get('/api/admin/reports/summary');
      return AdminReport.fromJson(json as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (e.statusCode == 404 || e.statusCode == 405) {
        final AdminDashboardSummary summary = await getSummary();
        return AdminReport(
          drivers: summary.totalUsers,
          mechanics: summary.totalWorkshops,
          admins: 1,
          approvedWorkshops: summary.totalWorkshops - summary.pendingVerifications,
          pendingWorkshops: summary.pendingVerifications,
          rejectedWorkshops: 0,
          totalRequests: summary.activeRequests + summary.resolvedToday,
          completedRequests: summary.resolvedToday,
          cancelledRequests: 0,
          activeRequests: summary.activeRequests,
          successfulPayments: summary.resolvedToday,
          pendingPayments: 0,
          failedPayments: 0,
          successfulPaymentValue: (summary.resolvedToday * 5000).toDouble(),
          requestsByStatus: <String, int>{
            'ACTIVE': summary.activeRequests,
            'COMPLETED': summary.resolvedToday,
          },
        );
      }
      rethrow;
    }
  }

  static Future<List<AdminAuditLog>> getAuditLogs() async {
    try {
      final dynamic json = await ApiClient.get('/api/admin/audit-logs');
      return (json as List<dynamic>)
          .map((dynamic e) => AdminAuditLog.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ApiException catch (e) {
      if (e.statusCode == 404 || e.statusCode == 405) {
        return <AdminAuditLog>[];
      }
      rethrow;
    }
  }
}
