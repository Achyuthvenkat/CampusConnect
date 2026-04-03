import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/auth_provider.dart' as app_auth;
import '../../providers/user_provider.dart';
import '../../providers/bookmarks_provider.dart';
import '../../models/user_model.dart';
import '../../models/review_model.dart';
import '../../utils/theme.dart';
import '../../utils/helpers.dart';
import '../../widgets/review_card.dart';
import '../../widgets/rating_bar.dart';
import '../auth/login_screen.dart';
import 'edit_profile_screen.dart';
import 'portfolio_screen.dart';

class ProfileScreen extends StatelessWidget {
  final String? userId;
  const ProfileScreen({super.key, this.userId});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<app_auth.AuthProvider>();
    final currentUserId = authProvider.currentUser?.uid ?? '';
    final viewingUserId = userId ?? currentUserId;
    final isOwnProfile = viewingUserId == currentUserId;

    return _ProfileView(
      userId: viewingUserId,
      isOwnProfile: isOwnProfile,
    );
  }
}

class _ProfileView extends StatefulWidget {
  final String userId;
  final bool isOwnProfile;

  const _ProfileView({required this.userId, required this.isOwnProfile});

  @override
  State<_ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<_ProfileView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    if (!widget.isOwnProfile) {
      context.read<UserProvider>().loadUser(widget.userId);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final user = widget.isOwnProfile
        ? userProvider.user
        : null; // For other users, we'd need a separate load

    if (user == null && widget.isOwnProfile) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    return _buildProfile(context, user, userProvider);
  }

  Widget _buildProfile(
      BuildContext context, UserModel? user, UserProvider userProvider) {
    if (user == null) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    final bookmarksProvider = context.watch<BookmarksProvider>();
    final authProvider = context.read<app_auth.AuthProvider>();
    final currentUserId = authProvider.currentUser?.uid ?? '';

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppTheme.primaryColor,
            actions: [
              if (widget.isOwnProfile)
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const EditProfileScreen()),
                  ),
                )
              else
                IconButton(
                  icon: Icon(
                    bookmarksProvider.isBookmarked(user.uid)
                        ? Icons.bookmark
                        : Icons.bookmark_outline,
                  ),
                  onPressed: () => bookmarksProvider.toggleBookmark(
                      currentUserId, user.uid),
                ),
              if (widget.isOwnProfile)
                PopupMenuButton(
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'signout',
                      child: Text('Sign Out'),
                    ),
                  ],
                  onSelected: (value) async {
                    if (value == 'signout') {
                      await authProvider.signOut();
                      if (!context.mounted) return;
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const LoginScreen()),
                        (_) => false,
                      );
                    }
                  },
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppTheme.primaryColor, Color(0xFF9C88FF)],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 48),
                      _avatar(user),
                      const SizedBox(height: 12),
                      Text(
                        user.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        user.college,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _statsRow(user),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: AppTheme.primaryColor,
                unselectedLabelColor: AppTheme.textSecondary,
                indicatorColor: AppTheme.primaryColor,
                tabs: const [
                  Tab(text: 'About'),
                  Tab(text: 'Portfolio'),
                  Tab(text: 'Reviews'),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _AboutTab(user: user),
            PortfolioScreen(user: user, isOwnProfile: widget.isOwnProfile),
            _ReviewsTab(reviews: userProvider.reviews),
          ],
        ),
      ),
    );
  }

  Widget _avatar(UserModel user) {
    if (user.photoUrl != null) {
      return CircleAvatar(
        radius: 44,
        backgroundImage: CachedNetworkImageProvider(user.photoUrl!),
      );
    }
    return CircleAvatar(
      radius: 44,
      backgroundColor: Colors.white,
      child: Text(
        Helpers.getInitials(user.name),
        style: const TextStyle(
          color: AppTheme.primaryColor,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _statsRow(UserModel user) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _stat('${user.completedJobs}', 'Jobs Done'),
          _divider(),
          _stat(user.rating.toStringAsFixed(1), 'Rating'),
          _divider(),
          _stat('${user.reviewCount}', 'Reviews'),
          _divider(),
          _stat(
            user.hourlyRate > 0
                ? Helpers.formatCurrency(user.hourlyRate)
                : 'N/A',
            '/ hr',
          ),
        ],
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _divider() => Container(
        height: 40,
        width: 1,
        color: Colors.grey.shade200,
      );
}

class _AboutTab extends StatelessWidget {
  final UserModel user;

  const _AboutTab({required this.user});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (user.bio != null && user.bio!.isNotEmpty) ...[
          const Text(
            'Bio',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            user.bio!,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
        ],
        if (user.skills.isNotEmpty) ...[
          const Text(
            'Skills',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: user.skills.map((skill) {
              return Chip(
                label: Text(skill),
                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                side: BorderSide.none,
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
        ],
        if (user.availability != null) ...[
          _InfoRow(
            icon: Icons.access_time,
            label: 'Availability',
            value: user.availability!,
          ),
          const SizedBox(height: 12),
        ],
        if (user.hourlyRate > 0)
          _InfoRow(
            icon: Icons.attach_money,
            label: 'Hourly Rate',
            value: '${Helpers.formatCurrency(user.hourlyRate)}/hr',
          ),
        const SizedBox(height: 12),
        _InfoRow(
          icon: Icons.calendar_today,
          label: 'Member Since',
          value: Helpers.formatDate(user.createdAt),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primaryColor),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        Text(value, style: const TextStyle(color: AppTheme.textSecondary)),
      ],
    );
  }
}

class _ReviewsTab extends StatelessWidget {
  final List<ReviewModel> reviews;

  const _ReviewsTab({required this.reviews});

  @override
  Widget build(BuildContext context) {
    if (reviews.isEmpty) {
      return const Center(
        child: Text('No reviews yet',
            style: TextStyle(color: AppTheme.textSecondary)),
      );
    }
    return ListView.builder(
      itemCount: reviews.length,
      itemBuilder: (_, i) => ReviewCard(review: reviews[i]),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _TabBarDelegate(this.tabBar);

  @override
  Widget build(
          BuildContext context, double shrinkOffset, bool overlapsContent) =>
      Container(color: Colors.white, child: tabBar);

  @override
  double get maxExtent => tabBar.preferredSize.height;
  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  bool shouldRebuild(_TabBarDelegate old) => false;
}
