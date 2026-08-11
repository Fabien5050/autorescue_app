import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../models/day_hours.dart';

/// One weekday row for the Operating Hours screen: name, open/closed
/// switch, and (when open) tap-to-edit start/end time chips.
class OperatingHoursRow extends StatelessWidget {
  const OperatingHoursRow({
    super.key,
    required this.hours,
    required this.onToggleOpen,
    required this.onEditOpenTime,
    required this.onEditCloseTime,
  });

  final DayHours hours;
  final ValueChanged<bool> onToggleOpen;
  final VoidCallback onEditOpenTime;
  final VoidCallback onEditCloseTime;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  hours.day,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryText,
                  ),
                ),
              ),
              Text(
                hours.isOpen ? 'Open' : 'Closed',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: hours.isOpen ? AppColors.accentGreen : AppColors.secondaryText,
                ),
              ),
              Switch(
                value: hours.isOpen,
                onChanged: onToggleOpen,
                activeTrackColor: AppColors.accentGreen,
              ),
            ],
          ),
          if (hours.isOpen)
            Row(
              children: <Widget>[
                Expanded(child: _TimeChip(label: hours.openTime.format(context), onTap: onEditOpenTime)),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.arrow_forward, size: 14, color: AppColors.secondaryText),
                ),
                Expanded(child: _TimeChip(label: hours.closeTime.format(context), onTap: onEditCloseTime)),
              ],
            ),
        ],
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryText,
            ),
          ),
        ),
      ),
    );
  }
}
