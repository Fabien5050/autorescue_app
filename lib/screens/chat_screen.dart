import 'dart:async';

import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/notification_service.dart';
import '../core/session.dart';
import '../core/websocket_service.dart';
import '../models/chat_message.dart';
import '../services/chat_api.dart';

/// Text chat between driver and mechanic on a shared active request —
/// history loads once via REST, new messages arrive live over the same
/// WebSocket connection used for status notifications and call signaling.
class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.requestId,
    required this.otherPartyName,
  });

  final int requestId;
  final String otherPartyName;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<ChatMessage> _messages = <ChatMessage>[];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  StreamSubscription<ChatMessage>? _sub;
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    NotificationService.setOpenChat(widget.requestId);
    _load();
    _sub = WebSocketService.instance.chatMessages.listen(_onIncoming);
  }

  @override
  void dispose() {
    NotificationService.setOpenChat(null);
    _sub?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final List<ChatMessage> messages = await ChatApi.list(widget.requestId);
      if (!mounted) return;
      setState(() {
        _messages
          ..clear()
          ..addAll(messages);
        _loading = false;
      });
      _scrollToBottom();
      ChatApi.markRead(widget.requestId);
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Shared by two very different events: a genuinely new message from the
  /// other party (not yet in the list — appended), and a delivered/read
  /// receipt update pushed back for a message *this* device already sent
  /// (same id already in the list — updated in place so its ticks change).
  void _onIncoming(ChatMessage message) {
    if (message.requestId != widget.requestId || !mounted) return;
    final int existingIndex = _messages.indexWhere((ChatMessage m) => m.id == message.id);
    setState(() {
      if (existingIndex != -1) {
        _messages[existingIndex] = message;
      } else {
        _messages.add(message);
      }
    });
    if (existingIndex == -1) {
      _scrollToBottom();
      // Arrived while this thread is already open — read immediately.
      ChatApi.markRead(widget.requestId);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    final String text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    _controller.clear();
    try {
      final ChatMessage sent = await ChatApi.send(widget.requestId, text);
      // The WebSocket echo only reaches the *other* side — this device's
      // own send needs to append it locally, guarded against a duplicate
      // in the unlikely case a reconnect briefly loops it back too.
      if (mounted && !_messages.any((ChatMessage m) => m.id == sent.id)) {
        setState(() => _messages.add(sent));
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Couldn\'t send: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final int? myUserId = Session.instance.userId;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.otherPartyName),
        backgroundColor: AppColors.card,
        foregroundColor: AppColors.primaryText,
        elevation: 0.5,
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? const Center(
                        child: Text(
                          'No messages yet — say hello.',
                          style: TextStyle(color: AppColors.secondaryText),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(14),
                        itemCount: _messages.length,
                        itemBuilder: (BuildContext context, int index) {
                          final ChatMessage message = _messages[index];
                          return _MessageBubble(
                            message: message,
                            isMine: message.senderId == myUserId,
                          );
                        },
                      ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Message…',
                        filled: true,
                        fillColor: AppColors.card,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                      ),
                      onSubmitted: (String _) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sending ? null : _send,
                    icon: const Icon(Icons.send),
                    style: IconButton.styleFrom(backgroundColor: AppColors.primaryBlue),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.isMine});

  final ChatMessage message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMine ? AppColors.primaryBlue : AppColors.card,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(isMine ? 14 : 2),
            bottomRight: Radius.circular(isMine ? 2 : 14),
          ),
          border: isMine ? null : Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              message.content,
              style: TextStyle(color: isMine ? Colors.white : AppColors.primaryText, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  _formatTime(message.sentAt.toLocal()),
                  style: TextStyle(
                    fontSize: 10.5,
                    color: isMine ? Colors.white70 : AppColors.secondaryText,
                  ),
                ),
                if (isMine) ...<Widget>[
                  const SizedBox(width: 4),
                  _ReceiptTicks(message: message),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final String hour = dt.hour.toString().padLeft(2, '0');
    final String minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

/// WhatsApp-style receipt ticks on the sender's own messages: one gray
/// check once sent, two gray checks once the recipient's device has
/// actually received it, two blue checks once they've opened the thread.
class _ReceiptTicks extends StatelessWidget {
  const _ReceiptTicks({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    if (message.readAt != null) {
      return const Icon(Icons.done_all, size: 15, color: Color(0xFF34B7F1));
    }
    if (message.deliveredAt != null) {
      return const Icon(Icons.done_all, size: 15, color: Colors.white70);
    }
    return const Icon(Icons.done, size: 15, color: Colors.white70);
  }
}
