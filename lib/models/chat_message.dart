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
  });

  final int id;
  final int requestId;
  final int senderId;
  final String senderName;
  final String content;
  final DateTime sentAt;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as int,
      requestId: json['requestId'] as int,
      senderId: json['senderId'] as int,
      senderName: json['senderName'] as String,
      content: json['content'] as String,
      sentAt: DateTime.parse(json['sentAt'] as String),
    );
  }
}
