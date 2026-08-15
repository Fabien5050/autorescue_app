/// Mirrors the backend's `CallTokenResponse` — everything needed to join
/// an Agora RTC channel for one call.
class CallToken {
  const CallToken({
    required this.appId,
    required this.channel,
    required this.token,
    required this.uid,
  });

  final String appId;
  final String channel;
  final String token;
  final int uid;

  factory CallToken.fromJson(Map<String, dynamic> json) {
    return CallToken(
      appId: json['appId'] as String,
      channel: json['channel'] as String,
      token: json['token'] as String,
      uid: json['uid'] as int,
    );
  }
}
