import '../core/api_client.dart';
import '../models/call_token.dart';

class CallApi {
  CallApi._();

  /// Caller: gets a token for itself and rings the other side.
  static Future<CallToken> start(int requestId) async {
    final dynamic json = await ApiClient.post('/api/requests/$requestId/calls/start', <String, dynamic>{});
    return CallToken.fromJson(json as Map<String, dynamic>);
  }

  /// Callee: gets a token to join the call already in progress, no ringing.
  static Future<CallToken> join(int requestId) async {
    final dynamic json = await ApiClient.post('/api/requests/$requestId/calls/join', <String, dynamic>{});
    return CallToken.fromJson(json as Map<String, dynamic>);
  }

  static Future<void> decline(int requestId) async {
    await ApiClient.post('/api/requests/$requestId/calls/decline', <String, dynamic>{});
  }
}
