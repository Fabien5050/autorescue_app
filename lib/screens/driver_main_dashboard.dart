import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../widgets/dashboard_nav_bar.dart';
import 'driver_home_map_screen.dart';
import 'emergency_sos_screen.dart';
import 'workshops_list_screen.dart';

/// Persistent shell for the post-payment driver experience — a bottom nav
/// switching between the map, the workshop directory, SOS, and profile.
class DriverMainDashboard extends StatefulWidget {
  const DriverMainDashboard({super.key});

  @override
  State<DriverMainDashboard> createState() => _DriverMainDashboardState();
}

class _DriverMainDashboardState extends State<DriverMainDashboard> {
  DashboardTab _tab = DashboardTab.home;

  void _selectTab(DashboardTab tab) => setState(() => _tab = tab);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: DashboardTab.values.indexOf(_tab),
        children: <Widget>[
          DriverHomeMapScreen(
            onEmergencyTap: () => _selectTab(DashboardTab.sos),
            onViewAllWorkshops: () => _selectTab(DashboardTab.workshops),
          ),
          WorkshopsListScreen(onViewMap: () => _selectTab(DashboardTab.home)),
          const EmergencySosScreen(),
          const _ProfileTab(),
        ],
      ),
      bottomNavigationBar: DashboardNavBar(current: _tab, onSelect: _selectTab),
    );
  }
}

/// Minimal placeholder — no design was provided for the driver's own
/// profile screen, so this is a light stub rather than a guessed layout.
class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          children: <Widget>[
            const Text(
              'Profile',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.heading,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: <Widget>[
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: AppColors.badgeSoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, color: AppColors.primaryBlue, size: 28),
                ),
                const SizedBox(width: 14),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Driver Account',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.heading,
                      ),
                    ),
                    Text(
                      'Active · South-West Region',
                      style: TextStyle(fontSize: 12, color: AppColors.slate),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            for (final (IconData icon, String label) in const <(IconData, String)>[
              (Icons.directions_car_outlined, 'My Vehicle'),
              (Icons.receipt_long_outlined, 'Payment History'),
              (Icons.settings_outlined, 'Settings'),
              (Icons.logout, 'Log Out'),
            ])
              _ProfileRow(icon: icon, label: label),
          ],
        ),
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 19, color: AppColors.slate),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: AppColors.heading,
            ),
          ),
          const Spacer(),
          const Icon(Icons.chevron_right, size: 18, color: AppColors.slateLight),
        ],
      ),
    );
  }
}
