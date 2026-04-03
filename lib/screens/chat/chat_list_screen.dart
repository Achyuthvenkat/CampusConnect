import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart' as app_auth;
import '../../models/chat_room_model.dart';
import '../../utils/theme.dart';
import '../../utils/helpers.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();
    final authProvider = context.read<app_auth.AuthProvider>();
    final currentUserId = authProvider.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: chatProvider.chatRooms.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline,
                      size: 64, color: AppTheme.textSecondary),
                  SizedBox(height: 16),
                  Text(
                    'No conversations yet',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Start a conversation by messaging a freelancer or client.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )
          : ListView.separated(
              itemCount: chatProvider.chatRooms.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, indent: 76),
              itemBuilder: (_, i) {
                final room = chatProvider.chatRooms[i];
                return _ChatTile(
                  room: room,
                  currentUserId: currentUserId,
                );
              },
            ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  final ChatRoomModel room;
  final String currentUserId;

  const _ChatTile({required this.room, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    final otherName = room.getOtherParticipantName(currentUserId);
    final otherPhoto = room.getOtherParticipantPhoto(currentUserId);
    final unread = room.unreadCount[currentUserId] ?? 0;

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: _avatar(otherPhoto, otherName),
      title: Row(
        children: [
          Expanded(
            child: Text(
              otherName,
              style: TextStyle(
                fontWeight:
                    unread > 0 ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Text(
            Helpers.timeAgo(room.lastMessageTime),
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
      subtitle: Row(
        children: [
          if (room.lastMessageSenderId == currentUserId)
            const Icon(Icons.done_all,
                size: 14, color: AppTheme.primaryColor),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              room.lastMessage.isEmpty
                  ? 'Start a conversation'
                  : room.lastMessage,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: unread > 0
                    ? AppTheme.textPrimary
                    : AppTheme.textSecondary,
                fontWeight:
                    unread > 0 ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ),
          if (unread > 0)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$unread',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ChatScreen(chatRoom: room)),
      ),
    );
  }

  Widget _avatar(String? photoUrl, String name) {
    if (photoUrl != null) {
      return CircleAvatar(
        radius: 24,
        backgroundImage: CachedNetworkImageProvider(photoUrl),
      );
    }
    return CircleAvatar(
      radius: 24,
      backgroundColor: AppTheme.primaryColor,
      child: Text(
        Helpers.getInitials(name),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
