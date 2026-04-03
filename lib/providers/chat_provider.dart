import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/chat_room_model.dart';
import '../models/message_model.dart';
import '../services/firestore_service.dart';

class ChatProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  StreamSubscription<List<ChatRoomModel>>? _chatRoomsSubscription;

  List<ChatRoomModel> _chatRooms = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ChatRoomModel> get chatRooms => _chatRooms;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void listenToChatRooms(String userId) {
    _chatRoomsSubscription?.cancel();
    _chatRoomsSubscription =
        _firestoreService.getChatRooms(userId).listen((rooms) {
      _chatRooms = rooms;
      notifyListeners();
    });
  }

  Stream<List<MessageModel>> getMessages(String chatRoomId) {
    return _firestoreService.getMessages(chatRoomId);
  }

  Future<ChatRoomModel?> getOrCreateChatRoom({
    required String currentUserId,
    required String currentUserName,
    required String? currentUserPhoto,
    required String otherUserId,
    required String otherUserName,
    required String? otherUserPhoto,
  }) async {
    _setLoading(true);
    try {
      final room = await _firestoreService.getOrCreateChatRoom(
        currentUserId: currentUserId,
        currentUserName: currentUserName,
        currentUserPhoto: currentUserPhoto,
        otherUserId: otherUserId,
        otherUserName: otherUserName,
        otherUserPhoto: otherUserPhoto,
      );
      return room;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> sendMessage(MessageModel message) async {
    try {
      await _firestoreService.sendMessage(message);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  Future<void> markAsRead(String chatRoomId, String userId) async {
    try {
      await _firestoreService.markMessagesAsRead(chatRoomId, userId);
    } catch (_) {}
  }

  int getTotalUnreadCount(String userId) {
    return _chatRooms.fold(
        0, (sum, room) => sum + (room.unreadCount[userId] ?? 0));
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _chatRoomsSubscription?.cancel();
    super.dispose();
  }
}
