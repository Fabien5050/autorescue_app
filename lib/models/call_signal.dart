/// A voice-call signal delivered over the WebSocket, mirroring the
/// backend's `CallSignal` record — separate from [NotificationMessage]
/// since Agora's RTC engine carries the audio itself once both sides join
/// the channel; this is only ever used to trigger that.
class CallSignal {
  const CallSignal({
    required this.type,
    required this.requestId,
    required this.callerId,
    required this.callerName,
    this.callerPhotoUrl,
    required this.channelName,
    required this.timestamp,
  });

  final CallSignalType type;
  final int requestId;
  final int callerId;
  final String callerName;
  final String? callerPhotoUrl;
  final String channelName;
  final DateTime timestamp;

  factory CallSignal.fromJson(Map<String, dynamic> json) {
    return CallSignal(
      type: CallSignalType.fromWire(json['type'] as String),
      requestId: json['requestId'] as int,
      callerId: json['callerId'] as int,
      callerName: json['callerName'] as String,
      callerPhotoUrl: json['callerPhotoUrl'] as String?,
      channelName: json['channelName'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

enum CallSignalType {
  callInvite,
  callDeclined,
  unknown;

  static CallSignalType fromWire(String wire) => switch (wire) {
    'CALL_INVITE' => CallSignalType.callInvite,
    'CALL_DECLINED' => CallSignalType.callDeclined,
    _ => CallSignalType.unknown,
  };
}
