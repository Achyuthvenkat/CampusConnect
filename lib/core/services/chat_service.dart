import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_connect/core/models/message_model.dart';
import 'package:campus_connect/core/constants/firestore_paths.dart';
import 'package:campus_connect/core/services/storage_service.dart';

final chatServiceProvider = Provider<ChatService>(
  (ref) => ChatService(ref.read(storageServiceProvider)),
);

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final StorageService _storage;

  ChatService(this._storage);

  // ─── Chat Room ───────────────────────────────────────────────────────────

  Future<String> getOrCreateChat(String uid1, String uid2) async {
    final chatId = FirestorePaths.chatId(uid1, uid2);
    final docRef = _db.collection(FirestorePaths.chats).doc(chatId);
    try {
      final doc = await docRef.get();

      if (!doc.exists) {
        await docRef.set({
          'id': chatId,
          'participants': [uid1, uid2],
          'lastMessage': '',
          'lastTimestamp': FieldValue.serverTimestamp(),
          'unreadCount': {uid1: 0, uid2: 0},
        });
      }
    } catch (e) {
      // If we can't check/create, we still return chatId
      // The subsequent stream listen will handle the permission error
      print('ChatService: getOrCreateChat error: $e');
    }

    return chatId;
  }

  // ─── Messages ────────────────────────────────────────────────────────────

  Stream<List<MessageModel>> messagesStream(String chatId) {
    return _db
        .collection(FirestorePaths.chats)
        .doc(chatId)
        .collection(FirestorePaths.messages)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => MessageModel.fromFirestore(d)).toList());
  }

  Future<void> sendTextMessage({
    required String chatId,
    required String senderId,
    required String recipientId,
    required String text,
  }) async {
    final message = MessageModel(
      id: '',
      senderId: senderId,
      text: text,
      type: 'text',
      timestamp: DateTime.now(),
    );

    await _sendMessage(chatId, senderId, recipientId, message, text);
  }

  Future<void> sendImageMessage({
    required String chatId,
    required String senderId,
    required String recipientId,
    required File imageFile,
  }) async {
    final imageUrl = await _storage.uploadChatImage(chatId, imageFile);
    final message = MessageModel(
      id: '',
      senderId: senderId,
      text: '📷 Image',
      type: 'image',
      imageUrl: imageUrl,
      timestamp: DateTime.now(),
    );

    await _sendMessage(chatId, senderId, recipientId, message, '📷 Image');
  }

  Future<void> _sendMessage(
    String chatId,
    String senderId,
    String recipientId,
    MessageModel message,
    String preview,
  ) async {
    final batch = _db.batch();

    // Add message document
    final msgRef = _db
        .collection(FirestorePaths.chats)
        .doc(chatId)
        .collection(FirestorePaths.messages)
        .doc();
    batch.set(msgRef, message.toFirestore());

    // Update chat metadata
    final chatRef = _db.collection(FirestorePaths.chats).doc(chatId);
    batch.update(chatRef, {
      'lastMessage': preview,
      'lastTimestamp': FieldValue.serverTimestamp(),
      'unreadCount.$recipientId': FieldValue.increment(1),
    });

    await batch.commit();
  }

  // Mark messages as read
  Future<void> markAsRead(String chatId, String userId) async {
    await _db.collection(FirestorePaths.chats).doc(chatId).update({
      'unreadCount.$userId': 0,
    });
  }

  // ─── Chat List ───────────────────────────────────────────────────────────

  Stream<List<ChatModel>> userChatsStream(String userId) {
    return _db
        .collection(FirestorePaths.chats)
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((s) {
          final chats =
              s.docs.map((d) => ChatModel.fromFirestore(d)).toList();
          chats.sort((a, b) => b.lastTimestamp.compareTo(a.lastTimestamp));
          return chats;
        });
  }
}
