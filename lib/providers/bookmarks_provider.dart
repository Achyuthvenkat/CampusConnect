import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';

class BookmarksProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<UserModel> _bookmarkedFreelancers = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<UserModel> get bookmarkedFreelancers => _bookmarkedFreelancers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadBookmarks(List<String> ids) async {
    _setLoading(true);
    try {
      _bookmarkedFreelancers =
          await _firestoreService.getBookmarkedFreelancers(ids);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> toggleBookmark(String userId, String freelancerId) async {
    try {
      await _firestoreService.toggleBookmark(userId, freelancerId);
      // Refresh the bookmarks after toggle.
      final isBookmarked =
          _bookmarkedFreelancers.any((u) => u.uid == freelancerId);
      if (isBookmarked) {
        _bookmarkedFreelancers
            .removeWhere((u) => u.uid == freelancerId);
      } else {
        final freelancer =
            await _firestoreService.getUser(freelancerId);
        if (freelancer != null) {
          _bookmarkedFreelancers.add(freelancer);
        }
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  bool isBookmarked(String freelancerId) {
    return _bookmarkedFreelancers.any((u) => u.uid == freelancerId);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
