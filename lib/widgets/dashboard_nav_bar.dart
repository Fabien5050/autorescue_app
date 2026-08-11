import 'package:flutter/material.dart';

import '../core/app_colors.dart';

enum DashboardTab { home, workshops, sos, profile }

/// Persistent bottom navigation shared by every tab of the driver dashboard.
class DashboardNavBar extends StatelessWidget {
  const DashboardNavBar({super.key, required this.current, required this.onSelect});

  final DashboardTab current;
  final ValueChanged<DashboardTab> onSelect;

  static const List<(DashboardTab, IconData, String)> _items = <(DashboardTab, IconData, String)>[
    (DashboardTab.home, Icons.home_outlined, 'Home'),
    (DashboardTab.workshops, Icons.build_outlined, 'Workshops'),
    (DashboardTab.sos, Icons.sos_rounded, 'SOS'),
    (DashboardTab.profile, Icons.person_outline, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 58,
          child: Row(
            children: <Widget>[
              for (final (DashboardTab tab, IconData icon, String label) in _items)
                Expanded(
                  child: _NavItem(
                    icon: icon,
                    label: label,
                    selected: tab == current,
                    isSos: tab == DashboardTab.sos,
                    onTap: () => onSelect(tab),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.isSos,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final bool isSos;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color color = isSos
        ? AppColors.emergencyRed
        : (selected ? AppColors.primaryBlue : AppColors.slateLight);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
