import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../screens/chat_screen.dart';
import 'app_navigator.dart';

/// Local (device-tray) notifications for the app's two real-time surfaces:
/// a new chat message — tapping it opens that conversation directly via
/// [AppNavigator], regardless of what screen the app happens to be on — and
/// an incoming call, shown alongside [RingtoneService]'s vibration pattern.
///
/// This only works while the app process is alive (foreground or recently
/// backgrounded) since delivery rides on the same STOMP WebSocket
/// connection as everything else here — a fully closed app won't receive
/// these until a push-notification (FCM) layer is added on top, which is a
/// separate, considerably larger project.
class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  /// The request whose chat thread is currently open on screen — new
  /// messages for it are already visible live, so a tray notification
  /// would just be noise.
  static int? _openChatRequestId;

  static const AndroidNotificationDetails _chatChannel = AndroidNotificationDetails(
    'chat_messages',
    'Chat messages',
    channelDescription: 'New messages from your driver or mechanic',
    importance: Importance.high,
    priority: Priority.high,
  );

  static const AndroidNotificationDetails _callChannel = AndroidNotificationDetails(
    'incoming_calls',
    'Incoming calls',
    channelDescription: 'Voice call invitations from your driver or mechanic',
    importance: Importance.max,
    priority: Priority.high,
  );

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _onTap,
    );

    final AndroidFlutterLocalNotificationsPlugin? android =
        _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
  }

  static void setOpenChat(int? requestId) => _openChatRequestId = requestId;

  static void _onTap(NotificationResponse response) {
    final String? payload = response.payload;
    if (payload == null) return;
    final Map<String, dynamic> data = jsonDecode(payload) as Map<String, dynamic>;
    if (data['type'] == 'chat') {
      AppNavigator.state?.push(MaterialPageRoute<void>(
        builder: (BuildContext _) => ChatScreen(
          requestId: data['requestId'] as int,
          otherPartyName: data['otherPartyName'] as String,
        ),
      ));
    }
  }

  static Future<void> showChatMessage({
    required int requestId,
    required String senderName,
    required String content,
  }) {
    if (!_initialized || requestId == _openChatRequestId) return Future<void>.value();
    return _plugin.show(
      requestId,
      senderName,
      content,
      const NotificationDetails(android: _chatChannel),
      payload: jsonEncode(<String, dynamic>{
        'type': 'chat',
        'requestId': requestId,
        'otherPartyName': senderName,
      }),
    );
  }

  static Future<void> showIncomingCall({required int requestId, required String callerName}) {
    if (!_initialized) return Future<void>.value();
    return _plugin.show(
      1000000 + requestId,
      'Incoming call',
      '$callerName is calling…',
      const NotificationDetails(android: _callChannel),
    );
  }

  static Future<void> cancelIncomingCall(int requestId) {
    if (!_initialized) return Future<void>.value();
    return _plugin.cancel(1000000 + requestId);
  }
}
