import 'dart:async';
import 'dart:convert';

import 'package:stomp_dart_client/stomp_dart_client.dart';

import '../models/admin_dashboard_summary.dart';
import '../models/notification_message.dart';
import 'api_config.dart';
import 'session.dart';

/// Single shared STOMP connection for this app's two real-time surfaces:
/// driver/workshop request notifications (`/queue/driver/{id}` or
/// `/queue/workshop/{id}`, chosen by [Session.role] at [connect] time) and
/// the admin dashboard's live summary (`/topic/admin/live-stats`).
///
/// Auth rides along as a `?token=` query parameter on the connection URL —
/// a WebSocket handshake can't carry a custom `Authorization` header, so
/// the backend's `JwtHandshakeInterceptor` reads it from there instead. The
/// underlying `stomp_dart_client` handles reconnection on its own
/// (`reconnectDelay` below); [connect] only needs to be called once per
/// session and is a no-op if already connected.
class WebSocketService {
  WebSocketService._();

  static final WebSocketService instance = WebSocketService._();

  StompClient? _client;
  final StreamController<NotificationMessage> _notifications = StreamController<NotificationMessage>.broadcast();
  final StreamController<AdminDashboardSummary> _liveStats = StreamController<AdminDashboardSummary>.broadcast();

  Stream<NotificationMessage> get notifications => _notifications.stream;
  Stream<AdminDashboardSummary> get liveStats => _liveStats.stream;

  bool get isConnected => _client?.connected ?? false;

  void connect() {
    if (_client != null) return; // Already connecting/connected this session.

    final String? token = Session.instance.token;
    final int? userId = Session.instance.userId;
    if (token == null || userId == null) return;

    final String role = Session.instance.role ?? '';
    final int? workshopId = Session.instance.workshopId;
    final String wsBase = ApiConfig.baseUrl.replaceFirst(RegExp(r'^http'), 'ws');

    _client = StompClient(
      config: StompConfig(
        url: '$wsBase/ws?token=$token',
        reconnectDelay: const Duration(seconds: 5),
        onConnect: (StompFrame _) {
          if (role == 'DRIVER') {
            _client?.subscribe(destination: '/queue/driver/$userId', callback: _handleNotificationFrame);
          } else if (role == 'MECHANIC' && workshopId != null) {
            _client?.subscribe(destination: '/queue/workshop/$workshopId', callback: _handleNotificationFrame);
          } else if (role == 'ADMIN') {
            _client?.subscribe(destination: '/topic/admin/live-stats', callback: _handleLiveStatsFrame);
          }
        },
        onWebSocketError: (dynamic _) {},
        onStompError: (StompFrame _) {},
      ),
    );
    _client?.activate();
  }

  void _handleNotificationFrame(StompFrame frame) {
    final String? body = frame.body;
    if (body == null) return;
    try {
      _notifications.add(NotificationMessage.fromJson(jsonDecode(body) as Map<String, dynamic>));
    } catch (_) {
      // Malformed/unexpected payload — drop it rather than crash the stream.
    }
  }

  void _handleLiveStatsFrame(StompFrame frame) {
    final String? body = frame.body;
    if (body == null) return;
    try {
      _liveStats.add(AdminDashboardSummary.fromJson(jsonDecode(body) as Map<String, dynamic>));
    } catch (_) {
      // Malformed/unexpected payload — drop it rather than crash the stream.
    }
  }

  /// Called on every logout path (driver, workshop owner, admin) so a
  /// signed-out session doesn't keep a live connection (and doesn't
  /// silently reconnect as whoever signs in next).
  void disconnect() {
    _client?.deactivate();
    _client = null;
  }
}
