import 'package:flutter/material.dart';

import '../../core/api_config.dart';
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

  void _showApplicationDetails(BuildContext context, AdminWorkshopSummary workshop) {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => _WorkshopDetailsDialog(
        workshop: workshop,
        isUpdating: _updatingIds.contains(workshop.id),
        onApprove: () {
          Navigator.of(dialogContext).pop();
          _handleDecision(workshop.id, 'APPROVED');
        },
        onReject: () {
          Navigator.of(dialogContext).pop();
          _handleDecision(workshop.id, 'REJECTED');
        },
      ),
    );
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
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: () => _showApplicationDetails(context, workshop),
                                icon: const Icon(Icons.find_in_page_outlined, size: 18),
                                label: const Text('View Registration Details & Uploaded ID/Documents'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primaryBlue,
                                  side: const BorderSide(color: AppColors.primaryBlue),
                                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                                ),
                              ),
                              const SizedBox(height: 12),
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
}

class _WorkshopDetailsDialog extends StatelessWidget {
  const _WorkshopDetailsDialog({
    required this.workshop,
    required this.isUpdating,
    required this.onApprove,
    required this.onReject,
  });

  final AdminWorkshopSummary workshop;
  final bool isUpdating;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 780),
        child: Column(
          children: <Widget>[
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
              child: Row(
                children: <Widget>[
                  const Icon(Icons.verified_user_outlined, color: AppColors.primaryBlue, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          workshop.name,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.navy),
                        ),
                        const Text('Complete Registration & Document Inspection', style: TextStyle(fontSize: 12, color: AppColors.slate)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            // Body
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: <Widget>[
                  _DetailSection(
                    title: 'Owner & Contact Credentials',
                    children: <Widget>[
                      _DetailRow(label: 'Owner Full Name', value: workshop.ownerName ?? 'Not provided'),
                      _DetailRow(label: 'Owner Email', value: workshop.ownerEmail ?? 'Not provided'),
                      _DetailRow(label: 'Primary Phone', value: workshop.phone ?? 'Not provided'),
                      _DetailRow(label: 'WhatsApp Contact', value: workshop.whatsapp ?? 'Not provided'),
                      _DetailRow(label: 'Emergency Line', value: workshop.emergencyContact ?? 'Not provided'),
                      _DetailRow(label: 'Facility Address', value: workshop.address ?? 'Not provided'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _DetailSection(
                    title: 'Legal & Tax Verification IDs',
                    children: <Widget>[
                      _DetailRow(label: 'National ID Number', value: workshop.nationalIdNumber ?? 'Not provided'),
                      _DetailRow(label: 'Tax / Business Registration ID', value: workshop.taxIdNumber ?? 'Not provided'),
                    ],
                  ),
                  if (workshop.services.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 20),
                    const Text('Declared Services', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.navy)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        for (final String s in workshop.services)
                          Chip(
                            label: Text(s, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryBlue)),
                            backgroundColor: AppColors.badgeSoft,
                            side: BorderSide.none,
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),
                  const Text('Uploaded Identity & Business Documents', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.navy)),
                  const SizedBox(height: 10),
                  if (workshop.documents.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: AppColors.screenBackground, borderRadius: BorderRadius.circular(10)),
                      child: const Text('No verification documents uploaded yet.', style: TextStyle(color: AppColors.slate, fontSize: 13)),
                    )
                  else
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: <Widget>[
                        for (final AdminDocumentItem doc in workshop.documents)
                          _DocumentTile(doc: doc),
                      ],
                    ),
                  if (workshop.photos.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 24),
                    const Text('Uploaded Workshop Facility Photos', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.navy)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: <Widget>[
                        for (final String photoUrl in workshop.photos)
                          _PhotoTile(photoUrl: photoUrl),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            // Actions
            Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  OutlinedButton.icon(
                    onPressed: isUpdating ? null : onReject,
                    icon: const Icon(Icons.close, color: AppColors.dangerRed),
                    label: const Text('Reject Application', style: TextStyle(color: AppColors.dangerRed)),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.dangerRed), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: isUpdating ? null : onApprove,
                    icon: const Icon(Icons.check),
                    label: const Text('Approve Workshop'),
                    style: FilledButton.styleFrom(backgroundColor: AppColors.accentGreen, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.screenBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.navy)),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 170,
            child: Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.slate)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.navy)),
          ),
        ],
      ),
    );
  }
}

class _DocumentTile extends StatelessWidget {
  const _DocumentTile({required this.doc});

  final AdminDocumentItem doc;

  String get _label => switch (doc.documentType) {
        'OWNER_ID_FRONT' => 'National ID (Front)',
        'OWNER_ID_BACK' => 'National ID (Back)',
        'FACE_PHOTO' => 'Face Photo / Selfie',
        'BUSINESS_CERTIFICATE' => 'Business Certificate',
        _ => doc.documentType.replaceAll('_', ' '),
      };

  @override
  Widget build(BuildContext context) {
    final String? resolvedUrl = ApiConfig.resolveFileUrl(doc.fileUrl);

    return Container(
      width: 180,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(_label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.navy)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 110,
              width: double.infinity,
              color: AppColors.badgeSoft,
              child: resolvedUrl != null
                  ? Image.network(
                      resolvedUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.description_outlined, size: 36, color: AppColors.primaryBlue)),
                    )
                  : const Center(child: Icon(Icons.description_outlined, size: 36, color: AppColors.primaryBlue)),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({required this.photoUrl});

  final String photoUrl;

  @override
  Widget build(BuildContext context) {
    final String? resolvedUrl = ApiConfig.resolveFileUrl(photoUrl);

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 140,
        height: 100,
        color: AppColors.badgeSoft,
        child: resolvedUrl != null
            ? Image.network(
                resolvedUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.image_not_supported_outlined, color: AppColors.slate)),
              )
            : const Center(child: Icon(Icons.image_not_supported_outlined, color: AppColors.slate)),
      ),
    );
  }
}
