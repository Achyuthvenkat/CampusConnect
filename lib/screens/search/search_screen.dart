import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart' as app_auth;
import '../../providers/user_provider.dart';
import '../../providers/bookmarks_provider.dart';
import '../../services/firestore_service.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';
import '../../widgets/freelancer_card.dart';
import '../../widgets/job_card.dart';
import '../profile/profile_screen.dart';
import '../jobs/job_detail_screen.dart';
import '../../models/job_model.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchCtrl = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();

  List<UserModel> _freelancers = [];
  bool _isLoading = false;
  String _selectedSkill = '';
  double? _maxRate;
  double? _minRating;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchFreelancers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _searchFreelancers() async {
    setState(() => _isLoading = true);
    try {
      final results = await _firestoreService.searchFreelancers(
        skill: _selectedSkill.isEmpty ? null : _selectedSkill,
        maxRate: _maxRate,
        minRating: _minRating,
        query: _searchCtrl.text.trim(),
      );
      setState(() => _freelancers = results);
    } catch (e) {
      // Handle error silently.
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _FreelancerFilterSheet(
        initialSkill: _selectedSkill,
        initialMaxRate: _maxRate,
        initialMinRating: _minRating,
        onApply: (skill, maxRate, minRating) {
          setState(() {
            _selectedSkill = skill;
            _maxRate = maxRate;
            _minRating = minRating;
          });
          _searchFreelancers();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<app_auth.AuthProvider>();
    final bookmarksProvider = context.watch<BookmarksProvider>();
    final currentUserId = authProvider.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Freelancers'),
            Tab(text: 'Jobs'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          _searchFreelancers();
                        },
                      )
                    : null,
              ),
              onSubmitted: (_) => _searchFreelancers(),
              onChanged: (v) {
                if (v.isEmpty) _searchFreelancers();
              },
              textInputAction: TextInputAction.search,
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _freelancers.isEmpty
                        ? const Center(
                            child: Text(
                              'No freelancers found',
                              style:
                                  TextStyle(color: AppTheme.textSecondary),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _freelancers.length,
                            itemBuilder: (_, i) {
                              final user = _freelancers[i];
                              return FreelancerCard(
                                user: user,
                                isBookmarked:
                                    bookmarksProvider.isBookmarked(user.uid),
                                onBookmark: () =>
                                    bookmarksProvider.toggleBookmark(
                                        currentUserId, user.uid),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ProfileScreen(userId: user.uid),
                                  ),
                                ),
                              );
                            },
                          ),
                const _JobSearchTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _JobSearchTab extends StatelessWidget {
  const _JobSearchTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Use the Jobs tab to browse and filter jobs',
        style: TextStyle(color: AppTheme.textSecondary),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _FreelancerFilterSheet extends StatefulWidget {
  final String initialSkill;
  final double? initialMaxRate;
  final double? initialMinRating;
  final void Function(String skill, double? maxRate, double? minRating)
      onApply;

  const _FreelancerFilterSheet({
    required this.initialSkill,
    this.initialMaxRate,
    this.initialMinRating,
    required this.onApply,
  });

  @override
  State<_FreelancerFilterSheet> createState() =>
      _FreelancerFilterSheetState();
}

class _FreelancerFilterSheetState extends State<_FreelancerFilterSheet> {
  late String _skill;
  late TextEditingController _maxRateCtrl;
  double _minRating = 0;

  @override
  void initState() {
    super.initState();
    _skill = widget.initialSkill;
    _maxRateCtrl =
        TextEditingController(text: widget.initialMaxRate?.toString() ?? '');
    _minRating = widget.initialMinRating ?? 0;
  }

  @override
  void dispose() {
    _maxRateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Filter Freelancers',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _skill.isEmpty ? null : _skill,
            hint: const Text('Any Skill'),
            decoration: const InputDecoration(labelText: 'Skill'),
            items: AppConstants.skillCategories
                .where((s) => s != 'All')
                .map((s) =>
                    DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (v) => setState(() => _skill = v ?? ''),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _maxRateCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Max Hourly Rate (\$)',
              prefixIcon: Icon(Icons.attach_money),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Minimum Rating: ${_minRating.toStringAsFixed(1)}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Slider(
            value: _minRating,
            min: 0,
            max: 5,
            divisions: 10,
            label: _minRating.toStringAsFixed(1),
            activeColor: AppTheme.primaryColor,
            onChanged: (v) => setState(() => _minRating = v),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              widget.onApply(
                _skill,
                _maxRateCtrl.text.isEmpty
                    ? null
                    : double.tryParse(_maxRateCtrl.text),
                _minRating > 0 ? _minRating : null,
              );
              Navigator.pop(context);
            },
            child: const Text('Apply Filters'),
          ),
        ],
      ),
    );
  }
}
