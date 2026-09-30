import 'package:flutter/foundation.dart';

class MissedCall {
  const MissedCall({
    required this.id,
    required this.requestId,
    required this.callerName,
    this.callerPhotoUrl,
    required this.timestamp,
  });

  final String id;
  final int requestId;
  final String callerName;
  final String? callerPhotoUrl;
  final DateTime timestamp;
}

class MissedCallService {
  MissedCallService._();

  static final MissedCallService instance = MissedCallService._();

  final ValueNotifier<List<MissedCall>> missedCalls = ValueNotifier<List<MissedCall>>(<MissedCall>[]);

  void addMissedCall({
    required int requestId,
    required String callerName,
    String? callerPhotoUrl,
  }) {
    final MissedCall call = MissedCall(
      id: '${requestId}_${DateTime.now().millisecondsSinceEpoch}',
      requestId: requestId,
      callerName: callerName,
      callerPhotoUrl: callerPhotoUrl,
      timestamp: DateTime.now(),
    );

    final List<MissedCall> current = List<MissedCall>.from(missedCalls.value);
    current.insert(0, call);
    missedCalls.value = current;
  }

  void removeCall(String id) {
    final List<MissedCall> current = List<MissedCall>.from(missedCalls.value);
    current.removeWhere((MissedCall c) => c.id == id);
    missedCalls.value = current;
  }

  void clearAll() {
    missedCalls.value = <MissedCall>[];
  }
}
