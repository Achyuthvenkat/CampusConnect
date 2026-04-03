import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/review_model.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';

class UserProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();

  StreamSubscription<UserModel?>? _userSubscription;
  StreamSubscription<List<ReviewModel>>? _reviewsSubscription;

  UserModel? _user;
  List<ReviewModel> _reviews = [];
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get user => _user;
  List<ReviewModel> get reviews => _reviews;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void listenToUser(String uid) {
    _userSubscription?.cancel();
    _userSubscription = _firestoreService.userStream(uid).listen((user) {
      _user = user;
      notifyListeners();
    });
  }

  Future<void> loadUser(String uid) async {
    _setLoading(true);
    try {
      _user = await _firestoreService.getUser(uid);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadReviews(String uid) async {
    _reviewsSubscription?.cancel();
    _reviewsSubscription =
        _firestoreService.getUserReviews(uid).listen((reviews) {
      _reviews = reviews;
      notifyListeners();
    });
  }

  Future<bool> updateProfile({
    required String uid,
    String? name,
    String? bio,
    String? college,
    List<String>? skills,
    String? availability,
    double? hourlyRate,
    bool? isAvailable,
  }) async {
    _setLoading(true);
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (bio != null) updates['bio'] = bio;
      if (college != null) updates['college'] = college;
      if (skills != null) updates['skills'] = skills;
      if (availability != null) updates['availability'] = availability;
      if (hourlyRate != null) updates['hourlyRate'] = hourlyRate;
      if (isAvailable != null) updates['isAvailable'] = isAvailable;

      await _firestoreService.updateUser(uid, updates);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> uploadProfilePhoto(String uid, File file) async {
    _setLoading(true);
    try {
      final url = await _storageService.uploadProfilePhoto(uid, file);
      await _firestoreService.updateUser(uid, {'photoUrl': url});
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> addPortfolioItem(String uid, File file) async {
    _setLoading(true);
    try {
      final url = await _storageService.uploadPortfolioItem(uid, file);
      final currentUrls = List<String>.from(_user?.portfolioUrls ?? []);
      currentUrls.add(url);
      await _firestoreService.updateUser(uid, {'portfolioUrls': currentUrls});
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> removePortfolioItem(String uid, String url) async {
    _setLoading(true);
    try {
      await _storageService.deleteFile(url);
      final currentUrls = List<String>.from(_user?.portfolioUrls ?? []);
      currentUrls.remove(url);
      await _firestoreService.updateUser(uid, {'portfolioUrls': currentUrls});
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    _reviewsSubscription?.cancel();
    super.dispose();
  }
}
