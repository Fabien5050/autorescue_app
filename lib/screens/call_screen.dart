import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/api_config.dart';
import '../core/app_colors.dart';
import '../models/call_token.dart';

/// In-call screen for both sides of an Agora voice call — the caller
/// arrives here right after [CallApi.start], the callee right after
/// accepting an incoming call and calling [CallApi.join]. Either way this
/// only cares about the Agora session itself, not who initiated it.
class CallScreen extends StatefulWidget {
  const CallScreen({
    super.key,
    required this.token,
    required this.otherPartyName,
    this.otherPartyPhotoUrl,
  });

  final CallToken token;
  final String otherPartyName;
  final String? otherPartyPhotoUrl;

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  RtcEngine? _engine;
  bool _remoteJoined = false;
  bool _muted = false;
  bool _speakerOn = false;
  bool _leaving = false;
  String _status = 'Connecting…';
  Timer? _durationTimer;
  Duration _callDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _setup();
  }

  Future<void> _setup() async {
    final PermissionStatus micStatus = await Permission.microphone.request();
    if (!mounted) return;
    if (!micStatus.isGranted) {
      setState(() => _status = 'Microphone permission is required for calls');
      return;
    }

    final RtcEngine engine = createAgoraRtcEngine();
    await engine.initialize(RtcEngineContext(appId: widget.token.appId));
    await engine.enableAudio();
    engine.registerEventHandler(RtcEngineEventHandler(
      onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
        if (!mounted) return;
        setState(() => _status = 'Ringing…');
      },
      onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
        if (!mounted) return;
        setState(() {
          _remoteJoined = true;
          _status = 'Connected';
        });
        _startTimer();
      },
      onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
        if (!mounted) return;
        Navigator.of(context).maybePop();
      },
      onError: (ErrorCodeType err, String msg) {
        if (!mounted) return;
        setState(() => _status = 'Call error — ${err.name}');
      },
    ));

    await engine.joinChannel(
      token: widget.token.token,
      channelId: widget.token.channel,
      uid: widget.token.uid,
      options: const ChannelMediaOptions(
        channelProfile: ChannelProfileType.channelProfileCommunication,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
      ),
    );

    if (!mounted) {
      await engine.leaveChannel();
      await engine.release();
      return;
    }
    _engine = engine;
  }

  void _startTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (Timer _) {
      if (!mounted) return;
      setState(() => _callDuration += const Duration(seconds: 1));
    });
  }

  Future<void> _toggleMute() async {
    final bool next = !_muted;
    await _engine?.muteLocalAudioStream(next);
    if (mounted) setState(() => _muted = next);
  }

  Future<void> _toggleSpeaker() async {
    final bool next = !_speakerOn;
    await _engine?.setEnableSpeakerphone(next);
    if (mounted) setState(() => _speakerOn = next);
  }

  /// Cancels the timer and hands the engine off to a fire-and-forget
  /// teardown — leaveChannel()/release() can hang or throw depending on
  /// connection state, and none of that should be able to block the UI.
  /// Called from [PopScope]'s callback, never directly from the end-call
  /// button — that button just pops, same as the system back gesture.
  void _cleanup() {
    if (_leaving) return;
    _leaving = true;
    _durationTimer?.cancel();
    final RtcEngine? engine = _engine;
    _engine = null;
    unawaited(_teardownEngine(engine));
  }

  Future<void> _teardownEngine(RtcEngine? engine) async {
    if (engine == null) return;
    try {
      await engine.leaveChannel();
      await engine.release();
    } catch (_) {
      // Best-effort — the call screen is already closed either way.
    }
  }

  @override
  void dispose() {
    // Safety net in case the widget leaves the tree some other way (e.g. a
    // parent navigator reset) without PopScope's callback ever firing.
    _cleanup();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final String minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final String seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final String? photoUrl = ApiConfig.resolveFileUrl(widget.otherPartyPhotoUrl);
    return PopScope(
      // Always allowed to pop now — cleanup is fire-and-forget and doesn't
      // need to gate navigation, so there's nothing left to block. Blocking
      // it was the actual bug: it intercepted the end-call button's own
      // pop the same way it intercepted the system back gesture, and the
      // resulting re-entrant call was a silent no-op, so the screen never
      // closed either way.
      canPop: true,
      onPopInvokedWithResult: (bool didPop, Object? _) {
        if (didPop) _cleanup();
      },
      child: Scaffold(
        backgroundColor: AppColors.navy,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              children: <Widget>[
                const Spacer(),
                CircleAvatar(
                  radius: 64,
                  backgroundColor: Colors.white24,
                  backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                  child: photoUrl == null
                      ? Text(
                          widget.otherPartyName.isNotEmpty ? widget.otherPartyName[0].toUpperCase() : '?',
                          style: const TextStyle(fontSize: 40, color: Colors.white),
                        )
                      : null,
                ),
                const SizedBox(height: 20),
                Text(
                  widget.otherPartyName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  _remoteJoined ? _formatDuration(_callDuration) : _status,
                  style: const TextStyle(fontSize: 16, color: Colors.white70),
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    _CallControlButton(
                      icon: _muted ? Icons.mic_off : Icons.mic,
                      active: _muted,
                      onTap: _toggleMute,
                    ),
                    _CallControlButton(
                      icon: Icons.call_end,
                      background: AppColors.dangerRed,
                      large: true,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    _CallControlButton(
                      icon: Icons.volume_up,
                      active: _speakerOn,
                      onTap: _toggleSpeaker,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CallControlButton extends StatelessWidget {
  const _CallControlButton({
    required this.icon,
    required this.onTap,
    this.active = false,
    this.background,
    this.large = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool active;
  final Color? background;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final double size = large ? 68 : 56;
    final Color fill = background ?? (active ? Colors.white : Colors.white24);
    final Color iconColor = background != null ? Colors.white : (active ? AppColors.navy : Colors.white);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(size),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
        child: Icon(icon, color: iconColor, size: large ? 32 : 26),
      ),
    );
  }
}
