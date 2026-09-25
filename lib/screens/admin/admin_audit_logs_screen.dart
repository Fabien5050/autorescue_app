import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../models/admin_operations.dart';
import '../../services/admin_dashboard_api.dart';

class AdminAuditLogsScreen extends StatefulWidget {
  const AdminAuditLogsScreen({super.key});

  @override
  State<AdminAuditLogsScreen> createState() => _AdminAuditLogsScreenState();
}

class _AdminAuditLogsScreenState extends State<AdminAuditLogsScreen> {
  late Future<List<AdminAuditLog>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => setState(() => _future = AdminDashboardApi.getAuditLogs());

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<List<AdminAuditLog>>(
        future: _future,
        builder: (BuildContext context, AsyncSnapshot<List<AdminAuditLog>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return _AuditError(message: snapshot.error.toString(), onRetry: _load);
          final List<AdminAuditLog> logs = snapshot.data ?? <AdminAuditLog>[];
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            Padding(padding: const EdgeInsets.fromLTRB(24, 24, 24, 8), child: Row(children: <Widget>[const Expanded(child: Text('Audit Logs', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.navy))), IconButton(onPressed: _load, tooltip: 'Refresh', icon: const Icon(Icons.refresh_rounded))])),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 24), child: Text('Recent platform activity', style: TextStyle(color: AppColors.slate))),
            Expanded(child: logs.isEmpty ? const Center(child: Text('No activity recorded.', style: TextStyle(color: AppColors.slate))) : RefreshIndicator(onRefresh: () async => _load(), child: ListView.separated(padding: const EdgeInsets.all(24), itemCount: logs.length, separatorBuilder: (_, _) => const Divider(height: 1), itemBuilder: (BuildContext context, int index) {
              final AdminAuditLog log = logs[index];
              return ListTile(contentPadding: const EdgeInsets.symmetric(vertical: 6), leading: Icon(_iconFor(log.eventType), color: _colorFor(log.status)), title: Text(log.description, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.navy)), subtitle: Text('${log.eventType}  •  ${_date(log.occurredAt)}', style: const TextStyle(color: AppColors.slate)), trailing: Text(log.status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: _colorFor(log.status))));
            })))
          ]);
        },
      ),
    );
  }

  IconData _iconFor(String type) => switch (type) { 'PAYMENT' => Icons.payments_outlined, 'REQUEST' => Icons.support_agent_outlined, _ => Icons.storefront_outlined };
  Color _colorFor(String status) => switch (status) { 'SUCCESS' || 'COMPLETED' || 'APPROVED' => AppColors.success, 'FAILED' || 'CANCELLED' || 'REJECTED' => AppColors.dangerRed, _ => AppColors.warningOrange };
  String _date(DateTime value) => '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}

class _AuditError extends StatelessWidget {
  const _AuditError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.slate)), const SizedBox(height: 12), FilledButton(onPressed: onRetry, child: const Text('Retry'))]));
}
