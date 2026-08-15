import 'package:flutter/material.dart';

import '../core/app_colors.dart';

enum WorkshopOwnerTab { dashboard, requests, services, analytics, profile }

/// Persistent bottom navigation for the workshop-owner shell.
class WorkshopOwnerNavBar extends StatelessWidget {
  const WorkshopOwnerNavBar({
    super.key,
    required this.current,
    required this.onSelect,
    this.requestsBadge = false,
  });

  final WorkshopOwnerTab current;
  final ValueChanged<WorkshopOwnerTab> onSelect;

  /// Shows a small dot on the Requests tab — a new request came in, or a
  /// chat message arrived, since the owner last looked at that tab.
  final bool requestsBadge;

  static const List<(WorkshopOwnerTab, IconData, String)> _items = <(WorkshopOwnerTab, IconData, String)>[
    (WorkshopOwnerTab.dashboard, Icons.space_dashboard_outlined, 'Dashboard'),
    (WorkshopOwnerTab.requests, Icons.build_outlined, 'Requests'),
    (WorkshopOwnerTab.services, Icons.miscellaneous_services_outlined, 'Services'),
    (WorkshopOwnerTab.analytics, Icons.bar_chart_outlined, 'Analytics'),
    (WorkshopOwnerTab.profile, Icons.storefront_outlined, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.card,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.primaryText.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: <Widget>[
              for (final (WorkshopOwnerTab tab, IconData icon, String label) in _items)
                Expanded(
                  child: _NavItem(
                    icon: icon,
                    label: label,
                    selected: tab == current,
                    showBadge: tab == WorkshopOwnerTab.requests && requestsBadge,
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
    required this.onTap,
    this.showBadge = false,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool showBadge;

  @override
  Widget build(BuildContext context) {
    final Color color = selected ? AppColors.primaryBlue : AppColors.slateLight;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                Icon(icon, color: color, size: 21),
                if (showBadge)
                  Positioned(
                    right: -4,
                    top: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(color: AppColors.dangerRed, shape: BoxShape.circle),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
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
