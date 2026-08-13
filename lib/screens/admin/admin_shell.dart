import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../models/user_profile.dart';
import '../../services/user_api.dart';
import '../../widgets/admin_sidebar.dart';
import 'admin_audit_logs_screen.dart';
import 'admin_dashboard_screen.dart';
import 'admin_fleet_management_screen.dart';
import 'admin_mechanic_verification_screen.dart';
import 'admin_reports_screen.dart';
import 'admin_settings_screen.dart';

/// Below this width the permanent sidebar wouldn't leave enough room for
/// content (this portal is web-only but still gets opened on phone-width
/// browsers), so it collapses into a drawer instead.
const double _narrowBreakpoint = 900;

/// Persistent shell for the signed-in admin portal — a fixed left sidebar
/// next to a switchable content pane on wide viewports, or an app-bar +
/// drawer on narrow ones. The web-desktop equivalent of [WorkshopOwnerMain]'s
/// bottom-nav shell on the mobile side.
class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  AdminTab _tab = AdminTab.dashboard;
  UserProfile? _profile;

  @override
  void initState() {
    super.initState();
    // Best-effort — a failed fetch just leaves the sidebar showing initials
    // instead of a photo, not worth surfacing as an error on its own.
    UserApi.getMe().then((UserProfile profile) {
      if (mounted) setState(() => _profile = profile);
    }).catchError((Object _) {});
  }

  void _selectTab(AdminTab tab) => setState(() => _tab = tab);

  void _onProfileChanged(UserProfile profile) => setState(() => _profile = profile);

  @override
  Widget build(BuildContext context) {
    final Widget content = IndexedStack(
      index: AdminTab.values.indexOf(_tab),
      children: <Widget>[
        AdminDashboardScreen(onReviewRequested: () => _selectTab(AdminTab.mechanicVerification)),
        const AdminFleetManagementScreen(),
        const AdminMechanicVerificationScreen(),
        const AdminReportsScreen(),
        const AdminAuditLogsScreen(),
        AdminSettingsScreen(onProfileChanged: _onProfileChanged),
      ],
    );

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (constraints.maxWidth < _narrowBreakpoint) {
          return Scaffold(
            backgroundColor: AppColors.screenBackground,
            appBar: AppBar(
              backgroundColor: AppColors.card,
              foregroundColor: AppColors.navy,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
              title: Text(_tab.label, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.navy)),
            ),
            drawer: Drawer(
              width: 264,
              child: AdminSidebar(
                current: _tab,
                profile: _profile,
                onSelect: (AdminTab tab) {
                  _selectTab(tab);
                  Navigator.of(context).pop();
                },
              ),
            ),
            body: content,
          );
        }

        return Scaffold(
          backgroundColor: AppColors.screenBackground,
          body: Row(
            children: <Widget>[
              AdminSidebar(current: _tab, profile: _profile, onSelect: _selectTab),
              const VerticalDivider(width: 1, color: AppColors.border),
              Expanded(child: content),
            ],
          ),
        );
      },
    );
  }
}
