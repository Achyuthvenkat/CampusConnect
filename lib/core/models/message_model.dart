import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class MessageModel extends Equatable {
  final String id;
  final String senderId;
  final String text;
  final String type; // 'text' | 'image'
  final String? imageUrl;
  final DateTime timestamp;
  final bool read;

  const MessageModel({
    required this.id,
    required this.senderId,
    required this.text,
    this.type = 'text',
    this.imageUrl,
    required this.timestamp,
    this.read = false,
  });

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      text: data['text'] ?? '',
      type: data['type'] ?? 'text',
      imageUrl: data['imageUrl'],
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      read: data['read'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'text': text,
      'type': type,
      'imageUrl': imageUrl,
      'timestamp': Timestamp.fromDate(timestamp),
      'read': read,
    };
  }

  bool get isImage => type == 'image';

  @override
  List<Object?> get props => [id, senderId, text, timestamp];
}

class ChatModel extends Equatable {
  final String id;
  final List<String> participants;
  final String lastMessage;
  final DateTime lastTimestamp;
  final Map<String, int> unreadCount;

  const ChatModel({
    required this.id,
    required this.participants,
    this.lastMessage = '',
    required this.lastTimestamp,
    this.unreadCount = const {},
  });

  factory ChatModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatModel(
      id: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      lastMessage: data['lastMessage'] ?? '',
      lastTimestamp:
          (data['lastTimestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      unreadCount: Map<String, int>.from(data['unreadCount'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'participants': participants,
      'lastMessage': lastMessage,
      'lastTimestamp': Timestamp.fromDate(lastTimestamp),
      'unreadCount': unreadCount,
    };
  }

  int getUnreadCount(String userId) => unreadCount[userId] ?? 0;

  @override
  List<Object?> get props => [id, participants, lastMessage, lastTimestamp];
}
