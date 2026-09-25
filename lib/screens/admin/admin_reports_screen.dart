import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../models/admin_operations.dart';
import '../../services/admin_dashboard_api.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  late Future<AdminReport> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => setState(() => _future = AdminDashboardApi.getReports());

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<AdminReport>(
        future: _future,
        builder: (BuildContext context, AsyncSnapshot<AdminReport> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return _ReportError(message: snapshot.error.toString(), onRetry: _load);
          final AdminReport report = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async => _load(),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: <Widget>[
                Row(children: <Widget>[const Expanded(child: Text('Reports', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.navy))), IconButton(onPressed: _load, tooltip: 'Refresh', icon: const Icon(Icons.refresh_rounded))]),
                const Text('Live platform totals from the database', style: TextStyle(color: AppColors.slate)),
                const SizedBox(height: 20),
                _Section(title: 'Accounts', values: <String, String>{'Drivers': '${report.drivers}', 'Mechanics': '${report.mechanics}', 'Admins': '${report.admins}'}),
                _Section(title: 'Workshops', values: <String, String>{'Approved': '${report.approvedWorkshops}', 'Pending': '${report.pendingWorkshops}', 'Rejected': '${report.rejectedWorkshops}'}),
                _Section(title: 'Requests', values: <String, String>{'Total': '${report.totalRequests}', 'Active': '${report.activeRequests}', 'Completed': '${report.completedRequests}', 'Cancelled': '${report.cancelledRequests}'}),
                _Section(title: 'Payments', values: <String, String>{'Successful': '${report.successfulPayments}', 'Pending': '${report.pendingPayments}', 'Failed': '${report.failedPayments}', 'Collected': '${report.successfulPaymentValue.toStringAsFixed(0)} XAF'}),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.values});
  final String title;
  final Map<String, String> values;
  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 0,
        color: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.border)),
        child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.navy)), const SizedBox(height: 14), Wrap(spacing: 28, runSpacing: 16, children: values.entries.map((MapEntry<String, String> entry) => SizedBox(width: 120, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[Text(entry.value, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: AppColors.primaryBlue)), Text(entry.key, style: const TextStyle(fontSize: 12, color: AppColors.slate))]))).toList())])),
      );
}

class _ReportError extends StatelessWidget {
  const _ReportError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.slate)), const SizedBox(height: 12), FilledButton(onPressed: onRetry, child: const Text('Retry'))]));
}
