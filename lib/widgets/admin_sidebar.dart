import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/session.dart';
import '../models/user_profile.dart';

enum AdminTab {
  dashboard(Icons.dashboard_outlined, Icons.dashboard, 'Dashboard'),
  fleetManagement(Icons.local_shipping_outlined, Icons.local_shipping, 'Fleet Management'),
  mechanicVerification(Icons.verified_user_outlined, Icons.verified_user, 'Mechanic Verification'),
  reports(Icons.bar_chart_outlined, Icons.bar_chart, 'Reports'),
  auditLogs(Icons.history_outlined, Icons.history, 'Audit Logs'),
  settings(Icons.settings_outlined, Icons.settings, 'Settings');

  const AdminTab(this.icon, this.activeIcon, this.label);

  final IconData icon;
  final IconData activeIcon;
  final String label;
}

/// Persistent left navigation for the admin portal — a permanent sidebar
/// rather than a bottom nav bar, since this surface is web-only and gets
/// used on wide viewports.
class AdminSidebar extends StatelessWidget {
  const AdminSidebar({super.key, required this.current, required this.onSelect, this.profile});

  final AdminTab current;
  final ValueChanged<AdminTab> onSelect;

  /// The signed-in admin's profile — supplies the sidebar footer's photo
  /// and name. Null until [AdminShell] finishes its first fetch, in which
  /// case the footer falls back to initials + [Session.instance.fullName].
  final UserProfile? profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 248,
      color: AppColors.card,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const _SidebarHeader(),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: <Widget>[
                  for (final AdminTab tab in AdminTab.values)
                    _SidebarItem(
                      tab: tab,
                      selected: tab == current,
                      onTap: () => onSelect(tab),
                    ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            _SidebarFooter(profile: profile),
          ],
        ),
      ),
    );
  }
}

class _SidebarHeader extends StatelessWidget {
  const _SidebarHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      child: Row(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.orange,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'SOS',
              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.5),
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'AutoRescue',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.navy),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({required this.tab, required this.selected, required this.onTap});

  final AdminTab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: selected ? AppColors.badgeSoft : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: <Widget>[
                Icon(
                  selected ? tab.activeIcon : tab.icon,
                  size: 20,
                  color: selected ? AppColors.primaryBlue : AppColors.slate,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tab.label,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? AppColors.primaryBlue : AppColors.primaryText,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarFooter extends StatelessWidget {
  const _SidebarFooter({this.profile});

  final UserProfile? profile;

  @override
  Widget build(BuildContext context) {
    final String name = profile?.fullName ?? Session.instance.fullName ?? 'Administrator';
    final String initial = name.isNotEmpty ? name[0].toUpperCase() : 'A';
    final String? photoUrl = profile?.fullProfilePhotoUrl;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.blueSoft,
            backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
            child: photoUrl != null ? null : Text(
              initial,
              style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primaryBlue),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  name,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.navy),
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: <Widget>[
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'Administrator',
                      style: TextStyle(fontSize: 11.5, color: AppColors.slate),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
