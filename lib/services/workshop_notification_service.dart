import 'package:flutter/foundation.dart';

class WorkshopNotificationItem {
  const WorkshopNotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    this.requestId,
    this.callerName,
    this.callerPhotoUrl,
  });

  final String id;
  final WorkshopNotificationType type;
  final String title;
  final String subtitle;
  final DateTime timestamp;
  final int? requestId;
  final String? callerName;
  final String? callerPhotoUrl;
}

enum WorkshopNotificationType { missedCall, newRequest, newChatMessage }

class WorkshopNotificationService {
  WorkshopNotificationService._();

  static final WorkshopNotificationService instance = WorkshopNotificationService._();

  final ValueNotifier<List<WorkshopNotificationItem>> notifications =
      ValueNotifier<List<WorkshopNotificationItem>>(<WorkshopNotificationItem>[]);

  int get totalCount => notifications.value.length;

  void addMissedCall({
    required int requestId,
    required String callerName,
    String? callerPhotoUrl,
  }) {
    final WorkshopNotificationItem item = WorkshopNotificationItem(
      id: 'call_${requestId}_${DateTime.now().millisecondsSinceEpoch}',
      type: WorkshopNotificationType.missedCall,
      title: 'Missed Call from $callerName',
      subtitle: 'Tap to call back or send a message',
      timestamp: DateTime.now(),
      requestId: requestId,
      callerName: callerName,
      callerPhotoUrl: callerPhotoUrl,
    );
    _insert(item);
  }

  void addNewRequest({required int requestId, required String message}) {
    final WorkshopNotificationItem item = WorkshopNotificationItem(
      id: 'req_${requestId}_${DateTime.now().millisecondsSinceEpoch}',
      type: WorkshopNotificationType.newRequest,
      title: 'New Emergency Assistance Request',
      subtitle: message,
      timestamp: DateTime.now(),
      requestId: requestId,
    );
    _insert(item);
  }

  void addNewMessage({
    required int requestId,
    required String senderName,
    required String previewText,
  }) {
    final WorkshopNotificationItem item = WorkshopNotificationItem(
      id: 'msg_${requestId}_${DateTime.now().millisecondsSinceEpoch}',
      type: WorkshopNotificationType.newChatMessage,
      title: 'Message from $senderName',
      subtitle: previewText,
      timestamp: DateTime.now(),
      requestId: requestId,
      callerName: senderName,
    );
    _insert(item);
  }

  void _insert(WorkshopNotificationItem item) {
    final List<WorkshopNotificationItem> current =
        List<WorkshopNotificationItem>.from(notifications.value);
    current.insert(0, item);
    notifications.value = current;
  }

  void removeItem(String id) {
    final List<WorkshopNotificationItem> current =
        List<WorkshopNotificationItem>.from(notifications.value);
    current.removeWhere((WorkshopNotificationItem i) => i.id == id);
    notifications.value = current;
  }

  void clearAll() {
    notifications.value = <WorkshopNotificationItem>[];
  }
}
