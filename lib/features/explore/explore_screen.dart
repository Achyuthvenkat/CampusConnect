import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:campus_connect/app/theme/app_colors.dart';
import 'package:campus_connect/core/constants/app_constants.dart';
import 'package:campus_connect/core/models/user_model.dart';
import 'package:campus_connect/core/services/auth_service.dart';
import 'package:campus_connect/core/services/firestore_service.dart';
import 'package:campus_connect/core/utils/helpers.dart';
import 'package:campus_connect/core/models/filter_models.dart';
import 'package:campus_connect/widgets/common/avatar_widget.dart';
import 'package:campus_connect/widgets/common/skill_chip.dart';
import 'package:campus_connect/widgets/common/rating_bar_widget.dart';
import 'package:campus_connect/core/services/chat_service.dart';

// Providers
final searchQueryProvider = StateProvider<String>((ref) => '');
final selectedExploreCategoryProvider = StateProvider<String>((ref) => 'All');
final filterAvailableOnlyProvider = StateProvider<bool>((ref) => false);
final maxRateFilterProvider = StateProvider<double?>((ref) => null);
final minRatingFilterProvider = StateProvider<double>((ref) => 0);

final freelancersProvider =
    FutureProvider.autoDispose.family<List<UserModel>, ExploreFilters>(
        (ref, filters) async {
  final service = ref.read(firestoreServiceProvider);
  return service.searchFreelancers(
    query: filters.query,
    availableOnly: filters.availableOnly,
    maxRate: filters.maxRate,
    minRating: filters.minRating,
  );
});

class ExploreScreen extends ConsumerWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(authServiceProvider).currentUserId ?? '';
    final searchQuery = ref.watch(searchQueryProvider);
    final selectedCategory = ref.watch(selectedExploreCategoryProvider);
    final availableOnly = ref.watch(filterAvailableOnlyProvider);
    final maxRate = ref.watch(maxRateFilterProvider);
    final minRating = ref.watch(minRatingFilterProvider);
    final hasFilters = availableOnly || maxRate != null || minRating > 0;

    final filters = ExploreFilters(
      query: searchQuery,
      availableOnly: availableOnly,
      maxRate: maxRate,
      minRating: minRating,
    );

    final freelancersAsync = ref.watch(freelancersProvider(filters));

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            backgroundColor: AppColors.white,
            elevation: 0,
            title: const Text('Explore'),
            actions: [
              IconButton(
                icon: Stack(
                  children: [
                    const Icon(Icons.tune),
                    if (hasFilters)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                onPressed: () => _showFilterSheet(context, ref),
              ),
            ],
          ),

          // Search
          SliverToBoxAdapter(
            child: Container(
              color: AppColors.white,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: _SearchBar(
                onChanged: (q) =>
                    ref.read(searchQueryProvider.notifier).state = q,
              ),
            ),
          ),

          // Categories
          SliverToBoxAdapter(
            child: Container(
              color: AppColors.white,
              padding: const EdgeInsets.only(bottom: 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: AppConstants.gigCategories.map((cat) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: CategoryChip(
                        label: cat,
                        isSelected: cat == selectedCategory,
                        onTap: () => ref
                            .read(selectedExploreCategoryProvider.notifier)
                            .state = cat,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),

          // Active filters
          if (hasFilters)
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  children: [
                    const Icon(Icons.filter_alt_outlined,
                        size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                    const Text('Filters active',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500)),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        ref
                            .read(filterAvailableOnlyProvider.notifier)
                            .state = false;
                        ref.read(maxRateFilterProvider.notifier).state = null;
                        ref.read(minRatingFilterProvider.notifier).state = 0;
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Clear all',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary)),
                    ),
                  ],
                ),
              ),
            ),

          // Results
          freelancersAsync.when(
            loading: () => SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                  child: _FreelancerShimmer(),
                ),
                childCount: 6,
              ),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: Colors.redAccent),
                      const SizedBox(height: 16),
                      Text(
                        'Error: ${e.toString()}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(freelancersProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            data: (users) {
              final filtered = users
                  .where((u) => u.uid != uid)
                  .where((u) =>
                      selectedCategory == 'All' ||
                      u.skills.any((s) => s
                          .toLowerCase()
                          .contains(selectedCategory.toLowerCase())))
                  .toList();

              if (filtered.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off,
                            size: 64, color: AppColors.textHint),
                        const SizedBox(height: 12),
                        Text(
                          searchQuery.isNotEmpty
                              ? 'No results for "$searchQuery"'
                              : 'No freelancers found',
                          style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: FreelancerCard(
                        user: filtered[index],
                        currentUserId: uid,
                        onTap: () => context
                            .push('/home/profile/${filtered[index].uid}'),
                      ),
                    ),
                    childCount: filtered.length,
                  ),
                ),
              );
            },
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  void _showFilterSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _FilterSheet(ref: ref),
    );
  }
}

class FreelancerCard extends ConsumerStatefulWidget {
  final UserModel user;
  final String currentUserId;
  final VoidCallback onTap;

  const FreelancerCard({
    super.key,
    required this.user,
    required this.currentUserId,
    required this.onTap,
  });

  @override
  ConsumerState<FreelancerCard> createState() => _FreelancerCardState();
}

class _FreelancerCardState extends ConsumerState<FreelancerCard> {
  bool _bookmarkLoading = false;

  Future<void> _toggleBookmark() async {
    setState(() => _bookmarkLoading = true);
    await ref
        .read(firestoreServiceProvider)
        .toggleBookmark(widget.currentUserId, widget.user.uid);
    setState(() => _bookmarkLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    // Watch current user for bookmark state
    final currentUserAsync = ref.watch(
      StreamProvider.autoDispose<UserModel?>(
        (r) => ref.read(firestoreServiceProvider).userStream(widget.currentUserId),
      ),
    );
    final isBookmarked = currentUserAsync.valueOrNull?.bookmarks
            .contains(widget.user.uid) ??
        false;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              children: [
                AvatarWidget(
                    imageUrl: widget.user.avatarUrl,
                    name: widget.user.name,
                    radius: 30),
                if (widget.user.availability)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppColors.accentGreen,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.user.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (widget.user.hourlyRate > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${AppHelpers.formatCurrencyCompact(widget.user.hourlyRate)}/hr',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (widget.user.department.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '${widget.user.department} · Year ${widget.user.year}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ),
                  if (widget.user.reviewCount > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          StarRatingDisplay(
                              rating: widget.user.rating,
                              itemSize: 12,
                              showText: true),
                          Text(
                            ' (${widget.user.reviewCount})',
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  if (widget.user.skills.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: widget.user.skills.take(3).map((s) {
                          return SkillChip(label: s);
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              onPressed: () async {
                final uid = ref.read(authServiceProvider).currentUserId ?? '';
                if (uid.isEmpty || uid == widget.user.uid) return; // Can't message self or if not logged in

                final chatService = ref.read(chatServiceProvider);
                final chatId = await chatService.getOrCreateChat(uid, widget.user.uid);
                
                if (context.mounted) {
                  context.push(
                    '/home/chat/$chatId/${widget.user.uid}/${Uri.encodeComponent(widget.user.name)}',
                  );
                }
              },
              icon: const Icon(
                Icons.chat_bubble_outline,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            _bookmarkLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : IconButton(
                    onPressed: _toggleBookmark,
                    icon: Icon(
                      isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                      color: isBookmarked
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      size: 22,
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class _SearchBar extends StatefulWidget {
  final void Function(String) onChanged;

  const _SearchBar({required this.onChanged});

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: (v) {
        setState(() {});
        widget.onChanged(v);
      },
      decoration: InputDecoration(
        hintText: 'Search skills, names, departments...',
        prefixIcon:
            const Icon(Icons.search, color: AppColors.textHint, size: 20),
        suffixIcon: _controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () {
                  _controller.clear();
                  widget.onChanged('');
                  setState(() {});
                },
              )
            : null,
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  final WidgetRef ref;

  const _FilterSheet({required this.ref});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late bool _availableOnly;
  late double _minRating;
  late double _maxRate;
  bool _useMaxRate = false;

  @override
  void initState() {
    super.initState();
    _availableOnly = widget.ref.read(filterAvailableOnlyProvider);
    _minRating = widget.ref.read(minRatingFilterProvider);
    final existingMax = widget.ref.read(maxRateFilterProvider);
    _maxRate = existingMax ?? 1000;
    _useMaxRate = existingMax != null;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Filters',
                    style: Theme.of(context).textTheme.headlineSmall),
                const Spacer(),
                IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context)),
              ],
            ),
            SwitchListTile(
              title: const Text('Available Only',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              subtitle: const Text('Only freelancers open for work'),
              value: _availableOnly,
              onChanged: (v) => setState(() => _availableOnly = v),
              activeColor: AppColors.primary,
              contentPadding: EdgeInsets.zero,
            ),
            const Divider(),
            const SizedBox(height: 8),
            Text(
                'Minimum Rating: ${_minRating == 0 ? 'Any' : _minRating.toStringAsFixed(1)}⭐',
                style: const TextStyle(
                    fontWeight: FontWeight.w500, fontSize: 14)),
            Slider(
              value: _minRating,
              min: 0,
              max: 5,
              divisions: 10,
              onChanged: (v) => setState(() => _minRating = v),
              activeColor: AppColors.primary,
            ),
            Row(
              children: [
                Text('Max Hourly Rate',
                    style: const TextStyle(
                        fontWeight: FontWeight.w500, fontSize: 14)),
                const Spacer(),
                Switch(
                    value: _useMaxRate,
                    onChanged: (v) => setState(() => _useMaxRate = v),
                    activeColor: AppColors.primary),
              ],
            ),
            if (_useMaxRate) ...[
              Slider(
                value: _maxRate,
                min: 100,
                max: 5000,
                divisions: 49,
                label: '₹${_maxRate.toInt()}/hr',
                onChanged: (v) => setState(() => _maxRate = v),
                activeColor: AppColors.primary,
              ),
              Text('Up to ₹${_maxRate.toInt()}/hr',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  widget.ref
                      .read(filterAvailableOnlyProvider.notifier)
                      .state = _availableOnly;
                  widget.ref
                      .read(minRatingFilterProvider.notifier)
                      .state = _minRating;
                  widget.ref.read(maxRateFilterProvider.notifier).state =
                      _useMaxRate ? _maxRate : null;
                  Navigator.pop(context);
                },
                child: const Text('Apply Filters'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FreelancerShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFEEF0F5),
      highlightColor: Colors.white,
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
