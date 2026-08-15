import 'dart:async';

import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/location_service.dart';
import '../core/session.dart';
import '../core/websocket_service.dart';
import '../models/assistance_request.dart';
import '../models/call_signal.dart';
import '../models/call_token.dart';
import '../models/notification_message.dart';
import '../models/user_profile.dart';
import '../services/assistance_request_api.dart';
import '../services/call_api.dart';
import '../services/user_api.dart';
import '../widgets/dashboard_nav_bar.dart';
import '../widgets/incoming_call_dialog.dart';
import 'call_screen.dart';
import 'chat_screen.dart';
import 'driver_home_map_screen.dart';
import 'driver_profile_screen.dart';
import 'settings_screen.dart';
import 'emergency_sos_screen.dart';
import 'login_screen.dart';
import 'payment_history_screen.dart';
import 'workshops_list_screen.dart';

const Set<String> _activeStatuses = <String>{'PENDING', 'ACCEPTED', 'EN_ROUTE'};

/// Persistent shell for the post-payment driver experience — a bottom nav
/// switching between the map, the workshop directory, SOS, and profile.
class DriverMainDashboard extends StatefulWidget {
  const DriverMainDashboard({super.key});

  @override
  State<DriverMainDashboard> createState() => _DriverMainDashboardState();
}

class _DriverMainDashboardState extends State<DriverMainDashboard> {
  DashboardTab _tab = DashboardTab.home;
  Timer? _locationTimer;
  bool _isPushingLocation = false;
  AssistanceRequest? _activeRequest;
  StreamSubscription<NotificationMessage>? _notificationSub;
  StreamSubscription<CallSignal>? _callSignalSub;
  bool _startingCall = false;

  @override
  void initState() {
    super.initState();
    // Live tracking: while this driver has an outstanding assistance
    // request, push a fresh position every 15s so the workshop side can
    // see where they are. Cheap no-op the rest of the time — one list
    // call finds nothing active and skips the GPS read entirely.
    _locationTimer = Timer.periodic(const Duration(seconds: 15), (_) => _pushLocationIfActive());

    WebSocketService.instance.connect();
    _notificationSub = WebSocketService.instance.notifications.listen(_onNotification);
    _callSignalSub = WebSocketService.instance.callSignals.listen(_onCallSignal);
    _refreshActiveRequest();
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _notificationSub?.cancel();
    _callSignalSub?.cancel();
    super.dispose();
  }

  void _onCallSignal(CallSignal signal) {
    if (signal.type != CallSignalType.callInvite || !mounted) return;
    IncomingCallDialog.show(context, signal);
  }

  Future<void> _startCall() async {
    final AssistanceRequest? request = _activeRequest;
    if (request == null || _startingCall) return;
    setState(() => _startingCall = true);
    try {
      final CallToken token = await CallApi.start(request.id);
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (BuildContext _) => CallScreen(
          token: token,
          otherPartyName: request.workshopName ?? 'Workshop',
        ),
      ));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Couldn\'t start the call: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _startingCall = false);
    }
  }

  void _openChat() {
    final AssistanceRequest? request = _activeRequest;
    if (request == null) return;
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (BuildContext _) => ChatScreen(
        requestId: request.id,
        otherPartyName: request.workshopName ?? 'Workshop',
      ),
    ));
  }

  Future<AssistanceRequest?> _fetchActiveRequest() async {
    final List<AssistanceRequest> mine = await AssistanceRequestApi.listMine();
    return mine
        .cast<AssistanceRequest?>()
        .firstWhere((AssistanceRequest? r) => _activeStatuses.contains(r!.status), orElse: () => null);
  }

  Future<void> _refreshActiveRequest() async {
    try {
      final AssistanceRequest? active = await _fetchActiveRequest();
      if (mounted) setState(() => _activeRequest = active);
    } catch (_) {
      // Best-effort — the banner just stays as it was.
    }
  }

  /// A status push affecting this driver's own request — re-fetch (cheap;
  /// this app has at most one active request per driver) and surface a
  /// toast so the change is noticed even off the tab that shows it.
  void _onNotification(NotificationMessage message) {
    _refreshActiveRequest();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.primaryBlue,
        behavior: SnackBarBehavior.floating,
        content: Text(message.message),
      ),
    );
  }

  Future<void> _pushLocationIfActive() async {
    // Guards against overlapping ticks: on a slow/degraded connection one
    // call chain (list -> GPS -> PATCH) can outlast the 15s interval, and
    // two in flight at once can resolve out of order, briefly regressing
    // the workshop-side live map to an older position.
    if (_isPushingLocation) return;
    _isPushingLocation = true;
    try {
      final AssistanceRequest? active = await _fetchActiveRequest();
      if (mounted) setState(() => _activeRequest = active);
      if (active == null) return;

      // requestIfNeeded: false — this is a silent background timer, not a
      // user action, so it must never surface an OS permission prompt.
      final position = await LocationService.getCurrentPosition(requestIfNeeded: false);
      if (position == null) return;

      await AssistanceRequestApi.updateLocation(
        requestId: active.id,
        driverLatitude: position.latitude,
        driverLongitude: position.longitude,
      );
    } catch (_) {
      // Best-effort background tracking — a transient failure here
      // shouldn't surface anywhere in the UI, just try again next tick.
    } finally {
      _isPushingLocation = false;
    }
  }

  void _selectTab(DashboardTab tab) => setState(() => _tab = tab);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          if (_activeRequest != null)
            _ActiveRequestBanner(
              request: _activeRequest!,
              onCall: _startingCall ? null : _startCall,
              onChat: _openChat,
            ),
          Expanded(
            child: IndexedStack(
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
          ),
        ],
      ),
      bottomNavigationBar: DashboardNavBar(current: _tab, onSelect: _selectTab),
    );
  }
}

/// Persistent strip showing the live status of the driver's one outstanding
/// request — updates instantly on a WebSocket push rather than waiting for
/// the driver to happen to look at a particular screen.
class _ActiveRequestBanner extends StatelessWidget {
  const _ActiveRequestBanner({required this.request, this.onCall, this.onChat});

  final AssistanceRequest request;
  final VoidCallback? onCall;
  final VoidCallback? onChat;

  bool get _isCallable => request.status == 'ACCEPTED' || request.status == 'EN_ROUTE';

  Color get _statusColor => switch (request.status) {
    'PENDING' => AppColors.warningOrange,
    'ACCEPTED' => AppColors.primaryBlue,
    'EN_ROUTE' => AppColors.secondaryCyan,
    _ => AppColors.secondaryText,
  };

  String get _statusLabel => switch (request.status) {
    'PENDING' => 'Waiting for a workshop to accept your request…',
    'ACCEPTED' => '${request.workshopName ?? 'A workshop'} accepted your request.',
    'EN_ROUTE' => '${request.workshopName ?? 'Help'} is on the way.',
    _ => request.status,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: _statusColor.withValues(alpha: 0.12),
      child: Row(
        children: <Widget>[
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: _statusColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _statusLabel,
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: _statusColor),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (_isCallable && onChat != null)
            IconButton(
              onPressed: onChat,
              icon: Icon(Icons.chat_bubble_outline, color: _statusColor, size: 19),
              tooltip: 'Message ${request.workshopName ?? 'workshop'}',
              visualDensity: VisualDensity.compact,
            ),
          if (_isCallable && onCall != null)
            IconButton(
              onPressed: onCall,
              icon: Icon(Icons.call, color: _statusColor, size: 20),
              tooltip: 'Call ${request.workshopName ?? 'workshop'}',
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }
}

/// Minimal placeholder — no design was provided for the driver's own
/// profile screen, so this is a light stub rather than a guessed layout.
class _ProfileTab extends StatefulWidget {
  const _ProfileTab();

  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  late Future<UserProfile> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = UserApi.getMe();
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out of AutoRescue?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.dangerRed),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    WebSocketService.instance.disconnect();
    await Session.instance.clear();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

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
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const DriverProfileScreen()),
                );
                if (mounted) {
                  setState(() {
                    _profileFuture = UserApi.getMe();
                  });
                }
              },
              child: FutureBuilder<UserProfile>(
                future: _profileFuture,
                builder: (BuildContext context, AsyncSnapshot<UserProfile> snapshot) {
                  final UserProfile? profile = snapshot.data;
                  return Row(
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              profile?.fullName ?? 'Driver Account',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.heading,
                              ),
                            ),
                            Text(
                              profile?.email ?? 'Active · South-West Region',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, color: AppColors.slate),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, size: 18, color: AppColors.slateLight),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            for (final (IconData icon, String label) in const <(IconData, String)>[
              (Icons.directions_car_outlined, 'My Vehicle'),
              (Icons.receipt_long_outlined, 'Payment History'),
              (Icons.settings_outlined, 'Settings'),
              (Icons.logout, 'Log Out'),
            ])
              _ProfileRow(
                icon: icon,
                label: label,
                onTap: switch (label) {
                  'Log Out' => () => _confirmLogout(context),
                  'Payment History' => () => Navigator.of(context).push(
                        MaterialPageRoute<void>(builder: (_) => const PaymentHistoryScreen()),
                      ),
                  'Settings' => () => Navigator.of(context).push(
                        MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
                      ),
                  _ => null, // "My Vehicle" — no backend endpoint yet.
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
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
          ),
        ),
      ),
    );
  }
}
