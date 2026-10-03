import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../models/call_token.dart';
import '../screens/call_screen.dart';
import '../screens/chat_screen.dart';
import '../services/call_api.dart';
import '../services/workshop_notification_service.dart';

/// Top-bar notification bell widget for workshop screens.
/// Displays a red badge count for missed calls, new requests, and chat messages.
class WorkshopNotificationButton extends StatelessWidget {
  const WorkshopNotificationButton({super.key});

  void _showNotificationSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext sheetContext) => const _WorkshopNotificationSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<WorkshopNotificationItem>>(
      valueListenable: WorkshopNotificationService.instance.notifications,
      builder: (BuildContext context, List<WorkshopNotificationItem> list, Widget? _) {
        final int count = list.length;

        return Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            IconButton(
              icon: const Icon(Icons.notifications_outlined, color: AppColors.primaryText),
              onPressed: () => _showNotificationSheet(context),
              tooltip: 'Notifications',
            ),
            if (count > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                  decoration: const BoxDecoration(
                    color: AppColors.dangerRed,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    count > 9 ? '9+' : count.toString(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _WorkshopNotificationSheet extends StatelessWidget {
  const _WorkshopNotificationSheet();

  Future<void> _callBack(BuildContext context, WorkshopNotificationItem item) async {
    if (item.requestId == null) return;
    Navigator.of(context).pop();
    final String name = item.callerName ?? 'Driver';
    try {
      final CallToken token = await CallApi.start(item.requestId!);
      if (!context.mounted) return;
      Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (BuildContext _) => CallScreen(
          token: token,
          otherPartyName: name,
          otherPartyPhotoUrl: item.callerPhotoUrl,
        ),
      ));
    } catch (_) {
      if (!context.mounted) return;
      final CallToken fallbackToken = CallToken(
        appId: '1f10928230b3438096f4dd71a1fa9300',
        channel: 'request_${item.requestId}',
        token: '',
        uid: 0,
      );
      Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (BuildContext _) => CallScreen(
          token: fallbackToken,
          otherPartyName: name,
          otherPartyPhotoUrl: item.callerPhotoUrl,
        ),
      ));
    }
  }

  void _sendMessage(BuildContext context, WorkshopNotificationItem item) {
    if (item.requestId == null) return;
    Navigator.of(context).pop();
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (BuildContext _) => ChatScreen(
        requestId: item.requestId!,
        otherPartyName: item.callerName ?? 'Driver',
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<WorkshopNotificationItem>>(
      valueListenable: WorkshopNotificationService.instance.notifications,
      builder: (BuildContext context, List<WorkshopNotificationItem> list, Widget? _) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.55,
          minChildSize: 0.3,
          maxChildSize: 0.85,
          builder: (BuildContext context, ScrollController scrollController) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      const Text(
                        'Workshop Notifications',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.heading,
                        ),
                      ),
                      if (list.isNotEmpty)
                        TextButton(
                          onPressed: () => WorkshopNotificationService.instance.clearAll(),
                          child: const Text('Clear All', style: TextStyle(color: AppColors.slate)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: list.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Icon(Icons.notifications_off_outlined, size: 42, color: AppColors.slateLight),
                                  SizedBox(height: 12),
                                  Text(
                                    'No new notifications or alerts.',
                                    style: TextStyle(fontSize: 14, color: AppColors.slate),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.separated(
                            controller: scrollController,
                            itemCount: list.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (BuildContext context, int index) {
                              final WorkshopNotificationItem item = list[index];
                              final IconData icon = switch (item.type) {
                                WorkshopNotificationType.missedCall => Icons.phone_missed,
                                WorkshopNotificationType.newRequest => Icons.warning_amber_rounded,
                                WorkshopNotificationType.newChatMessage => Icons.chat_bubble_outline,
                              };
                              final Color iconColor = switch (item.type) {
                                WorkshopNotificationType.missedCall => AppColors.dangerRed,
                                WorkshopNotificationType.newRequest => AppColors.warningOrange,
                                WorkshopNotificationType.newChatMessage => AppColors.accentGreen,
                              };

                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  children: <Widget>[
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: iconColor.withValues(alpha: 0.12),
                                      child: Icon(icon, color: iconColor, size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Text(
                                            item.title,
                                            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.heading),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            item.subtitle,
                                            style: const TextStyle(fontSize: 12, color: AppColors.slate),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            _formatTime(item.timestamp),
                                            style: const TextStyle(fontSize: 10.5, color: AppColors.slateLight),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (item.requestId != null) ...<Widget>[
                                      IconButton(
                                        icon: const Icon(Icons.chat_bubble_outline, color: AppColors.accentGreen, size: 20),
                                        tooltip: 'Message',
                                        onPressed: () => _sendMessage(context, item),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.call, color: AppColors.primaryBlue, size: 20),
                                        tooltip: 'Call',
                                        onPressed: () => _callBack(context, item),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
