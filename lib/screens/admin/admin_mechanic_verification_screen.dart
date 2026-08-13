import 'package:flutter/material.dart';

import '../../widgets/admin_placeholder.dart';

class AdminMechanicVerificationScreen extends StatelessWidget {
  const AdminMechanicVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminPlaceholder(
      icon: Icons.verified_user_outlined,
      title: 'Mechanic Verification',
      description: 'Reviewing and approving pending workshop applications '
          'will live here — the Dashboard already surfaces the queue.',
    );
  }
}
