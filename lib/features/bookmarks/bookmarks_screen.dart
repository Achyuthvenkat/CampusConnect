import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:campus_connect/app/theme/app_colors.dart';
import 'package:campus_connect/core/models/user_model.dart';
import 'package:campus_connect/core/services/auth_service.dart';
import 'package:campus_connect/core/services/firestore_service.dart';
import 'package:campus_connect/widgets/common/avatar_widget.dart';
import 'package:campus_connect/widgets/common/skill_chip.dart';
import 'package:campus_connect/widgets/common/rating_bar_widget.dart';
import 'package:campus_connect/core/utils/helpers.dart';

class BookmarksScreen extends ConsumerWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(authServiceProvider).currentUserId ?? '';

    final currentUserAsync = ref.watch(
      StreamProvider.autoDispose<UserModel?>(
        (r) => ref.read(firestoreServiceProvider).userStream(uid),
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: const Text('Saved Freelancers'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: currentUserAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (currentUser) {
          if (currentUser == null || currentUser.bookmarks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.bookmark_border,
                      size: 64, color: AppColors.textHint),
                  const SizedBox(height: 12),
                  const Text(
                    'No saved freelancers yet.',
                    style: TextStyle(
                        fontSize: 14, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => context.pop(),
                    child: const Text('Explore freelancers'),
                  ),
                ],
              ),
            );
          }

          return FutureBuilder<List<UserModel>>(
            future: ref
                .read(firestoreServiceProvider)
                .getBookmarkedUsers(currentUser.bookmarks),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final users = snapshot.data!;

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: users.length,
                itemBuilder: (_, i) {
                  final user = users[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GestureDetector(
                      onTap: () =>
                          context.push('/home/profile/${user.uid}'),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Row(
                          children: [
                            Stack(
                              children: [
                                AvatarWidget(
                                    imageUrl: user.avatarUrl,
                                    name: user.name,
                                    radius: 28),
                                if (user.availability)
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: AppColors.accentGreen,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: Colors.white, width: 2),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(user.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14)),
                                  if (user.department.isNotEmpty)
                                    Text(
                                      user.department,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary),
                                    ),
                                  if (user.reviewCount > 0)
                                    StarRatingDisplay(
                                        rating: user.rating,
                                        itemSize: 12),
                                  if (user.skills.isNotEmpty)
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(top: 6),
                                      child: Wrap(
                                        spacing: 6,
                                        children: user.skills
                                            .take(2)
                                            .map((s) => SkillChip(label: s))
                                            .toList(),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (user.hourlyRate > 0)
                                  Text(
                                    '${AppHelpers.formatCurrencyCompact(user.hourlyRate)}/hr',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                        fontSize: 13),
                                  ),
                                const SizedBox(height: 4),
                                IconButton(
                                  icon: const Icon(Icons.bookmark,
                                      color: AppColors.primary, size: 20),
                                  onPressed: () async {
                                    await ref
                                        .read(firestoreServiceProvider)
                                        .toggleBookmark(uid, user.uid);
                                  },
                                  constraints: const BoxConstraints(),
                                  padding: EdgeInsets.zero,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
