import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/app_colors.dart';
import '../../core/websocket_service.dart';
import '../../models/chat_message.dart';
import '../../models/notification_message.dart';
import '../../services/workshop_api.dart';
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
  late Future<void> _loadProfile;
  bool _hasUnseenActivity = false;
  StreamSubscription<NotificationMessage>? _notificationSub;
  StreamSubscription<ChatMessage>? _chatMessageSub;

  @override
  void initState() {
    super.initState();
    _loadProfile = WorkshopApi.refreshMyProfile();
    // WorkshopRequestsScreen also connects/subscribes independently for its
    // own UI — this is a separate listener purely for the nav-bar badge, so
    // it still lights up even while a different tab is showing.
    WebSocketService.instance.connect();
    _notificationSub = WebSocketService.instance.notifications.listen((NotificationMessage message) {
      if (message.type == NotificationType.newRequest) _markUnseen();
    });
    _chatMessageSub = WebSocketService.instance.chatMessages.listen((_) => _markUnseen());
  }

  @override
  void dispose() {
    _notificationSub?.cancel();
    _chatMessageSub?.cancel();
    super.dispose();
  }

  void _markUnseen() {
    if (_tab == WorkshopOwnerTab.requests || !mounted) return;
    setState(() => _hasUnseenActivity = true);
  }

  void _selectTab(WorkshopOwnerTab tab) => setState(() {
    _tab = tab;
    if (tab == WorkshopOwnerTab.requests) _hasUnseenActivity = false;
  });

  void _retry() => setState(() {
    _loadProfile = WorkshopApi.refreshMyProfile();
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<void>(
        future: _loadProfile,
        builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final String message = snapshot.error is ApiException
                ? (snapshot.error! as ApiException).message
                : 'Failed to load your workshop.';
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.slate),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(onPressed: _retry, child: const Text('Retry')),
                  ],
                ),
              ),
            );
          }
          return IndexedStack(
            index: WorkshopOwnerTab.values.indexOf(_tab),
            children: const <Widget>[
              WorkshopDashboardScreen(),
              WorkshopRequestsScreen(),
              WorkshopServicesScreen(),
              WorkshopAnalyticsScreen(),
              WorkshopOwnerProfileScreen(),
            ],
          );
        },
      ),
      bottomNavigationBar: WorkshopOwnerNavBar(
        current: _tab,
        onSelect: _selectTab,
        requestsBadge: _hasUnseenActivity,
      ),
    );
  }
}
