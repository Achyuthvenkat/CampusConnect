import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:campus_connect/app/theme/app_colors.dart';
import 'package:campus_connect/core/models/user_model.dart';
import 'package:campus_connect/core/models/review_model.dart';
import 'package:campus_connect/core/services/auth_service.dart';
import 'package:campus_connect/core/services/firestore_service.dart';
import 'package:campus_connect/core/services/chat_service.dart';
import 'package:campus_connect/core/utils/helpers.dart';
import 'package:campus_connect/widgets/common/avatar_widget.dart';
import 'package:campus_connect/widgets/common/skill_chip.dart';
import 'package:campus_connect/widgets/common/rating_bar_widget.dart';
import 'package:campus_connect/widgets/cards/review_card.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

final _profileUserProvider =
    StreamProvider.autoDispose.family<UserModel?, String>((ref, uid) {
  return ref.read(firestoreServiceProvider).userStream(uid);
});

final _userReviewsProvider =
    StreamProvider.autoDispose.family<List<ReviewModel>, String>((ref, uid) {
  return ref.read(firestoreServiceProvider).userReviewsStream(uid);
});

class ProfileScreen extends ConsumerWidget {
  final String userId;

  const ProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUid = ref.watch(authServiceProvider).currentUserId ?? '';
    final isOwnProfile = currentUid == userId;

    final userAsync = ref.watch(_profileUserProvider(userId));
    final reviewsAsync = ref.watch(_userReviewsProvider(userId));

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('User not found'));
          }

          return CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                backgroundColor: AppColors.white,
                elevation: 0,
                floating: true,
                leading: !isOwnProfile
                    ? IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                        onPressed: () => context.pop(),
                      )
                    : null,
                actions: [
                  if (isOwnProfile)
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => context.push('/home/edit-profile'),
                    ),
                  if (isOwnProfile)
                    IconButton(
                      icon: const Icon(Icons.logout),
                      onPressed: () async {
                        await ref.read(authServiceProvider).signOut();
                        if (context.mounted) context.go('/login');
                      },
                    ),
                ],
              ),

              // Profile Header
              SliverToBoxAdapter(
                child: Container(
                  color: AppColors.white,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Avatar + availability
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          AvatarWidget(
                            imageUrl: user.avatarUrl,
                            name: user.name,
                            radius: 48,
                          ),
                          if (user.availability)
                            Positioned(
                              right: 0,
                              bottom: 4,
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: AppColors.accentGreen,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.white, width: 2.5),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Text(user.name,
                          style:
                              Theme.of(context).textTheme.headlineMedium),
                      if (user.department.isNotEmpty)
                        Text(
                          '${user.department} · Year ${user.year}',
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.textSecondary),
                        ),
                      const SizedBox(height: 6),

                      // Rating
                      if (user.reviewCount > 0)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            StarRatingDisplay(
                                rating: user.rating, itemSize: 16),
                            const SizedBox(width: 6),
                            Text(
                              '(${user.reviewCount} reviews)',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary),
                            ),
                          ],
                        )
                      else
                        const Text('No reviews yet',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary)),

                      const SizedBox(height: 16),

                      // Stats row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _StatItem(
                            label: 'Rate',
                            value: user.hourlyRate > 0
                                ? '${AppHelpers.formatCurrencyCompact(user.hourlyRate)}/hr'
                                : 'N/A',
                          ),
                          _VerticalDivider(),
                          _StatItem(
                            label: 'Status',
                            value: user.availability
                                ? 'Available'
                                : 'Unavailable',
                            valueColor: user.availability
                                ? AppColors.accentGreen
                                : AppColors.error,
                          ),
                          _VerticalDivider(),
                          _StatItem(
                            label: 'Skills',
                            value: '${user.skills.length}',
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Action buttons
                      if (!isOwnProfile)
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  final chatId = await ref
                                      .read(chatServiceProvider)
                                      .getOrCreateChat(currentUid, userId);
                                  if (context.mounted) {
                                    context.push(
                                        '/home/chat/$chatId/$userId/${Uri.encodeComponent(user.name)}');
                                  }
                                },
                                icon: const Icon(Icons.chat_bubble_outline,
                                    size: 18),
                                label: const Text('Message'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            _BookmarkIconButton(
                              targetUserId: userId,
                              currentUserId: currentUid,
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),

              // Bio
              if (user.bio.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: _Section(
                      title: 'About',
                      child: Text(
                        user.bio,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ),
                ),

              // Skills
              if (user.skills.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: _Section(
                      title: 'Skills',
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: user.skills
                            .map((s) => SkillChip(label: s, isSelected: true))
                            .toList(),
                      ),
                    ),
                  ),
                ),

              // Portfolio
              if (user.portfolioUrls.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: _Section(
                      title: 'Portfolio',
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 6,
                          mainAxisSpacing: 6,
                        ),
                        itemCount: user.portfolioUrls.length,
                        itemBuilder: (_, i) => GestureDetector(
                          onTap: () => _openPortfolio(
                              context, user.portfolioUrls, i),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              user.portfolioUrls[i],
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // Reviews
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: reviewsAsync.when(
                    loading: () => const SizedBox(),
                    error: (_, __) => const SizedBox(),
                    data: (reviews) => _Section(
                      title: 'Reviews (${reviews.length})',
                      child: reviews.isEmpty
                          ? const Text(
                              'No reviews yet.',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary),
                            )
                          : Column(
                              children: reviews
                                  .map((r) => Padding(
                                        padding: const EdgeInsets.only(
                                            bottom: 10),
                                        child: ReviewCard(review: r),
                                      ))
                                  .toList(),
                            ),
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          );
        },
      ),
    );
  }

  void _openPortfolio(
      BuildContext context, List<String> urls, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _PortfolioGallery(urls: urls, initialIndex: index),
      ),
    );
  }
}

class _PortfolioGallery extends StatelessWidget {
  final List<String> urls;
  final int initialIndex;

  const _PortfolioGallery(
      {required this.urls, required this.initialIndex});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: PhotoViewGallery.builder(
        itemCount: urls.length,
        backgroundDecoration: const BoxDecoration(color: Colors.black),
        pageController: PageController(initialPage: initialIndex),
        builder: (_, i) => PhotoViewGalleryPageOptions(
          imageProvider: NetworkImage(urls[i]),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 2,
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _StatItem(
      {required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style:
              const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(height: 32, width: 1, color: AppColors.divider);
  }
}

class _BookmarkIconButton extends ConsumerStatefulWidget {
  final String targetUserId;
  final String currentUserId;

  const _BookmarkIconButton(
      {required this.targetUserId, required this.currentUserId});

  @override
  ConsumerState<_BookmarkIconButton> createState() =>
      _BookmarkIconButtonState();
}

class _BookmarkIconButtonState
    extends ConsumerState<_BookmarkIconButton> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final currentUserAsync = ref.watch(
        _profileUserProvider(widget.currentUserId));
    final isBookmarked =
        currentUserAsync.valueOrNull?.bookmarks.contains(widget.targetUserId) ??
            false;

    return IconButton.outlined(
      onPressed: _loading
          ? null
          : () async {
              setState(() => _loading = true);
              await ref.read(firestoreServiceProvider).toggleBookmark(
                  widget.currentUserId, widget.targetUserId);
              setState(() => _loading = false);
            },
      icon: _loading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2))
          : Icon(
              isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: isBookmarked ? AppColors.primary : AppColors.textSecondary,
            ),
    );
  }
}
