/// A chat message on an assistance request, mirroring the backend's
/// `ChatMessageResponse`.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.requestId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.sentAt,
    this.deliveredAt,
    this.readAt,
  });

  final int id;
  final int requestId;
  final int senderId;
  final String senderName;
  final String content;
  final DateTime sentAt;

  /// Set once the recipient's app has actually received this over the
  /// WebSocket — null means only "sent" (single tick).
  final DateTime? deliveredAt;

  /// Set once the recipient has opened the thread — null means not yet
  /// read (double tick, gray, if delivered; blue once this is set).
  final DateTime? readAt;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as int,
      requestId: json['requestId'] as int,
      senderId: json['senderId'] as int,
      senderName: json['senderName'] as String,
      content: json['content'] as String,
      sentAt: DateTime.parse(json['sentAt'] as String),
      deliveredAt: json['deliveredAt'] == null ? null : DateTime.parse(json['deliveredAt'] as String),
      readAt: json['readAt'] == null ? null : DateTime.parse(json['readAt'] as String),
    );
  }
}
