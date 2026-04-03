import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/job_model.dart';
import '../models/bid_model.dart';
import '../models/review_model.dart';
import '../models/message_model.dart';
import '../models/chat_room_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ── Users ────────────────────────────────────────────────────────────────

  Future<UserModel?> getUser(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!);
  }

  Stream<UserModel?> userStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromMap(doc.data()!);
    });
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(uid).update(data);
  }

  // ── Jobs ─────────────────────────────────────────────────────────────────

  Stream<List<JobModel>> getJobsStream({
    String? category,
    double? maxBudget,
    double? minBudget,
    String? searchQuery,
  }) {
    Query<Map<String, dynamic>> query = _firestore
        .collection('jobs')
        .where('status', isEqualTo: 'open')
        .orderBy('createdAt', descending: true);

    if (category != null && category != 'All') {
      query = query.where('category', isEqualTo: category);
    }

    return query.snapshots().map((snapshot) {
      var jobs = snapshot.docs
          .map((doc) => JobModel.fromMap(doc.data(), doc.id))
          .toList();

      if (maxBudget != null) {
        jobs = jobs.where((j) => j.budget <= maxBudget).toList();
      }
      if (minBudget != null) {
        jobs = jobs.where((j) => j.budget >= minBudget).toList();
      }
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        jobs = jobs
            .where((j) =>
                j.title.toLowerCase().contains(q) ||
                j.description.toLowerCase().contains(q) ||
                j.category.toLowerCase().contains(q))
            .toList();
      }

      return jobs;
    });
  }

  Stream<List<JobModel>> getUserJobs(String userId) {
    return _firestore
        .collection('jobs')
        .where('clientId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => JobModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Stream<List<JobModel>> getFreelancerJobs(String userId) {
    return _firestore
        .collection('jobs')
        .where('assignedFreelancerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => JobModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<DocumentReference> createJob(JobModel job) async {
    return await _firestore.collection('jobs').add(job.toMap());
  }

  Future<void> updateJob(String jobId, Map<String, dynamic> data) async {
    await _firestore.collection('jobs').doc(jobId).update(data);
  }

  // ── Bids ─────────────────────────────────────────────────────────────────

  Future<void> createBid(BidModel bid) async {
    final batch = _firestore.batch();
    final bidRef = _firestore.collection('bids').doc();
    batch.set(bidRef, bid.toMap());
    batch.update(
      _firestore.collection('jobs').doc(bid.jobId),
      {'bidCount': FieldValue.increment(1)},
    );
    await batch.commit();
  }

  Stream<List<BidModel>> getJobBids(String jobId) {
    return _firestore
        .collection('bids')
        .where('jobId', isEqualTo: jobId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BidModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Stream<List<BidModel>> getFreelancerBids(String freelancerId) {
    return _firestore
        .collection('bids')
        .where('freelancerId', isEqualTo: freelancerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BidModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> updateBid(String bidId, Map<String, dynamic> data) async {
    await _firestore.collection('bids').doc(bidId).update(data);
  }

  // ── Reviews ───────────────────────────────────────────────────────────────

  Future<void> addReview(ReviewModel review) async {
    final batch = _firestore.batch();

    final reviewRef = _firestore.collection('reviews').doc();
    batch.set(reviewRef, review.toMap());

    final userDoc =
        await _firestore.collection('users').doc(review.revieweeId).get();
    if (userDoc.exists) {
      final userData = userDoc.data()!;
      final currentRating = (userData['rating'] ?? 0).toDouble();
      final currentCount = (userData['reviewCount'] ?? 0) as int;
      final newCount = currentCount + 1;
      final newRating =
          ((currentRating * currentCount) + review.rating) / newCount;

      batch.update(
        _firestore.collection('users').doc(review.revieweeId),
        {'rating': newRating, 'reviewCount': newCount},
      );
    }

    await batch.commit();
  }

  Stream<List<ReviewModel>> getUserReviews(String userId) {
    return _firestore
        .collection('reviews')
        .where('revieweeId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReviewModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // ── Chat ─────────────────────────────────────────────────────────────────

  String getChatRoomId(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  Future<ChatRoomModel> getOrCreateChatRoom({
    required String currentUserId,
    required String currentUserName,
    required String? currentUserPhoto,
    required String otherUserId,
    required String otherUserName,
    required String? otherUserPhoto,
  }) async {
    final chatRoomId = getChatRoomId(currentUserId, otherUserId);
    final docRef = _firestore.collection('chatRooms').doc(chatRoomId);
    final doc = await docRef.get();

    if (!doc.exists) {
      final chatRoom = ChatRoomModel(
        id: chatRoomId,
        participantIds: [currentUserId, otherUserId],
        participantNames: {
          currentUserId: currentUserName,
          otherUserId: otherUserName,
        },
        participantPhotos: {
          currentUserId: currentUserPhoto,
          otherUserId: otherUserPhoto,
        },
        lastMessage: '',
        lastMessageTime: DateTime.now(),
        lastMessageSenderId: currentUserId,
        unreadCount: {currentUserId: 0, otherUserId: 0},
      );
      await docRef.set(chatRoom.toMap());
      return chatRoom;
    }

    return ChatRoomModel.fromMap(doc.data()!, chatRoomId);
  }

  Stream<List<ChatRoomModel>> getChatRooms(String userId) {
    return _firestore
        .collection('chatRooms')
        .where('participantIds', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatRoomModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Stream<List<MessageModel>> getMessages(String chatRoomId) {
    return _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> sendMessage(MessageModel message) async {
    final batch = _firestore.batch();

    final msgRef = _firestore
        .collection('chatRooms')
        .doc(message.chatRoomId)
        .collection('messages')
        .doc();
    batch.set(msgRef, message.toMap());

    final chatRoomRef =
        _firestore.collection('chatRooms').doc(message.chatRoomId);
    batch.update(chatRoomRef, {
      'lastMessage': message.content,
      'lastMessageTime': Timestamp.fromDate(message.timestamp),
      'lastMessageSenderId': message.senderId,
    });

    await batch.commit();
  }

  Future<void> markMessagesAsRead(
      String chatRoomId, String userId) async {
    final messages = await _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('messages')
        .where('isRead', isEqualTo: false)
        .where('senderId', isNotEqualTo: userId)
        .get();

    final batch = _firestore.batch();
    for (final doc in messages.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    batch.update(
      _firestore.collection('chatRooms').doc(chatRoomId),
      {'unreadCount.$userId': 0},
    );
    await batch.commit();
  }

  // ── Bookmarks ─────────────────────────────────────────────────────────────

  Future<void> toggleBookmark(String userId, String freelancerId) async {
    final userRef = _firestore.collection('users').doc(userId);
    final doc = await userRef.get();
    if (!doc.exists) return;

    final bookmarks = List<String>.from(doc.data()!['bookmarks'] ?? []);
    if (bookmarks.contains(freelancerId)) {
      bookmarks.remove(freelancerId);
    } else {
      bookmarks.add(freelancerId);
    }

    await userRef.update({'bookmarks': bookmarks});
  }

  Future<List<UserModel>> getBookmarkedFreelancers(List<String> ids) async {
    if (ids.isEmpty) return [];
    final docs = await _firestore
        .collection('users')
        .where(FieldPath.documentId, whereIn: ids)
        .get();
    return docs.docs
        .map((doc) => UserModel.fromMap(doc.data()))
        .toList();
  }

  // ── Search Freelancers ────────────────────────────────────────────────────

  Future<List<UserModel>> searchFreelancers({
    String? skill,
    double? maxRate,
    double? minRating,
    String? query,
  }) async {
    Query<Map<String, dynamic>> q = _firestore.collection('users');

    if (skill != null && skill.isNotEmpty) {
      q = q.where('skills', arrayContains: skill);
    }

    final docs = await q.get();
    var users =
        docs.docs.map((doc) => UserModel.fromMap(doc.data())).toList();

    if (maxRate != null) {
      users = users.where((u) => u.hourlyRate <= maxRate).toList();
    }
    if (minRating != null) {
      users = users.where((u) => u.rating >= minRating).toList();
    }
    if (query != null && query.isNotEmpty) {
      final q2 = query.toLowerCase();
      users = users
          .where((u) =>
              u.name.toLowerCase().contains(q2) ||
              u.skills.any((s) => s.toLowerCase().contains(q2)) ||
              (u.bio?.toLowerCase().contains(q2) ?? false))
          .toList();
    }

    return users;
  }
}
