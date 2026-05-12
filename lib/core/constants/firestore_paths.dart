class FirestorePaths {
  FirestorePaths._();

  // Collections
  static const String users = 'users';
  static const String gigs = 'gigs';
  static const String chats = 'chats';
  static const String reviews = 'reviews';
  static const String notifications = 'notifications';

  // Subcollections
  static const String bids = 'bids';
  static const String messages = 'messages';

  // Document paths
  static String userDoc(String uid) => '$users/$uid';
  static String gigDoc(String gigId) => '$gigs/$gigId';
  static String chatDoc(String chatId) => '$chats/$chatId';
  static String reviewDoc(String reviewId) => '$reviews/$reviewId';

  // Subcollection paths
  static String gigBids(String gigId) => '$gigs/$gigId/$bids';
  static String bidDoc(String gigId, String bidId) =>
      '$gigs/$gigId/$bids/$bidId';
  static String chatMessages(String chatId) => '$chats/$chatId/$messages';
  static String messageDoc(String chatId, String messageId) =>
      '$chats/$chatId/$messages/$messageId';

  // Storage paths
  static String userAvatar(String uid) => 'users/$uid/avatar';
  static String userPortfolio(String uid, String filename) =>
      'users/$uid/portfolio/$filename';
  static String gigAttachment(String gigId, String filename) =>
      'gigs/$gigId/attachments/$filename';
  static String chatImage(String chatId, String filename) =>
      'chats/$chatId/images/$filename';

  // Chat ID generation
  static String chatId(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }
}
