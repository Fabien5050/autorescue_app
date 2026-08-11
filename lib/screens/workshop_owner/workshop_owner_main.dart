import 'package:flutter/material.dart';

import '../../widgets/workshop_owner_nav_bar.dart';
import 'workshop_analytics_screen.dart';
import 'workshop_dashboard_screen.dart';
import 'workshop_owner_profile_screen.dart';
import 'workshop_requests_screen.dart';
import 'workshop_services_screen.dart';

/// Persistent shell for the workshop-owner experience — bottom nav
/// switching between Dashboard, Requests, Services, Analytics and Profile.
/// Mirrors [DriverMainDashboard]'s structure on the driver side.
class WorkshopOwnerMain extends StatefulWidget {
  const WorkshopOwnerMain({super.key});

  @override
  State<WorkshopOwnerMain> createState() => _WorkshopOwnerMainState();
}

class _WorkshopOwnerMainState extends State<WorkshopOwnerMain> {
  WorkshopOwnerTab _tab = WorkshopOwnerTab.dashboard;

  void _selectTab(WorkshopOwnerTab tab) => setState(() => _tab = tab);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: WorkshopOwnerTab.values.indexOf(_tab),
        children: const <Widget>[
          WorkshopDashboardScreen(),
          WorkshopRequestsScreen(),
          WorkshopServicesScreen(),
          WorkshopAnalyticsScreen(),
          WorkshopOwnerProfileScreen(),
        ],
      ),
      bottomNavigationBar: WorkshopOwnerNavBar(current: _tab, onSelect: _selectTab),
    );
  }
}
