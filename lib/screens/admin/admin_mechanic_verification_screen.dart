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

  void _refresh([bool forceRemote = false]) {
    setState(() {
      _pendingFuture = (!forceRemote && widget.initialApplications != null)
          ? Future<List<AdminWorkshopSummary>>.value(widget.initialApplications!)
          : AdminDashboardApi.getSummary().then((summary) => summary.recentApplications);
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
            status == 'APPROVED' ? 'Workshop approved successfully!' : 'Workshop application rejected.',
          ),
        ),
      );
      _refresh(true);
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
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const Text(
                  'Pending Workshop Applications',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.navy),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: AppColors.primaryBlue),
                  onPressed: () => _refresh(true),
                  tooltip: 'Refresh list',
                ),
              ],
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
                          FilledButton(onPressed: () => _refresh(true), child: const Text('Retry')),
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
                        'No pending workshop applications at this time.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15, color: AppColors.slate),
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => _refresh(true),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(24),
                    itemCount: applications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
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
                          padding: const EdgeInsets.all(20),
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
                                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.navy),
                                        ),
                                        if (workshop.ownerName != null && workshop.ownerName!.isNotEmpty) ...<Widget>[
                                          const SizedBox(height: 4),
                                          Row(
                                            children: <Widget>[
                                              const Icon(Icons.person_outline, size: 15, color: AppColors.primaryBlue),
                                              const SizedBox(width: 6),
                                              Text(
                                                'Owner: ${workshop.ownerName}',
                                                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.navy),
                                              ),
                                              if (workshop.phone != null && workshop.phone!.isNotEmpty) ...<Widget>[
                                                const SizedBox(width: 12),
                                                const Icon(Icons.phone_outlined, size: 14, color: AppColors.slate),
                                                const SizedBox(width: 4),
                                                Text(
                                                  workshop.phone!,
                                                  style: const TextStyle(fontSize: 13, color: AppColors.slate),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                        const SizedBox(height: 6),
                                        Row(
                                          children: <Widget>[
                                            const Icon(Icons.location_on_outlined, size: 15, color: AppColors.slate),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                workshop.address ?? 'No address provided',
                                                style: const TextStyle(fontSize: 13, color: AppColors.slate),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppColors.warningSoft,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text(
                                      'Pending Review',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.warningOrange),
                                    ),
                                  ),
                                ],
                              ),
                              if ((workshop.nationalIdNumber != null && workshop.nationalIdNumber!.isNotEmpty) ||
                                  (workshop.taxIdNumber != null && workshop.taxIdNumber!.isNotEmpty)) ...<Widget>[
                                const SizedBox(height: 12),
                                const Divider(height: 1, color: AppColors.border),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 16,
                                  runSpacing: 6,
                                  children: <Widget>[
                                    if (workshop.nationalIdNumber != null && workshop.nationalIdNumber!.isNotEmpty)
                                      Text(
                                        'National ID: ${workshop.nationalIdNumber}',
                                        style: const TextStyle(fontSize: 12.5, color: AppColors.slate),
                                      ),
                                    if (workshop.taxIdNumber != null && workshop.taxIdNumber!.isNotEmpty)
                                      Text(
                                        'Tax / Business ID: ${workshop.taxIdNumber}',
                                        style: const TextStyle(fontSize: 12.5, color: AppColors.slate),
                                      ),
                                  ],
                                ),
                              ],
                              if (workshop.services.isNotEmpty) ...<Widget>[
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: <Widget>[
                                    for (final String service in workshop.services)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.badgeSoft,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          service,
                                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.primaryBlue),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 12),
                              Text(
                                'Submitted: ${_formatDate(workshop.createdAt)}',
                                style: const TextStyle(fontSize: 12, color: AppColors.slateLight),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: FilledButton.icon(
                                      onPressed: updating ? null : () => _handleDecision(workshop.id, 'APPROVED'),
                                      icon: const Icon(Icons.check_circle_outline, size: 18),
                                      label: Text(updating ? 'Approving...' : 'Approve Workshop'),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: AppColors.accentGreen,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: updating ? null : () => _handleDecision(workshop.id, 'REJECTED'),
                                      icon: const Icon(Icons.cancel_outlined, size: 18),
                                      label: Text(updating ? 'Rejecting...' : 'Reject Application'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.dangerRed,
                                        side: const BorderSide(color: AppColors.dangerRed),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
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
    return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  }
}
