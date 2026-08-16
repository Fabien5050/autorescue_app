/// Mirrors the backend's `ChatMessage.MessageType` enum.
enum ChatMessageType { text, image }

/// A chat message on an assistance request, mirroring the backend's
/// `ChatMessageResponse`.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.requestId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.type,
    required this.sentAt,
    this.deliveredAt,
    this.readAt,
    this.deletedAt,
  });

  final int id;
  final int requestId;
  final int senderId;
  final String senderName;

  /// Plain text for [ChatMessageType.text], a Cloudinary image URL for
  /// [ChatMessageType.image]. Null once [deletedAt] is set — the backend
  /// stops serving a deleted message's content entirely.
  final String? content;
  final ChatMessageType type;
  final DateTime sentAt;

  /// Set once the recipient's app has actually received this over the
  /// WebSocket — null means only "sent" (single tick).
  final DateTime? deliveredAt;

  /// Set once the recipient has opened the thread — null means not yet
  /// read (double tick, gray, if delivered; blue once this is set).
  final DateTime? readAt;

  /// Set once the sender deletes this message — [content] is null
  /// whenever this is set, so render a "message deleted" placeholder.
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  /// A short, human-readable preview for surfaces like tray notifications,
  /// where the raw [content] (a URL for images, null once deleted) isn't
  /// presentable on its own.
  String get previewText {
    if (isDeleted) return 'Message deleted';
    if (type == ChatMessageType.image) return '📷 Photo';
    return content ?? '';
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as int,
      requestId: json['requestId'] as int,
      senderId: json['senderId'] as int,
      senderName: json['senderName'] as String,
      content: json['content'] as String?,
      type: (json['type'] as String?) == 'IMAGE' ? ChatMessageType.image : ChatMessageType.text,
      sentAt: DateTime.parse(json['sentAt'] as String),
      deliveredAt: json['deliveredAt'] == null ? null : DateTime.parse(json['deliveredAt'] as String),
      readAt: json['readAt'] == null ? null : DateTime.parse(json['readAt'] as String),
      deletedAt: json['deletedAt'] == null ? null : DateTime.parse(json['deletedAt'] as String),
    );
  }
}
