import 'package:flutter/material.dart';

import '../../widgets/admin_placeholder.dart';

class AdminReportsScreen extends StatelessWidget {
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminPlaceholder(
      icon: Icons.bar_chart_outlined,
      title: 'Reports',
      description: 'Usage, revenue, and response-time reporting will live '
          'here.',
    );
  }
}
