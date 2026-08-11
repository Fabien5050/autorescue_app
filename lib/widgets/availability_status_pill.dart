import 'package:flutter/material.dart';

import '../models/workshop_availability_status.dart';

/// "● Available" / "● Busy" / "● Closed" pill, colored per
/// [WorkshopAvailabilityStatus].
class AvailabilityStatusPill extends StatelessWidget {
  const AvailabilityStatusPill({super.key, required this.status, this.dense = false});

  final WorkshopAvailabilityStatus status;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: dense ? 8 : 12, vertical: dense ? 4 : 7),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: status.color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            status.label.toUpperCase(),
            style: TextStyle(
              fontSize: dense ? 10.5 : 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
              color: status.color,
            ),
          ),
        ],
      ),
    );
  }
}
