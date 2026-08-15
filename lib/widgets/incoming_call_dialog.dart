import 'package:flutter/material.dart';

import '../core/api_config.dart';
import '../core/app_colors.dart';
import '../core/notification_service.dart';
import '../core/ringtone_service.dart';
import '../models/call_signal.dart';
import '../models/call_token.dart';
import '../screens/call_screen.dart';
import '../services/call_api.dart';

/// Full-screen-blocking dialog shown the moment a [CallSignal.callInvite]
/// arrives over the WebSocket — accepting joins the same Agora channel the
/// caller already started; declining just tells the caller's app to stop
/// ringing.
class IncomingCallDialog {
  IncomingCallDialog._();

  static Future<void> show(BuildContext context, CallSignal signal) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => _IncomingCallSheet(signal: signal),
    );
  }
}

class _IncomingCallSheet extends StatefulWidget {
  const _IncomingCallSheet({required this.signal});

  final CallSignal signal;

  @override
  State<_IncomingCallSheet> createState() => _IncomingCallSheetState();
}

class _IncomingCallSheetState extends State<_IncomingCallSheet> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    RingtoneService.startRinging();
    NotificationService.showIncomingCall(
      requestId: widget.signal.requestId,
      callerName: widget.signal.callerName,
    );
  }

  @override
  void dispose() {
    RingtoneService.stopRinging();
    NotificationService.cancelIncomingCall(widget.signal.requestId);
    super.dispose();
  }

  Future<void> _accept() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final CallToken token = await CallApi.join(widget.signal.requestId);
      if (!mounted) return;
      Navigator.of(context).pop();
      Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (BuildContext _) => CallScreen(
          token: token,
          otherPartyName: widget.signal.callerName,
          otherPartyPhotoUrl: widget.signal.callerPhotoUrl,
        ),
      ));
    } catch (_) {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _decline() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await CallApi.decline(widget.signal.requestId);
    } catch (_) {
      // Best-effort — dismiss regardless so the sheet isn't stuck open.
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final String? photoUrl = ApiConfig.resolveFileUrl(widget.signal.callerPhotoUrl);
    return PopScope(
      canPop: false,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.badgeSoft,
                backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                child: photoUrl == null
                    ? Text(
                        widget.signal.callerName.isNotEmpty ? widget.signal.callerName[0].toUpperCase() : '?',
                        style: const TextStyle(fontSize: 28, color: AppColors.primaryBlue),
                      )
                    : null,
              ),
              const SizedBox(height: 16),
              Text(widget.signal.callerName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('Incoming voice call', style: TextStyle(color: AppColors.secondaryText)),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  _ActionButton(
                    icon: Icons.call_end,
                    label: 'Decline',
                    color: AppColors.dangerRed,
                    onTap: _busy ? null : _decline,
                  ),
                  _ActionButton(
                    icon: Icons.call,
                    label: 'Accept',
                    color: AppColors.accentGreen,
                    onTap: _busy ? null : _accept,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(32),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}
