import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/job_model.dart';
import '../models/bid_model.dart';
import '../services/firestore_service.dart';

class JobsProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  StreamSubscription<List<JobModel>>? _jobsSubscription;
  StreamSubscription<List<JobModel>>? _postedJobsSubscription;
  StreamSubscription<List<JobModel>>? _assignedJobsSubscription;
  StreamSubscription<List<BidModel>>? _bidsSubscription;

  List<JobModel> _jobs = [];
  List<JobModel> _myPostedJobs = [];
  List<JobModel> _myAssignedJobs = [];
  List<BidModel> _myBids = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedCategory = 'All';
  double? _maxBudget;
  double? _minBudget;
  String _searchQuery = '';

  List<JobModel> get jobs => _jobs;
  List<JobModel> get myPostedJobs => _myPostedJobs;
  List<JobModel> get myAssignedJobs => _myAssignedJobs;
  List<BidModel> get myBids => _myBids;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedCategory => _selectedCategory;
  double? get maxBudget => _maxBudget;
  double? get minBudget => _minBudget;
  String get searchQuery => _searchQuery;

  void listenToJobs() {
    _jobsSubscription?.cancel();
    _jobsSubscription = _firestoreService
        .getJobsStream(
          category: _selectedCategory,
          maxBudget: _maxBudget,
          minBudget: _minBudget,
          searchQuery: _searchQuery,
        )
        .listen((jobs) {
      _jobs = jobs;
      notifyListeners();
    });
  }

  void listenToUserJobs(String userId) {
    _postedJobsSubscription?.cancel();
    _assignedJobsSubscription?.cancel();
    _bidsSubscription?.cancel();

    _postedJobsSubscription =
        _firestoreService.getUserJobs(userId).listen((jobs) {
      _myPostedJobs = jobs;
      notifyListeners();
    });
    _assignedJobsSubscription =
        _firestoreService.getFreelancerJobs(userId).listen((jobs) {
      _myAssignedJobs = jobs;
      notifyListeners();
    });
    _bidsSubscription =
        _firestoreService.getFreelancerBids(userId).listen((bids) {
      _myBids = bids;
      notifyListeners();
    });
  }

  void setCategory(String category) {
    _selectedCategory = category;
    listenToJobs();
    notifyListeners();
  }

  void setFilters({double? minBudget, double? maxBudget}) {
    _minBudget = minBudget;
    _maxBudget = maxBudget;
    listenToJobs();
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    listenToJobs();
    notifyListeners();
  }

  void clearFilters() {
    _selectedCategory = 'All';
    _maxBudget = null;
    _minBudget = null;
    _searchQuery = '';
    listenToJobs();
    notifyListeners();
  }

  Future<bool> createJob(JobModel job) async {
    _setLoading(true);
    try {
      await _firestoreService.createJob(job);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> submitBid(BidModel bid) async {
    _setLoading(true);
    try {
      await _firestoreService.createBid(bid);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> acceptBid(String bidId, String jobId, String freelancerId) async {
    _setLoading(true);
    try {
      await _firestoreService.updateBid(bidId, {'status': 'accepted'});
      await _firestoreService.updateJob(jobId, {
        'status': 'inProgress',
        'assignedFreelancerId': freelancerId,
      });
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> rejectBid(String bidId) async {
    _setLoading(true);
    try {
      await _firestoreService.updateBid(bidId, {'status': 'rejected'});
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> completeJob(String jobId, String? assignedFreelancerId) async {
    _setLoading(true);
    try {
      await _firestoreService.completeJob(jobId, assignedFreelancerId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Stream<List<BidModel>> getJobBids(String jobId) {
    return _firestoreService.getJobBids(jobId);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _jobsSubscription?.cancel();
    _postedJobsSubscription?.cancel();
    _assignedJobsSubscription?.cancel();
    _bidsSubscription?.cancel();
    super.dispose();
  }
}
