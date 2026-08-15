import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:vibration/vibration.dart';

/// Vibration pattern for an incoming call — played while
/// [IncomingCallDialog] is showing, stopped the moment it's accepted,
/// declined, or dismissed. The audible cue comes from the local
/// notification shown alongside it (the device's own default notification
/// sound); this just supplies the "ringing" feel a silent phone would
/// otherwise miss entirely.
class RingtoneService {
  RingtoneService._();

  static bool _ringing = false;

  static Future<void> startRinging() async {
    if (_ringing || kIsWeb) return;
    _ringing = true;
    final bool hasVibrator = await Vibration.hasVibrator();
    if (!hasVibrator || !_ringing) return; // Stopped while awaiting the check.
    // Repeats from index 1 (skipping the initial silence) for a
    // ring-pause-ring-pause cadence until explicitly cancelled.
    unawaited(Vibration.vibrate(pattern: <int>[0, 700, 400, 700, 400], repeat: 1));
  }

  static void stopRinging() {
    if (!_ringing) return;
    _ringing = false;
    Vibration.cancel();
  }
}
