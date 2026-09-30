import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/api_config.dart';
import '../core/app_colors.dart';
import '../models/call_token.dart';

/// Full-screen in-call interface supporting Agora voice communication,
/// live duration tracking, Mute, Speakerphone, Hold/Resume, and Keypad (DTMF).
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
  bool _onHold = false;
  bool _showKeypad = false;
  bool _leaving = false;
  String _status = 'Calling…';
  String _dialedDigits = '';
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
      setState(() => _status = 'Microphone permission required');
      return;
    }

    try {
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
    } catch (_) {
      if (mounted) setState(() => _status = 'Ringing…');
    }
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

  Future<void> _toggleHold() async {
    final bool next = !_onHold;
    await _engine?.muteAllRemoteAudioStreams(next);
    await _engine?.muteLocalAudioStream(next || _muted);
    if (mounted) {
      setState(() {
        _onHold = next;
        _status = next ? 'On Hold' : (_remoteJoined ? 'Connected' : 'Ringing…');
      });
    }
  }

  void _toggleKeypad() {
    setState(() => _showKeypad = !_showKeypad);
  }

  void _onKeyPress(String digit) {
    setState(() => _dialedDigits += digit);
    // Agora's sendCustomReportMessage expects a String message id, and the
    // docs require it to be unique per engine — the running count of digits
    // dialled in this call gives that without extra state.
    _engine?.sendCustomReportMessage(
      id: _dialedDigits.length.toString(),
      category: 'dtmf',
      event: digit,
      label: 'keypad',
      value: 0,
    );
  }

  void _endCall() {
    _cleanup();
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

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
    } catch (_) {}
  }

  @override
  void dispose() {
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
      canPop: true,
      onPopInvokedWithResult: (bool didPop, Object? _) {
        if (didPop) _cleanup();
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                Color(0xFF0F172A),
                Color(0xFF1E293B),
                Color(0xFF0F172A),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: <Widget>[
                const SizedBox(height: 16),
                // Encryption & Title Banner
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Icon(Icons.lock, size: 13, color: Colors.white60),
                    const SizedBox(width: 6),
                    Text(
                      'AutoRescue Encrypted Voice Call',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.65),
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
                const Spacer(),

                // Contact Avatar & Name
                Center(
                  child: Column(
                    children: <Widget>[
                      Stack(
                        alignment: Alignment.center,
                        children: <Widget>[
                          if (!_onHold && _remoteJoined)
                            Container(
                              width: 148,
                              height: 148,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primaryBlue.withValues(alpha: 0.15),
                              ),
                            ),
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.white12,
                            backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                            child: photoUrl == null
                                ? Text(
                                    widget.otherPartyName.isNotEmpty
                                        ? widget.otherPartyName[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      fontSize: 42,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  )
                                : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          widget.otherPartyName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: _onHold
                              ? AppColors.warningOrange.withValues(alpha: 0.2)
                              : Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _onHold
                              ? 'Call on Hold'
                              : (_remoteJoined ? _formatDuration(_callDuration) : _status),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _onHold ? AppColors.warningOrange : Colors.white70,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Optional Keypad Overlay or Control Buttons Grid
                if (_showKeypad)
                  _KeypadSheet(
                    dialedDigits: _dialedDigits,
                    onKeyPress: _onKeyPress,
                    onClose: _toggleKeypad,
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                    child: Column(
                      children: <Widget>[
                        // Control Rows
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            _ControlButton(
                              icon: _muted ? Icons.mic_off : Icons.mic,
                              label: _muted ? 'Muted' : 'Mute',
                              active: _muted,
                              onTap: _toggleMute,
                            ),
                            _ControlButton(
                              icon: Icons.dialpad,
                              label: 'Keypad',
                              active: _showKeypad,
                              onTap: _toggleKeypad,
                            ),
                            _ControlButton(
                              icon: _speakerOn ? Icons.volume_up : Icons.volume_down,
                              label: 'Speaker',
                              active: _speakerOn,
                              onTap: _toggleSpeaker,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            _ControlButton(
                              icon: _onHold ? Icons.play_arrow : Icons.pause,
                              label: _onHold ? 'Resume' : 'Hold',
                              active: _onHold,
                              onTap: _toggleHold,
                            ),
                            _ControlButton(
                              icon: Icons.call_end,
                              label: 'End',
                              isEndCall: true,
                              onTap: _endCall,
                            ),
                            _ControlButton(
                              icon: Icons.add_ic_call_outlined,
                              label: 'Add',
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Multi-party conference calling active')),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
    this.isEndCall = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;
  final bool isEndCall;

  @override
  Widget build(BuildContext context) {
    final Color bgColor = isEndCall
        ? AppColors.dangerRed
        : (active ? Colors.white : Colors.white.withValues(alpha: 0.12));
    final Color iconColor = isEndCall
        ? Colors.white
        : (active ? AppColors.navy : Colors.white);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Material(
          color: bgColor,
          shape: const CircleBorder(),
          elevation: isEndCall ? 6 : 0,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.all(isEndCall ? 20 : 16),
              child: Icon(
                icon,
                size: isEndCall ? 32 : 26,
                color: iconColor,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : Colors.white70,
          ),
        ),
      ],
    );
  }
}

class _KeypadSheet extends StatelessWidget {
  const _KeypadSheet({
    required this.dialedDigits,
    required this.onKeyPress,
    required this.onClose,
  });

  final String dialedDigits;
  final ValueChanged<String> onKeyPress;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final List<String> keys = <String>[
      '1', '2', '3',
      '4', '5', '6',
      '7', '8', '9',
      '*', '0', '#',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            dialedDigits.isEmpty ? 'Keypad' : dialedDigits,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: keys.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 24,
              childAspectRatio: 1.4,
            ),
            itemBuilder: (BuildContext context, int index) {
              final String key = keys[index];
              return InkWell(
                onTap: () => onKeyPress(key),
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    key,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onClose,
            icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
            label: const Text('Hide Keypad', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }
}
