import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_connect/core/models/user_model.dart';
import 'package:campus_connect/core/models/gig_model.dart';
import 'package:campus_connect/core/models/bid_model.dart';
import 'package:campus_connect/core/models/review_model.dart';
import 'package:campus_connect/core/constants/firestore_paths.dart';

final firestoreServiceProvider =
    Provider<FirestoreService>((ref) => FirestoreService());

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── USER ───────────────────────────────────────────────────────────────

  Future<void> createUser(UserModel user) async {
    await _db
        .collection(FirestorePaths.users)
        .doc(user.uid)
        .set(user.toFirestore());
  }

  Future<UserModel?> getUser(String uid) async {
    final doc =
        await _db.collection(FirestorePaths.users).doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  Stream<UserModel?> userStream(String uid) {
    return _db
        .collection(FirestorePaths.users)
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _db
        .collection(FirestorePaths.users)
        .doc(uid)
        .set(data, SetOptions(merge: true));
  }

  Future<bool> userExists(String uid) async {
    final doc =
        await _db.collection(FirestorePaths.users).doc(uid).get();
    return doc.exists;
  }

  // Search users by skills or name
  Future<List<UserModel>> searchFreelancers({
    String query = '',
    String? skill,
    double? minRating,
    double? maxRate,
    bool availableOnly = false,
  }) async {
    Query q = _db.collection(FirestorePaths.users);

    if (availableOnly) {
      q = q.where('availability', isEqualTo: true);
    }
    if (minRating != null && minRating > 0) {
      q = q.where('rating', isGreaterThanOrEqualTo: minRating);
    }
    if (maxRate != null) {
      q = q.where('hourlyRate', isLessThanOrEqualTo: maxRate);
    }

    try {
      final snapshot = await q.get();
      var users = snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .where((u) => u.uid.isNotEmpty)
          .toList();

      // Client-side filtering for text query
      if (query.isNotEmpty) {
        final q2 = query.toLowerCase();
        users = users.where((u) {
          return u.name.toLowerCase().contains(q2) ||
              u.skills.any((s) => s.toLowerCase().contains(q2)) ||
              u.department.toLowerCase().contains(q2);
        }).toList();
      }

      if (skill != null && skill.isNotEmpty) {
        users = users
            .where((u) =>
                u.skills.any((s) => s.toLowerCase() == skill.toLowerCase()))
            .toList();
      }

      return users;
    } catch (e) {
      print('DEBUG: searchFreelancers error: $e');
      rethrow;
    }
  }

  // ─── BOOKMARKS ──────────────────────────────────────────────────────────

  Future<void> toggleBookmark(String currentUserId, String targetUserId) async {
    final userDoc =
        _db.collection(FirestorePaths.users).doc(currentUserId);
    final snapshot = await userDoc.get();
    final bookmarks =
        List<String>.from(snapshot.data()?['bookmarks'] ?? []);

    if (bookmarks.contains(targetUserId)) {
      await userDoc.update({
        'bookmarks': FieldValue.arrayRemove([targetUserId])
      });
    } else {
      await userDoc.update({
        'bookmarks': FieldValue.arrayUnion([targetUserId])
      });
    }
  }

  Future<List<UserModel>> getBookmarkedUsers(List<String> uids) async {
    if (uids.isEmpty) return [];
    final futures = uids.map((uid) => getUser(uid));
    final users = await Future.wait(futures);
    return users.whereType<UserModel>().toList();
  }

  // ─── GIGS ────────────────────────────────────────────────────────────────

  Future<String> createGig(GigModel gig) async {
    final docRef = _db.collection(FirestorePaths.gigs).doc();
    final gigWithId = GigModel(
      id: docRef.id,
      clientId: gig.clientId,
      clientName: gig.clientName,
      clientAvatarUrl: gig.clientAvatarUrl,
      title: gig.title,
      description: gig.description,
      category: gig.category,
      budget: gig.budget,
      deadline: gig.deadline,
      attachmentUrls: gig.attachmentUrls,
      tags: gig.tags,
      createdAt: gig.createdAt,
    );
    await docRef.set(gigWithId.toFirestore());
    return docRef.id;
  }

  Stream<List<GigModel>> gigsStream({
    String? category,
    String? status,
    double? maxBudget,
    double? minBudget,
  }) {
    Query q = _db.collection(FirestorePaths.gigs);

    if (category != null && category != 'All') {
      q = q.where('category', isEqualTo: category);
    }
    if (status != null) {
      q = q.where('status', isEqualTo: status);
    }

    return q.snapshots().map((snapshot) {
      try {
        var gigs =
            snapshot.docs.map((doc) => GigModel.fromFirestore(doc)).toList();

        // Sort client-side to avoid needing a composite index
        gigs.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        if (maxBudget != null) {
          gigs = gigs.where((g) => g.budget <= maxBudget).toList();
        }
        if (minBudget != null) {
          gigs = gigs.where((g) => g.budget >= minBudget).toList();
        }

        return gigs;
      } catch (e) {
        print('DEBUG: gigsStream error: $e');
        return [];
      }
    });
  }

  Stream<List<GigModel>> userGigsStream(String userId) {
    return _db
        .collection(FirestorePaths.gigs)
        .where('clientId', isEqualTo: userId)
        .snapshots()
        .map((s) {
          final gigs = s.docs.map((d) => GigModel.fromFirestore(d)).toList();
          gigs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return gigs;
        });
  }

  Future<GigModel?> getGig(String gigId) async {
    final doc =
        await _db.collection(FirestorePaths.gigs).doc(gigId).get();
    if (!doc.exists) return null;
    return GigModel.fromFirestore(doc);
  }

  Future<void> updateGigStatus(String gigId, String status,
      {String? selectedBidId}) async {
    final data = {'status': status};
    if (selectedBidId != null) data['selectedBidId'] = selectedBidId;
    await _db.collection(FirestorePaths.gigs).doc(gigId).update(data);
  }

  Future<void> deleteGig(String gigId) async {
    await _db.collection(FirestorePaths.gigs).doc(gigId).delete();
  }

  // ─── BIDS ────────────────────────────────────────────────────────────────

  Future<String> createBid(BidModel bid) async {
    final docRef = _db
        .collection(FirestorePaths.gigs)
        .doc(bid.gigId)
        .collection(FirestorePaths.bids)
        .doc();

    final bidWithId = BidModel(
      id: docRef.id,
      gigId: bid.gigId,
      bidderId: bid.bidderId,
      bidderName: bid.bidderName,
      bidderAvatarUrl: bid.bidderAvatarUrl,
      bidderRating: bid.bidderRating,
      amount: bid.amount,
      proposal: bid.proposal,
      deliveryDays: bid.deliveryDays,
      createdAt: bid.createdAt,
    );

    await docRef.set(bidWithId.toFirestore());

    // Increment bid count
    await _db
        .collection(FirestorePaths.gigs)
        .doc(bid.gigId)
        .update({'bidCount': FieldValue.increment(1)});

    return docRef.id;
  }

  Stream<List<BidModel>> gigBidsStream(String gigId) {
    return _db
        .collection(FirestorePaths.gigs)
        .doc(gigId)
        .collection(FirestorePaths.bids)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((s) => s.docs.map((d) => BidModel.fromFirestore(d)).toList());
  }

  Future<List<BidModel>> getUserBids(String userId) async {
    // CollectionGroup query without orderBy to avoid composite index requirement
    final snapshot = await _db
        .collectionGroup(FirestorePaths.bids)
        .where('bidderId', isEqualTo: userId)
        .get();
    final bids = snapshot.docs.map((d) => BidModel.fromFirestore(d)).toList();
    // Sort client-side
    bids.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return bids;
  }

  Future<void> acceptBid(String gigId, String bidId) async {
    final batch = _db.batch();

    // Accept the selected bid
    batch.update(
      _db
          .collection(FirestorePaths.gigs)
          .doc(gigId)
          .collection(FirestorePaths.bids)
          .doc(bidId),
      {'status': 'accepted'},
    );

    // Update gig status
    batch.update(
      _db.collection(FirestorePaths.gigs).doc(gigId),
      {'status': 'in-progress', 'selectedBidId': bidId},
    );

    await batch.commit();
  }

  // ─── REVIEWS ─────────────────────────────────────────────────────────────

  Future<void> createReview(ReviewModel review) async {
    final docRef = _db.collection(FirestorePaths.reviews).doc();
    await docRef.set(review.toFirestore());

    // Update user's average rating
    final userReviews = await _db
        .collection(FirestorePaths.reviews)
        .where('targetUserId', isEqualTo: review.targetUserId)
        .get();

    final ratings = userReviews.docs
        .map((d) => (d.data()['rating'] as num).toDouble())
        .toList();
    
    final averageRating = ratings.isEmpty 
        ? 0.0 
        : (ratings.fold<double>(0.0, (sum, item) => sum + item) / ratings.length);

    await _db.collection(FirestorePaths.users).doc(review.targetUserId).update({
      'rating': averageRating,
      'reviewCount': ratings.length,
    });
  }

  Stream<List<ReviewModel>> userReviewsStream(String userId) {
    return _db
        .collection(FirestorePaths.reviews)
        .where('targetUserId', isEqualTo: userId)
        .snapshots()
        .map((s) {
          final reviews =
              s.docs.map((d) => ReviewModel.fromFirestore(d)).toList();
          reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return reviews;
        });
  }

  Future<bool> hasReviewed(
      String reviewerId, String targetUserId, String gigId) async {
    final snapshot = await _db
        .collection(FirestorePaths.reviews)
        .where('reviewerId', isEqualTo: reviewerId)
        .where('targetUserId', isEqualTo: targetUserId)
        .where('gigId', isEqualTo: gigId)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }
}
