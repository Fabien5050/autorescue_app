import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../models/admin_dashboard_summary.dart';
import '../../services/admin_dashboard_api.dart';

class AdminMechanicVerificationScreen extends StatefulWidget {
  const AdminMechanicVerificationScreen({
    super.key,
    this.initialApplications,
  });

  final List<AdminWorkshopSummary>? initialApplications;

  @override
  State<AdminMechanicVerificationScreen> createState() => _AdminMechanicVerificationScreenState();
}

class _AdminMechanicVerificationScreenState extends State<AdminMechanicVerificationScreen> {
  late Future<List<AdminWorkshopSummary>> _pendingFuture;
  final Set<int> _updatingIds = <int>{};

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _pendingFuture = widget.initialApplications == null
          ? AdminDashboardApi.getSummary().then((summary) => summary.recentApplications)
          : Future<List<AdminWorkshopSummary>>.value(widget.initialApplications!);
    });
  }

  Future<void> _handleDecision(int workshopId, String status) async {
    setState(() => _updatingIds.add(workshopId));
    try {
      await AdminDashboardApi.verifyWorkshop(workshopId, status);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'APPROVED' ? 'Workshop approved.' : 'Workshop rejected.',
          ),
        ),
      );
      _refresh();
    } catch (error) {
      if (!mounted) return;
      final String message = error is Exception ? error.toString() : 'Unable to update workshop status.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) {
        setState(() => _updatingIds.remove(workshopId));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Text(
              'Pending workshop applications',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.navy),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<AdminWorkshopSummary>>(
              future: _pendingFuture,
              builder: (BuildContext context, AsyncSnapshot<List<AdminWorkshopSummary>> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  final String message = snapshot.error.toString();
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const Icon(Icons.error_outline_rounded, size: 42, color: AppColors.slate),
                          const SizedBox(height: 12),
                          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.slate)),
                          const SizedBox(height: 12),
                          FilledButton(onPressed: _refresh, child: const Text('Retry')),
                        ],
                      ),
                    ),
                  );
                }

                final List<AdminWorkshopSummary> applications = snapshot.data ?? <AdminWorkshopSummary>[];
                if (applications.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No pending workshop applications.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: AppColors.slate),
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => _refresh(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(24),
                    itemCount: applications.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 16),
                    itemBuilder: (BuildContext context, int index) {
                      final AdminWorkshopSummary workshop = applications[index];
                      final bool updating = _updatingIds.contains(workshop.id);

                      return Card(
                        color: AppColors.card,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: AppColors.border),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          workshop.name,
                                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.navy),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          workshop.address ?? 'No address provided',
                                          style: const TextStyle(color: AppColors.slate),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Submitted ${_formatDate(workshop.createdAt)}',
                                          style: const TextStyle(fontSize: 12, color: AppColors.slate),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppColors.blueSoft,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: const Text(
                                      'Pending',
                                      style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.blue),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: FilledButton.icon(
                                      onPressed: updating ? null : () => _handleDecision(workshop.id, 'APPROVED'),
                                      icon: const Icon(Icons.check_rounded),
                                      label: Text(updating ? 'Approving...' : 'Approve'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: updating ? null : () => _handleDecision(workshop.id, 'REJECTED'),
                                      icon: const Icon(Icons.close_rounded),
                                      label: Text(updating ? 'Rejecting...' : 'Reject'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
  }
}
