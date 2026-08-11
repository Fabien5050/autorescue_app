import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../models/workshop_service.dart';

/// Card row for the Services screen: icon, name, description, optional
/// price, an availability toggle, and edit/delete actions.
class ServiceManagementCard extends StatelessWidget {
  const ServiceManagementCard({
    super.key,
    required this.service,
    required this.onAvailabilityChanged,
    required this.onEdit,
    required this.onDelete,
  });

  final WorkshopService service;
  final ValueChanged<bool> onAvailabilityChanged;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.badgeSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(service.icon, size: 20, color: AppColors.primaryBlue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      service.name,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      service.description,
                      style: const TextStyle(fontSize: 12.5, color: AppColors.secondaryText),
                    ),
                    if (service.price != null) ...<Widget>[
                      const SizedBox(height: 4),
                      Text(
                        service.price!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Switch(
                value: service.available,
                onChanged: onAvailabilityChanged,
                activeTrackColor: AppColors.accentGreen,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (service.available ? AppColors.accentGreen : AppColors.secondaryText)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  service.available ? 'Available' : 'Unavailable',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: service.available ? AppColors.accentGreen : AppColors.secondaryText,
                  ),
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Edit'),
                style: TextButton.styleFrom(foregroundColor: AppColors.primaryBlue),
              ),
              TextButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, size: 16),
                label: const Text('Delete'),
                style: TextButton.styleFrom(foregroundColor: AppColors.dangerRed),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
