import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:campus_connect/app/theme/app_colors.dart';
import 'package:campus_connect/core/models/message_model.dart';
import 'package:campus_connect/core/services/auth_service.dart';
import 'package:campus_connect/core/services/chat_service.dart';
import 'package:campus_connect/core/services/storage_service.dart';
import 'package:campus_connect/widgets/common/avatar_widget.dart';
import 'package:timeago/timeago.dart' as timeago;

final messagesProvider =
    StreamProvider.autoDispose.family<List<MessageModel>, String>(
        (ref, chatId) {
  return ref.read(chatServiceProvider).messagesStream(chatId);
});

class ChatRoomScreen extends ConsumerStatefulWidget {
  final String chatId;
  final String recipientId;
  final String recipientName;
  final String? recipientAvatarUrl;

  const ChatRoomScreen({
    super.key,
    required this.chatId,
    required this.recipientId,
    required this.recipientName,
    this.recipientAvatarUrl,
  });

  @override
  ConsumerState<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    // Mark as read when entering
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final uid = ref.read(authServiceProvider).currentUserId ?? '';
      try {
        await ref.read(chatServiceProvider).markAsRead(widget.chatId, uid);
      } catch (e) {
        print('ChatRoomScreen: Error marking as read: $e');
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendText() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();

    final uid = ref.read(authServiceProvider).currentUserId ?? '';
    await ref.read(chatServiceProvider).sendTextMessage(
          chatId: widget.chatId,
          senderId: uid,
          recipientId: widget.recipientId,
          text: text,
        );
  }

  Future<void> _sendImage() async {
    final file = await ref.read(storageServiceProvider).pickImage();
    if (file == null) return;

    setState(() => _isSending = true);
    final uid = ref.read(authServiceProvider).currentUserId ?? '';
    try {
      await ref.read(chatServiceProvider).sendImageMessage(
            chatId: widget.chatId,
            senderId: uid,
            recipientId: widget.recipientId,
            imageFile: file,
          );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(authServiceProvider).currentUserId ?? '';
    final messagesAsync = ref.watch(messagesProvider(widget.chatId));

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
        titleSpacing: 0,
        title: GestureDetector(
          onTap: () =>
              context.push('/home/profile/${widget.recipientId}'),
          child: Row(
            children: [
              AvatarWidget(
                imageUrl: widget.recipientAvatarUrl,
                name: widget.recipientName,
                radius: 20,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.recipientName,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const Text(
                    'Online',
                    style: TextStyle(fontSize: 11, color: AppColors.accentGreen),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: messagesAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.chat_bubble_outline,
                            size: 48, color: AppColors.textHint),
                        const SizedBox(height: 12),
                        Text(
                          'Start your conversation with ${widget.recipientName}',
                          style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                // Sort messages descending for reversed list
                final sortedMessages = List<MessageModel>.from(messages)
                  ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  itemCount: sortedMessages.length,
                  itemBuilder: (_, i) {
                    final msg = sortedMessages[i];
                    final isMe = msg.senderId == uid;
                    
                    // Show time if it's the first message or there's a 15 min gap
                    bool showTime = i == sortedMessages.length - 1;
                    if (!showTime) {
                      final prevMsg = sortedMessages[i + 1];
                      showTime = msg.timestamp
                              .difference(prevMsg.timestamp)
                              .inMinutes >
                          15;
                    }

                    return Column(
                      children: [
                        if (showTime)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 12),
                            child: Text(
                              timeago.format(msg.timestamp),
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textHint),
                            ),
                          ),
                        _MessageBubble(message: msg, isMe: isMe),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // Input bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Image picker button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isSending ? null : _sendImage,
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: _isSending
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5))
                            : const Icon(
                                Icons.add_circle_outline_rounded,
                                color: AppColors.primary,
                                size: 28,
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 4),

                  // Text field
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 40, maxHeight: 120),
                      decoration: BoxDecoration(
                        color: AppColors.scaffoldBackground,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: AppColors.divider.withOpacity(0.5)),
                      ),
                      child: TextField(
                        controller: _textController,
                        maxLines: 5,
                        minLines: 1,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          hintStyle: TextStyle(
                              fontSize: 14, color: AppColors.textHint),
                        ),
                        style: const TextStyle(fontSize: 14, height: 1.4),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Send button
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _textController,
                    builder: (context, value, _) {
                      final canSend = value.text.trim().isNotEmpty;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: canSend
                              ? AppColors.primary
                              : AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: canSend ? _sendText : null,
                            borderRadius: BorderRadius.circular(21),
                            child: Icon(
                              Icons.send_rounded,
                              color: canSend ? Colors.white : AppColors.primary.withOpacity(0.3),
                              size: 20,
                            ),
                          ),
                        ),
                      );
                    },
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
  final MessageModel message;
  final bool isMe;

  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        padding: message.isImage
            ? const EdgeInsets.all(4)
            : const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : AppColors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft:
                isMe ? const Radius.circular(20) : const Radius.circular(6),
            bottomRight:
                isMe ? const Radius.circular(6) : const Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (message.isImage && message.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  message.imageUrl!,
                  width: 240,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      width: 240,
                      height: 180,
                      color: AppColors.scaffoldBackground,
                      child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2)),
                    );
                  },
                ),
              )
            else
              Text(
                message.text,
                style: TextStyle(
                  color: isMe ? Colors.white : AppColors.textPrimary,
                  fontSize: 14.5,
                  height: 1.4,
                  letterSpacing: 0.1,
                ),
              ),
            const SizedBox(height: 2),
            Text(
              timeago.format(message.timestamp, locale: 'en_short'),
              style: TextStyle(
                fontSize: 10,
                color: isMe
                    ? Colors.white.withOpacity(0.7)
                    : AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
