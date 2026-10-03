import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/api_client.dart';
import '../../core/app_colors.dart';
import '../../core/notification_service.dart';
import '../../core/session.dart';
import '../../core/websocket_service.dart';
import '../../models/assistance_request.dart';
import '../../models/call_signal.dart';
import '../../models/call_token.dart';
import '../../models/chat_message.dart';
import '../../models/notification_message.dart';
import '../../services/assistance_request_api.dart';
import '../../services/call_api.dart';
import '../../services/missed_call_service.dart';
import '../../services/workshop_notification_service.dart';
import '../../widgets/incoming_call_dialog.dart';
import '../call_screen.dart';
import '../chat_screen.dart';

const Set<String> _trackableStatuses = <String>{'PENDING', 'ACCEPTED', 'EN_ROUTE'};

/// "Requests" tab — incoming roadside-assistance requests, with
/// accept/decline/en-route/complete actions driven by the backend's
/// [AssistanceRequestStatus] state machine.
class WorkshopRequestsScreen extends StatefulWidget {
  const WorkshopRequestsScreen({super.key});

  @override
  State<WorkshopRequestsScreen> createState() => _WorkshopRequestsScreenState();
}

class _WorkshopRequestsScreenState extends State<WorkshopRequestsScreen> {
  late Future<List<AssistanceRequest>> _requestsFuture;
  List<AssistanceRequest> _requests = <AssistanceRequest>[];
  final Set<int> _updatingIds = <int>{};
  final Set<int> _startingCallIds = <int>{};
  Timer? _liveTrackingTimer;
  StreamSubscription<NotificationMessage>? _notificationSub;
  StreamSubscription<CallSignal>? _callSignalSub;
  StreamSubscription<ChatMessage>? _chatMessageSub;

  @override
  void initState() {
    super.initState();
    _load();
    // Keeps any trackable request's mini-map in sync with the driver's
    // periodic position pushes without the owner having to pull-to-refresh.
    _liveTrackingTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (_requests.any((AssistanceRequest r) => _trackableStatuses.contains(r.status))) {
        _silentRefresh();
      }
    });

    // connect() is a no-op if the driver dashboard (or a prior mount of
    // this screen) already opened the connection this session.
    WebSocketService.instance.connect();
    _notificationSub = WebSocketService.instance.notifications.listen(_onNotification);
    _callSignalSub = WebSocketService.instance.callSignals.listen(_onCallSignal);
    _chatMessageSub = WebSocketService.instance.chatMessages.listen(_onChatMessage);
  }

  @override
  void dispose() {
    _liveTrackingTimer?.cancel();
    _notificationSub?.cancel();
    _callSignalSub?.cancel();
    _chatMessageSub?.cancel();
    super.dispose();
  }

  void _onCallSignal(CallSignal signal) {
    if (signal.type != CallSignalType.callInvite || !mounted) return;
    IncomingCallDialog.show(context, signal);
  }

  void _onChatMessage(ChatMessage message) {
    if (message.senderId == Session.instance.userId || message.isDeleted) return;
    NotificationService.showChatMessage(
      requestId: message.requestId,
      senderName: message.senderName,
      content: message.previewText,
    );
    WorkshopNotificationService.instance.addNewMessage(
      requestId: message.requestId,
      senderName: message.senderName,
      previewText: message.previewText,
    );
  }

  Future<void> _startCall(AssistanceRequest request) async {
    if (_startingCallIds.contains(request.id)) return;
    setState(() => _startingCallIds.add(request.id));
    try {
      final CallToken token = await CallApi.start(request.id);
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (BuildContext _) => CallScreen(
          token: token,
          otherPartyName: request.driverName,
        ),
      ));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Couldn\'t start the call: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _startingCallIds.remove(request.id));
    }
  }

  void _openChat(AssistanceRequest request) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (BuildContext _) => ChatScreen(
        requestId: request.id,
        otherPartyName: request.driverName,
      ),
    ));
  }

  Future<void> _startCallByName(int requestId, String callerName) async {
    try {
      final CallToken token = await CallApi.start(requestId);
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (BuildContext _) => CallScreen(
          token: token,
          otherPartyName: callerName,
        ),
      ));
    } catch (_) {
      if (!mounted) return;
      final CallToken fallbackToken = CallToken(
        appId: '1f10928230b3438096f4dd71a1fa9300',
        channel: 'request_$requestId',
        token: '',
        uid: 0,
      );
      Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (BuildContext _) => CallScreen(
          token: fallbackToken,
          otherPartyName: callerName,
        ),
      ));
    }
  }

  void _openChatByName(int requestId, String callerName) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (BuildContext _) => ChatScreen(
        requestId: requestId,
        otherPartyName: callerName,
      ),
    ));
  }

  /// A new request or a driver-side cancellation — refresh immediately
  /// rather than waiting for the next 15s poll. Simpler than reconstructing
  /// a full [AssistanceRequest] from the notification's terse payload.
  void _onNotification(NotificationMessage message) {
    _silentRefresh();
    if (!mounted || message.type != NotificationType.newRequest) return;
    if (message.requestId != null) {
      WorkshopNotificationService.instance.addNewRequest(
        requestId: message.requestId!,
        message: message.message,
      );
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.primaryBlue,
        behavior: SnackBarBehavior.floating,
        content: Text(message.message),
      ),
    );
  }

  void _load() {
    _requestsFuture = AssistanceRequestApi.listForMyWorkshop().then((List<AssistanceRequest> requests) {
      _requests = requests;
      return requests;
    });
  }

  Future<void> _refresh() async {
    setState(_load);
    await _requestsFuture;
  }

  Future<void> _silentRefresh() async {
    try {
      final List<AssistanceRequest> requests = await AssistanceRequestApi.listForMyWorkshop();
      if (mounted) setState(() => _requests = requests);
    } catch (_) {
      // Silent by design — this is a background poll, not a user action.
    }
  }

  Future<void> _updateStatus(AssistanceRequest request, AssistanceRequestStatus status) async {
    setState(() => _updatingIds.add(request.id));
    try {
      final AssistanceRequest updated = await AssistanceRequestApi.updateStatus(
        requestId: request.id,
        status: status,
      );
      if (!mounted) return;
      setState(() {
        final int index = _requests.indexWhere((AssistanceRequest r) => r.id == request.id);
        if (index != -1) _requests[index] = updated;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          content: Text(error.message),
        ),
      );
    } finally {
      if (mounted) setState(() => _updatingIds.remove(request.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 12, 18, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Requests',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primaryText),
                ),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<AssistanceRequest>>(
                future: _requestsFuture,
                builder: (BuildContext context, AsyncSnapshot<List<AssistanceRequest>> snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    final String message = snapshot.error is ApiException
                        ? (snapshot.error! as ApiException).message
                        : 'Failed to load requests.';
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.secondaryText)),
                            const SizedBox(height: 12),
                            FilledButton(onPressed: _refresh, child: const Text('Retry')),
                          ],
                        ),
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
                      children: <Widget>[
                        _MissedCallsSection(
                          onCall: _startCallByName,
                          onChat: _openChatByName,
                        ),
                        if (_requests.isEmpty)
                          _EmptyState(onRefresh: _refresh)
                        else
                          for (final AssistanceRequest request in _requests) ...<Widget>[
                            _RequestCard(
                              request: request,
                              isUpdating: _updatingIds.contains(request.id),
                              isCalling: _startingCallIds.contains(request.id),
                              onAccept: () => _updateStatus(request, AssistanceRequestStatus.accepted),
                              onDecline: () => _updateStatus(request, AssistanceRequestStatus.cancelled),
                              onStartEnRoute: () => _updateStatus(request, AssistanceRequestStatus.enRoute),
                              onComplete: () => _updateStatus(request, AssistanceRequestStatus.completed),
                              onCall: () => _startCall(request),
                              onChat: () => _openChat(request),
                            ),
                            const SizedBox(height: 10),
                          ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 72,
                  height: 72,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(color: AppColors.badgeSoft, shape: BoxShape.circle),
                  child: const Icon(Icons.build_outlined, size: 32, color: AppColors.primaryBlue),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No roadside assistance requests.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.primaryText),
                ),
                const SizedBox(height: 6),
                const Text(
                  'New requests from drivers nearby will show up here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12.5, color: AppColors.secondaryText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.request,
    required this.isUpdating,
    required this.isCalling,
    required this.onAccept,
    required this.onDecline,
    required this.onStartEnRoute,
    required this.onComplete,
    required this.onCall,
    required this.onChat,
  });

  final AssistanceRequest request;
  final bool isUpdating;
  final bool isCalling;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback onStartEnRoute;
  final VoidCallback onComplete;
  final VoidCallback onCall;
  final VoidCallback onChat;

  Color get _statusColor => switch (request.status) {
    'PENDING' => AppColors.warningOrange,
    'ACCEPTED' => AppColors.primaryBlue,
    'EN_ROUTE' => AppColors.secondaryCyan,
    'COMPLETED' => AppColors.accentGreen,
    _ => AppColors.secondaryText,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                child: Text(
                  request.driverName,
                  style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.primaryText),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: _statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                child: Text(
                  request.status.replaceAll('_', ' '),
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: _statusColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(request.driverPhone, style: const TextStyle(fontSize: 12.5, color: AppColors.secondaryText)),
          if (request.description != null && request.description!.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Text(request.description!, style: const TextStyle(fontSize: 12.5, color: AppColors.primaryText)),
          ],
          if (_trackableStatuses.contains(request.status)) ...<Widget>[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                height: 110,
                width: double.infinity,
                child: IgnorePointer(
                  child: GoogleMap(
                    key: ValueKey(
                      '${request.id}-${request.driverLatitude}-${request.driverLongitude}',
                    ),
                    initialCameraPosition: CameraPosition(
                      target: LatLng(request.driverLatitude.toDouble(), request.driverLongitude.toDouble()),
                      zoom: 14,
                    ),
                    zoomControlsEnabled: false,
                    scrollGesturesEnabled: false,
                    zoomGesturesEnabled: false,
                    rotateGesturesEnabled: false,
                    tiltGesturesEnabled: false,
                    markers: <Marker>{
                      Marker(
                        markerId: MarkerId('driver-${request.id}'),
                        position: LatLng(request.driverLatitude.toDouble(), request.driverLongitude.toDouble()),
                      ),
                    },
                  ),
                ),
              ),
            ),
          ] else ...<Widget>[
            const SizedBox(height: 6),
            Text(
              '${request.driverLatitude.toStringAsFixed(4)}, ${request.driverLongitude.toStringAsFixed(4)}',
              style: const TextStyle(fontSize: 11.5, color: AppColors.secondaryText),
            ),
          ],
          const SizedBox(height: 12),
          if (isUpdating)
            const Center(child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2.2)))
          else
            Row(
              children: <Widget>[
                if (request.status == 'PENDING') ...<Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onDecline,
                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.dangerRed),
                      child: const Text('Decline'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: onAccept,
                      style: FilledButton.styleFrom(backgroundColor: AppColors.primaryBlue),
                      child: const Text('Accept'),
                    ),
                  ),
                ] else if (request.status == 'ACCEPTED') ...<Widget>[
                  _ChatIconButton(onChat: onChat),
                  const SizedBox(width: 8),
                  _CallIconButton(isCalling: isCalling, onCall: onCall),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: onStartEnRoute,
                      style: FilledButton.styleFrom(backgroundColor: AppColors.secondaryCyan),
                      child: const Text('Start En Route'),
                    ),
                  ),
                ] else if (request.status == 'EN_ROUTE') ...<Widget>[
                  _ChatIconButton(onChat: onChat),
                  const SizedBox(width: 8),
                  _CallIconButton(isCalling: isCalling, onCall: onCall),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: onComplete,
                      style: FilledButton.styleFrom(backgroundColor: AppColors.accentGreen),
                      child: const Text('Mark Completed'),
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _CallIconButton extends StatelessWidget {
  const _CallIconButton({required this.isCalling, required this.onCall});

  final bool isCalling;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: isCalling
          ? const Center(child: SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)))
          : IconButton(
              onPressed: onCall,
              icon: const Icon(Icons.call, color: AppColors.primaryBlue, size: 22),
              tooltip: 'Call driver',
              visualDensity: VisualDensity.compact,
            ),
    );
  }
}

class _ChatIconButton extends StatelessWidget {
  const _ChatIconButton({required this.onChat});

  final VoidCallback onChat;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.accentGreen.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: IconButton(
        onPressed: onChat,
        icon: const Icon(Icons.chat_bubble_outline, color: AppColors.accentGreen, size: 21),
        tooltip: 'Message driver',
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

class _MissedCallsSection extends StatelessWidget {
  const _MissedCallsSection({required this.onCall, required this.onChat});

  final void Function(int requestId, String callerName) onCall;
  final void Function(int requestId, String callerName) onChat;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<MissedCall>>(
      valueListenable: MissedCallService.instance.missedCalls,
      builder: (BuildContext context, List<MissedCall> missedList, Widget? _) {
        if (missedList.isEmpty) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.dangerRed.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.dangerRed.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Icon(Icons.phone_missed, color: AppColors.dangerRed, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Missed Calls (${missedList.length})',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.dangerRed,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => MissedCallService.instance.clearAll(),
                    child: const Text('Clear All', style: TextStyle(fontSize: 12, color: AppColors.secondaryText)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              for (final MissedCall call in missedList) ...<Widget>[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: <Widget>[
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.badgeSoft,
                        child: Text(
                          call.callerName.isNotEmpty ? call.callerName[0].toUpperCase() : '?',
                          style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primaryBlue),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              call.callerName,
                              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.heading),
                            ),
                            Text(
                              'Missed call at ${_formatTime(call.timestamp)}',
                              style: const TextStyle(fontSize: 11.5, color: AppColors.secondaryText),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chat_bubble_outline, color: AppColors.accentGreen, size: 20),
                        tooltip: 'Send message',
                        onPressed: () => onChat(call.requestId, call.callerName),
                      ),
                      IconButton(
                        icon: const Icon(Icons.call, color: AppColors.primaryBlue, size: 20),
                        tooltip: 'Call back',
                        onPressed: () => onCall(call.requestId, call.callerName),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        );
      },
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
