import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:campus_connect/app/theme/app_colors.dart';
import 'package:campus_connect/core/models/message_model.dart';
import 'package:campus_connect/core/models/user_model.dart';
import 'package:campus_connect/core/services/auth_service.dart';
import 'package:campus_connect/core/services/chat_service.dart';
import 'package:campus_connect/core/services/firestore_service.dart';
import 'package:campus_connect/core/services/storage_service.dart';
import 'package:campus_connect/core/utils/helpers.dart';
import 'package:campus_connect/widgets/common/avatar_widget.dart';
import 'package:timeago/timeago.dart' as timeago;

final _chatsProvider =
    StreamProvider.autoDispose.family<List<ChatModel>, String>((ref, uid) {
  return ref.read(chatServiceProvider).userChatsStream(uid);
});

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(authServiceProvider).currentUserId ?? '';
    final chatsAsync = ref.watch(_chatsProvider(uid));

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: const Text('Messages'),
      ),
      body: chatsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (chats) {
          if (chats.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.chat_bubble_outline,
                      size: 64, color: AppColors.textHint),
                  const SizedBox(height: 12),
                  const Text('No conversations yet.',
                      style: TextStyle(
                          fontSize: 14, color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      // Navigate to explore tab
                    },
                    child: const Text('Find freelancers to message'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (_, i) {
              final chat = chats[i];
              final otherUserId =
                  chat.participants.firstWhere((p) => p != uid);
              final unread = chat.getUnreadCount(uid);

              return _ChatTile(
                chatId: chat.id,
                userId: uid,
                otherUserId: otherUserId,
                lastMessage: chat.lastMessage,
                lastTimestamp: chat.lastTimestamp,
                unreadCount: unread,
                onTap: () async {
                  // Get other user info
                  final otherUser = await ref
                      .read(firestoreServiceProvider)
                      .getUser(otherUserId);
                  if (context.mounted) {
                    context.push(
                        '/home/chat/${chat.id}/$otherUserId/${Uri.encodeComponent(otherUser?.name ?? 'User')}?avatar=${otherUser?.avatarUrl ?? ''}');
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _ChatTile extends ConsumerWidget {
  final String chatId;
  final String userId;
  final String otherUserId;
  final String lastMessage;
  final DateTime lastTimestamp;
  final int unreadCount;
  final VoidCallback onTap;

  const _ChatTile({
    required this.chatId,
    required this.userId,
    required this.otherUserId,
    required this.lastMessage,
    required this.lastTimestamp,
    required this.unreadCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(
      StreamProvider.autoDispose<UserModel?>(
        (r) => ref.read(firestoreServiceProvider).userStream(otherUserId),
      ),
    );

    final user = userAsync.valueOrNull;

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: AvatarWidget(
        imageUrl: user?.avatarUrl,
        name: user?.name ?? '...',
        radius: 26,
      ),
      title: Text(
        user?.name ?? '...',
        style: TextStyle(
          fontWeight:
              unreadCount > 0 ? FontWeight.w700 : FontWeight.w500,
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        lastMessage.isEmpty ? 'Start a conversation' : lastMessage,
        style: TextStyle(
          fontSize: 13,
          color: unreadCount > 0
              ? AppColors.textPrimary
              : AppColors.textSecondary,
          fontWeight:
              unreadCount > 0 ? FontWeight.w500 : FontWeight.w400,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            AppHelpers.formatChatTime(lastTimestamp),
            style: TextStyle(
              fontSize: 11,
              color: unreadCount > 0
                  ? AppColors.primary
                  : AppColors.textHint,
            ),
          ),
          const SizedBox(height: 4),
          if (unreadCount > 0)
            Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  unreadCount > 9 ? '9+' : '$unreadCount',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ),
        ],
      ),
      onTap: onTap,
    );
  }
}

