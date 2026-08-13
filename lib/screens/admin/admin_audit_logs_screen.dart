import 'package:flutter/material.dart';

import '../../widgets/admin_placeholder.dart';

class AdminAuditLogsScreen extends StatelessWidget {
  const AdminAuditLogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminPlaceholder(
      icon: Icons.history_outlined,
      title: 'Audit Logs',
      description: 'A record of admin actions — approvals, rejections, '
          'account changes — will live here.',
    );
  }
}
