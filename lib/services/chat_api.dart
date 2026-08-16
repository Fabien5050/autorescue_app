import '../core/api_client.dart';
import '../models/chat_message.dart';

class ChatApi {
  ChatApi._();

  static Future<List<ChatMessage>> list(int requestId) async {
    final dynamic json = await ApiClient.get('/api/requests/$requestId/messages');
    return (json as List<dynamic>)
        .map((dynamic e) => ChatMessage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<ChatMessage> send(int requestId, String content) async {
    final dynamic json = await ApiClient.post(
      '/api/requests/$requestId/messages',
      <String, dynamic>{'content': content},
    );
    return ChatMessage.fromJson(json as Map<String, dynamic>);
  }

  static Future<ChatMessage> sendImage({
    required int requestId,
    required List<int> fileBytes,
    required String fileName,
  }) async {
    final dynamic json = await ApiClient.postMultipart(
      '/api/requests/$requestId/messages/image',
      fields: const <String, String>{},
      fileBytes: fileBytes,
      fileName: fileName,
    );
    return ChatMessage.fromJson(json as Map<String, dynamic>);
  }

  /// Only the sender may delete their own message — the backend soft-deletes
  /// it and pushes the update to both sides, so the caller doesn't need to
  /// separately remove it from its own local list.
  static Future<ChatMessage> delete(int requestId, int messageId) async {
    final dynamic json = await ApiClient.delete('/api/requests/$requestId/messages/$messageId');
    return ChatMessage.fromJson(json as Map<String, dynamic>);
  }

  /// Called the moment this device actually receives a message over the
  /// WebSocket — a real delivery confirmation for the sender's ticks.
  static Future<void> ackDelivered(int requestId, int messageId) async {
    await ApiClient.post('/api/requests/$requestId/messages/$messageId/delivered', <String, dynamic>{});
  }

  /// Called when the thread is opened — marks every unread message from
  /// the other side as read.
  static Future<void> markRead(int requestId) async {
    await ApiClient.post('/api/requests/$requestId/messages/read', <String, dynamic>{});
  }
}
