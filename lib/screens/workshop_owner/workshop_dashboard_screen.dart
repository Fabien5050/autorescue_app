import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../models/workshop_availability_status.dart';
import '../../models/workshop_owner_profile.dart';
import '../../widgets/availability_status_pill.dart';
import '../../widgets/stat_card.dart';

/// "Dashboard" tab — header, quick stats, and an availability toggle. This
/// is the workshop owner's landing screen after signing in.
class WorkshopDashboardScreen extends StatefulWidget {
  const WorkshopDashboardScreen({super.key});

  @override
  State<WorkshopDashboardScreen> createState() => _WorkshopDashboardScreenState();
}

class _WorkshopDashboardScreenState extends State<WorkshopDashboardScreen> {
  final WorkshopOwnerProfile _profile = demoWorkshopOwnerProfile;

  Future<void> _changeStatus() async {
    final WorkshopAvailabilityStatus? picked = await showModalBottomSheet<WorkshopAvailabilityStatus>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (BuildContext sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const SizedBox(height: 8),
            for (final WorkshopAvailabilityStatus status in WorkshopAvailabilityStatus.values)
              ListTile(
                leading: Icon(Icons.circle, size: 12, color: status.color),
                title: Text(status.label),
                onTap: () => Navigator.of(sheetContext).pop(status),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (picked == null || !mounted) return;
    setState(() => _profile.availabilityStatus = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          children: <Widget>[
            _Header(profile: _profile),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final int columns = constraints.maxWidth > 420 ? 4 : 2;
                return GridView.count(
                  crossAxisCount: columns,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.25,
                  children: const <Widget>[
                    StatCard(icon: Icons.build_circle_outlined, label: 'Active Requests', value: '3', color: AppColors.primaryBlue),
                    StatCard(icon: Icons.check_circle_outline, label: 'Completed Jobs', value: '58', color: AppColors.accentGreen),
                    StatCard(icon: Icons.star_outline, label: 'Rating', value: '4.8', color: AppColors.warningOrange),
                    StatCard(icon: Icons.people_outline, label: 'Total Customers', value: '112', color: AppColors.secondaryCyan),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      const Text(
                        'Workshop Status',
                        style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.primaryText),
                      ),
                      InkWell(
                        onTap: _changeStatus,
                        borderRadius: BorderRadius.circular(20),
                        child: AvailabilityStatusPill(status: _profile.availabilityStatus),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: AppColors.border),
                  const SizedBox(height: 14),
                  Row(
                    children: <Widget>[
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Active for Requests',
                              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.primaryText),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Drivers can see and contact your workshop',
                              style: TextStyle(fontSize: 11.5, color: AppColors.secondaryText),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _profile.activeForRequests,
                        onChanged: (bool value) => setState(() => _profile.activeForRequests = value),
                        activeTrackColor: AppColors.accentGreen,
                      ),
                    ],
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

class _Header extends StatelessWidget {
  const _Header({required this.profile});

  final WorkshopOwnerProfile profile;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: AppColors.primaryBlue, borderRadius: BorderRadius.circular(14)),
          child: const Icon(Icons.storefront, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Flexible(
                    child: Text(
                      profile.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, color: AppColors.primaryText),
                    ),
                  ),
                  if (profile.isVerified) ...<Widget>[
                    const SizedBox(width: 6),
                    const Icon(Icons.verified, size: 16, color: AppColors.primaryBlue),
                  ],
                ],
              ),
              Text(
                profile.ownerName,
                style: const TextStyle(fontSize: 12.5, color: AppColors.secondaryText),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(behavior: SnackBarBehavior.floating, content: Text('No new notifications')),
          ),
          icon: const Icon(Icons.notifications_none, color: AppColors.primaryText),
        ),
        IconButton(
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(behavior: SnackBarBehavior.floating, content: Text('Settings not wired up yet')),
          ),
          icon: const Icon(Icons.settings_outlined, color: AppColors.primaryText),
        ),
      ],
    );
  }
}
