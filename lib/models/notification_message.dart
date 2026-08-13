/// A push notification delivered over the WebSocket, mirroring the
/// backend's `NotificationMessage` record.
class NotificationMessage {
  const NotificationMessage({
    required this.type,
    this.requestId,
    this.driverId,
    this.workshopId,
    required this.message,
    required this.timestamp,
  });

  final NotificationType type;
  final int? requestId;
  final int? driverId;
  final int? workshopId;
  final String message;
  final DateTime timestamp;

  factory NotificationMessage.fromJson(Map<String, dynamic> json) {
    return NotificationMessage(
      type: NotificationType.fromWire(json['type'] as String),
      requestId: json['requestId'] as int?,
      driverId: json['driverId'] as int?,
      workshopId: json['workshopId'] as int?,
      message: json['message'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

/// Mirrors the backend's `NotificationMessage.Type` enum.
enum NotificationType {
  newRequest,
  requestAccepted,
  statusUpdated,
  requestCancelled,
  unknown;

  static NotificationType fromWire(String wire) => switch (wire) {
    'NEW_REQUEST' => NotificationType.newRequest,
    'REQUEST_ACCEPTED' => NotificationType.requestAccepted,
    'STATUS_UPDATED' => NotificationType.statusUpdated,
    'REQUEST_CANCELLED' => NotificationType.requestCancelled,
    _ => NotificationType.unknown,
  };
}
