import '../core/api_client.dart';
import '../models/admin_analytics.dart';
import '../models/admin_dashboard_summary.dart';

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
}
