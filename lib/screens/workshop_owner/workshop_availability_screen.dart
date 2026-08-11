import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../models/workshop_availability_status.dart';
import '../../models/workshop_owner_profile.dart';
import '../../widgets/availability_status_pill.dart';

/// Dedicated "Workshop Availability" screen — a focused view of the same
/// status the dashboard card summarizes.
class WorkshopAvailabilityScreen extends StatefulWidget {
  const WorkshopAvailabilityScreen({super.key});

  @override
  State<WorkshopAvailabilityScreen> createState() => _WorkshopAvailabilityScreenState();
}

class _WorkshopAvailabilityScreenState extends State<WorkshopAvailabilityScreen> {
  final WorkshopOwnerProfile _profile = demoWorkshopOwnerProfile;

  String get _description {
    switch (_profile.availabilityStatus) {
      case WorkshopAvailabilityStatus.available:
        return 'Your workshop is currently accepting roadside assistance requests.';
      case WorkshopAvailabilityStatus.busy:
        return "You're marked as busy — new requests are paused, but drivers can still see your profile.";
      case WorkshopAvailabilityStatus.closed:
        return 'Your workshop is closed and hidden from new requests.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.primaryText,
        title: const Text('Workshop Availability', style: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Workshop Availability',
                    style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: AppColors.primaryText),
                  ),
                  const SizedBox(height: 10),
                  AvailabilityStatusPill(status: _profile.availabilityStatus),
                  const SizedBox(height: 12),
                  Text(_description, style: const TextStyle(fontSize: 12.5, height: 1.5, color: AppColors.secondaryText)),
                  const SizedBox(height: 18),
                  const Divider(height: 1, color: AppColors.border),
                  const SizedBox(height: 16),
                  Row(
                    children: <Widget>[
                      const Expanded(
                        child: Text(
                          'Available for Requests',
                          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.primaryText),
                        ),
                      ),
                      Switch(
                        value: _profile.activeForRequests,
                        activeTrackColor: AppColors.accentGreen,
                        onChanged: (bool value) => setState(() {
                          _profile.activeForRequests = value;
                          _profile.availabilityStatus =
                              value ? WorkshopAvailabilityStatus.available : WorkshopAvailabilityStatus.closed;
                        }),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Set Status',
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.primaryText),
            ),
            const SizedBox(height: 10),
            for (final WorkshopAvailabilityStatus status in WorkshopAvailabilityStatus.values) ...<Widget>[
              _StatusOption(
                status: status,
                selected: _profile.availabilityStatus == status,
                onTap: () => setState(() {
                  _profile.availabilityStatus = status;
                  _profile.activeForRequests = status == WorkshopAvailabilityStatus.available;
                }),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusOption extends StatelessWidget {
  const _StatusOption({required this.status, required this.selected, required this.onTap});

  final WorkshopAvailabilityStatus status;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? status.color : AppColors.border, width: selected ? 1.6 : 1.2),
          ),
          child: Row(
            children: <Widget>[
              Icon(Icons.circle, size: 12, color: status.color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  status.label,
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.primaryText),
                ),
              ),
              if (selected) Icon(Icons.check_circle, color: status.color, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
