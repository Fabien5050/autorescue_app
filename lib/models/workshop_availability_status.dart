import 'package:flutter/material.dart';

import '../core/app_colors.dart';

/// Coarse-grained availability shown on the dashboard and profile — distinct
/// from [bool] "Active for Requests" because a workshop can be open but
/// temporarily too busy to take new jobs.
enum WorkshopAvailabilityStatus {
  available('Available', AppColors.accentGreen),
  busy('Busy', AppColors.warningOrange),
  closed('Closed', AppColors.secondaryText);

  const WorkshopAvailabilityStatus(this.label, this.color);

  final String label;
  final Color color;
}
