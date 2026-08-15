import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/api_client.dart';
import '../../core/app_colors.dart';
import '../../core/websocket_service.dart';
import '../../models/assistance_request.dart';
import '../../models/call_signal.dart';
import '../../models/call_token.dart';
import '../../models/notification_message.dart';
import '../../services/assistance_request_api.dart';
import '../../services/call_api.dart';
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
  }

  @override
  void dispose() {
    _liveTrackingTimer?.cancel();
    _notificationSub?.cancel();
    _callSignalSub?.cancel();
    super.dispose();
  }

  void _onCallSignal(CallSignal signal) {
    if (signal.type != CallSignalType.callInvite || !mounted) return;
    IncomingCallDialog.show(context, signal);
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

  /// A new request or a driver-side cancellation — refresh immediately
  /// rather than waiting for the next 15s poll. Simpler than reconstructing
  /// a full [AssistanceRequest] from the notification's terse payload.
  void _onNotification(NotificationMessage message) {
    _silentRefresh();
    if (!mounted || message.type != NotificationType.newRequest) return;
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
                  if (_requests.isEmpty) return _EmptyState(onRefresh: _refresh);

                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
                      itemCount: _requests.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (BuildContext context, int index) {
                        final AssistanceRequest request = _requests[index];
                        return _RequestCard(
                          request: request,
                          isUpdating: _updatingIds.contains(request.id),
                          isCalling: _startingCallIds.contains(request.id),
                          onAccept: () => _updateStatus(request, AssistanceRequestStatus.accepted),
                          onDecline: () => _updateStatus(request, AssistanceRequestStatus.cancelled),
                          onStartEnRoute: () => _updateStatus(request, AssistanceRequestStatus.enRoute),
                          onComplete: () => _updateStatus(request, AssistanceRequestStatus.completed),
                          onCall: () => _startCall(request),
                          onChat: () => _openChat(request),
                        );
                      },
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
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: isCalling
          ? const Center(child: SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)))
          : IconButton(
              onPressed: onCall,
              icon: const Icon(Icons.call, color: AppColors.primaryBlue, size: 20),
              tooltip: 'Call driver',
              visualDensity: VisualDensity.compact,
            ),
    );
  }
}
