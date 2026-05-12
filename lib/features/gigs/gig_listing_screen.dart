import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:campus_connect/app/theme/app_colors.dart';
import 'package:campus_connect/core/constants/app_constants.dart';
import 'package:campus_connect/core/models/gig_model.dart';
import 'package:campus_connect/core/models/filter_models.dart';
import 'package:campus_connect/core/services/auth_service.dart';
import 'package:campus_connect/core/services/firestore_service.dart';
import 'package:campus_connect/widgets/cards/gig_card.dart';
import 'package:campus_connect/widgets/common/skill_chip.dart';
import 'package:campus_connect/core/services/chat_service.dart';

final gigCategoryFilterProvider =
    StateProvider<String>((ref) => 'All');
final gigStatusFilterProvider =
    StateProvider<String>((ref) => 'open');

final gigsStreamProvider =
    StreamProvider.autoDispose.family<List<GigModel>, GigFilters>((ref, filters) {
  return ref.read(firestoreServiceProvider).gigsStream(
        category: filters.category,
        status: filters.status,
      );
});

class GigListingScreen extends ConsumerWidget {
  const GigListingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = ref.watch(gigCategoryFilterProvider);
    final status = ref.watch(gigStatusFilterProvider);

    final filters = GigFilters(
      category: category == 'All' ? null : category,
      status: status,
    );

    final gigsAsync = ref.watch(gigsStreamProvider(filters));

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(
            floating: true,
            backgroundColor: AppColors.white,
            elevation: 0,
            title: Text('Gig Board'),
          ),

          // Status tabs
          SliverToBoxAdapter(
            child: Container(
              color: AppColors.white,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: ['open', 'in-progress', 'completed'].map((s) {
                  final isSelected = s == status;
                  final label = {
                    'open': 'Open',
                    'in-progress': 'In Progress',
                    'completed': 'Completed',
                  }[s]!;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => ref
                          .read(gigStatusFilterProvider.notifier)
                          .state = s,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: EdgeInsets.only(right: s != 'completed' ? 6 : 0),
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Category chips
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
                        isSelected: cat == category,
                        onTap: () => ref
                            .read(gigCategoryFilterProvider.notifier)
                            .state = cat,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),

          // Gig list
          gigsAsync.when(
            loading: () => SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                  child: _GigShimmer(),
                ),
                childCount: 5,
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
                        onPressed: () => ref.invalidate(gigsStreamProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            data: (gigs) {
              if (gigs.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.work_off_outlined,
                            size: 64, color: AppColors.textHint),
                        const SizedBox(height: 12),
                        const Text('No gigs available right now.',
                            style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14)),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () =>
                              context.push('/home/create-gig'),
                          icon: const Icon(Icons.add),
                          label: const Text('Post a Gig'),
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
                      child: GigCard(
                        gig: gigs[index],
                        onTap: () =>
                            context.push('/home/gig/${gigs[index].id}'),
                        onMessage: ref.watch(authServiceProvider).currentUserId == gigs[index].clientId
                            ? null
                            : () async {
                                final uid = ref.read(authServiceProvider).currentUserId ?? '';
                                final chatService = ref.read(chatServiceProvider);
                                final chatId = await chatService.getOrCreateChat(uid, gigs[index].clientId);
                                if (context.mounted) {
                                  context.push(
                                    '/home/chat/$chatId/${gigs[index].clientId}/${Uri.encodeComponent(gigs[index].clientName)}',
                                  );
                                }
                              },
                      ),
                    ),
                    childCount: gigs.length,
                  ),
                ),
              );
            },
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 96)),
        ],
      ),
    );
  }
}

class _GigShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFEEF0F5),
      highlightColor: Colors.white,
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
