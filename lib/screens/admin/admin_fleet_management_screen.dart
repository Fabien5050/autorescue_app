import 'package:flutter/material.dart';

import '../../widgets/admin_placeholder.dart';

class AdminFleetManagementScreen extends StatelessWidget {
  const AdminFleetManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminPlaceholder(
      icon: Icons.local_shipping_outlined,
      title: 'Fleet Management',
      description: 'Tracking and managing registered tow trucks and service '
          'vehicles will live here.',
    );
  }
}
