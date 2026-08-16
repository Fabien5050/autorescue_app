import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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
  final ImagePicker _imagePicker = ImagePicker();
  final Set<int> _selectedIds = <int>{};
  StreamSubscription<ChatMessage>? _sub;
  bool _loading = true;
  bool _sending = false;

  bool get _inSelectionMode => _selectedIds.isNotEmpty;

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

  /// Shared by several very different events pushed over the same
  /// destination: a genuinely new message from the other party (not yet in
  /// the list — appended), a delivered/read receipt update for a message
  /// *this* device already sent, and a deletion (both cases: same id
  /// already in the list — updated in place).
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

  Future<void> _sendImage() async {
    if (_sending) return;
    final XFile? picked = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null || !mounted) return;

    setState(() => _sending = true);
    try {
      final Uint8List bytes = await picked.readAsBytes();
      final ChatMessage sent = await ChatApi.sendImage(
        requestId: widget.requestId,
        fileBytes: bytes,
        fileName: picked.name,
      );
      if (mounted && !_messages.any((ChatMessage m) => m.id == sent.id)) {
        setState(() => _messages.add(sent));
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Couldn\'t send image: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _toggleSelected(int messageId) {
    setState(() {
      if (!_selectedIds.remove(messageId)) _selectedIds.add(messageId);
    });
  }

  void _clearSelection() => setState(_selectedIds.clear);

  Future<void> _deleteSelected() async {
    final int? myUserId = Session.instance.userId;
    final List<int> ids = _selectedIds.toList();
    final List<int> notMine = ids
        .where((int id) => _messages.firstWhere((ChatMessage m) => m.id == id).senderId != myUserId)
        .toList();
    _clearSelection();

    for (final int id in ids) {
      if (notMine.contains(id)) continue;
      try {
        final ChatMessage updated = await ChatApi.delete(widget.requestId, id);
        if (!mounted) return;
        final int index = _messages.indexWhere((ChatMessage m) => m.id == id);
        if (index != -1) setState(() => _messages[index] = updated);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Couldn\'t delete a message: $e')),
          );
        }
      }
    }

    if (notMine.isNotEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            notMine.length == ids.length
                ? 'You can only delete messages you sent.'
                : 'Only your own messages were deleted.',
          ),
        ),
      );
    }
  }

  void _openImage(String url) {
    showDialog<void>(
      context: context,
      builder: (BuildContext _) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        child: InteractiveViewer(
          child: Image.network(
            url,
            errorBuilder: (BuildContext _, Object _, StackTrace? _) =>
                const Icon(Icons.broken_image_outlined, color: Colors.white38, size: 64),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int? myUserId = Session.instance.userId;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _inSelectionMode
          ? AppBar(
              backgroundColor: AppColors.card,
              foregroundColor: AppColors.primaryText,
              elevation: 0.5,
              leading: IconButton(icon: const Icon(Icons.close), onPressed: _clearSelection),
              title: Text('${_selectedIds.length} selected'),
              actions: <Widget>[
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Delete',
                  onPressed: _deleteSelected,
                ),
              ],
            )
          : AppBar(
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
                            selected: _selectedIds.contains(message.id),
                            selectionMode: _inSelectionMode,
                            onTap: () {
                              if (_inSelectionMode) {
                                _toggleSelected(message.id);
                              } else if (message.type == ChatMessageType.image &&
                                  !message.isDeleted &&
                                  message.content != null) {
                                _openImage(message.content!);
                              }
                            },
                            onLongPress: message.isDeleted ? null : () => _toggleSelected(message.id),
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
                  IconButton(
                    onPressed: _sending ? null : _sendImage,
                    icon: const Icon(Icons.image_outlined, color: AppColors.primaryBlue),
                    tooltip: 'Send image',
                  ),
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
  const _MessageBubble({
    required this.message,
    required this.isMine,
    required this.selected,
    required this.selectionMode,
    required this.onTap,
    this.onLongPress,
  });

  final ChatMessage message;
  final bool isMine;
  final bool selected;
  final bool selectionMode;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: selected ? AppColors.primaryBlue.withValues(alpha: 0.08) : null,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Align(
          alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              if (selectionMode && isMine) _SelectionCheck(selected: selected),
              Container(
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: message.type == ChatMessageType.image && !message.isDeleted
                    ? const EdgeInsets.all(4)
                    : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                    _MessageContent(message: message, isMine: isMine),
                    const SizedBox(height: 4),
                    Padding(
                      padding: message.type == ChatMessageType.image && !message.isDeleted
                          ? const EdgeInsets.only(left: 6, right: 6, bottom: 2)
                          : EdgeInsets.zero,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            _formatTime(message.sentAt.toLocal()),
                            style: TextStyle(
                              fontSize: 10.5,
                              color: isMine ? Colors.white70 : AppColors.secondaryText,
                            ),
                          ),
                          if (isMine && !message.isDeleted) ...<Widget>[
                            const SizedBox(width: 4),
                            _ReceiptTicks(message: message),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (selectionMode && !isMine) _SelectionCheck(selected: selected),
            ],
          ),
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

class _SelectionCheck extends StatelessWidget {
  const _SelectionCheck({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Icon(
        selected ? Icons.check_circle : Icons.radio_button_unchecked,
        size: 20,
        color: selected ? AppColors.primaryBlue : AppColors.slateLight,
      ),
    );
  }
}

class _MessageContent extends StatelessWidget {
  const _MessageContent({required this.message, required this.isMine});

  final ChatMessage message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    if (message.isDeleted) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.block, size: 15, color: isMine ? Colors.white70 : AppColors.secondaryText),
          const SizedBox(width: 6),
          Text(
            'This message was deleted',
            style: TextStyle(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: isMine ? Colors.white70 : AppColors.secondaryText,
            ),
          ),
        ],
      );
    }

    if (message.type == ChatMessageType.image && message.content != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          message.content!,
          width: 200,
          height: 200,
          fit: BoxFit.cover,
          errorBuilder: (BuildContext _, Object _, StackTrace? _) => Container(
            width: 200,
            height: 200,
            color: AppColors.badgeSoft,
            alignment: Alignment.center,
            child: const Icon(Icons.broken_image_outlined, color: AppColors.slateLight, size: 32),
          ),
        ),
      );
    }

    return Text(
      message.content ?? '',
      style: TextStyle(color: isMine ? Colors.white : AppColors.primaryText, fontSize: 14),
    );
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
