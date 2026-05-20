import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:campus_connect/app/theme/app_colors.dart';
import 'package:campus_connect/core/models/gig_model.dart';
import 'package:campus_connect/core/models/bid_model.dart';
import 'package:campus_connect/core/services/auth_service.dart';
import 'package:campus_connect/core/services/firestore_service.dart';
import 'package:campus_connect/core/services/chat_service.dart';
import 'package:campus_connect/core/utils/helpers.dart';
import 'package:campus_connect/widgets/common/avatar_widget.dart';
import 'package:campus_connect/widgets/common/custom_button.dart';
import 'package:campus_connect/widgets/common/rating_bar_widget.dart';
import 'package:campus_connect/features/gigs/bid_sheet.dart';
import 'package:campus_connect/widgets/common/skill_chip.dart';
import 'package:campus_connect/features/gigs/delivery_section.dart';

final _gigDetailProvider = FutureProvider.autoDispose
    .family<GigModel?, String>((ref, gigId) async {
  return ref.read(firestoreServiceProvider).getGig(gigId);
});

final _gigBidsProvider =
    StreamProvider.autoDispose.family<List<BidModel>, String>((ref, gigId) {
  return ref.read(firestoreServiceProvider).gigBidsStream(gigId);
});

class GigDetailScreen extends ConsumerWidget {
  final String gigId;

  const GigDetailScreen({super.key, required this.gigId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gigAsync = ref.watch(_gigDetailProvider(gigId));
    final bidsAsync = ref.watch(_gigBidsProvider(gigId));
    final uid = ref.watch(authServiceProvider).currentUserId ?? '';

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: gigAsync.when(
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Scaffold(
          appBar: AppBar(),
          body: Center(child: Text('Error: $e')),
        ),
        data: (gig) {
          if (gig == null) {
            return Scaffold(
              appBar: AppBar(),
              body: const Center(child: Text('Gig not found')),
            );
          }

          final isOwner = gig.clientId == uid;
          final isOpen = gig.isOpen;
          final statusColor = AppHelpers.getStatusColor(gig.status);

          final bids = bidsAsync.maybeWhen(data: (d) => d, orElse: () => <BidModel>[]);
          final winningBid = bids.where((b) => b.id == gig.selectedBidId).firstOrNull;
          final isWinner = winningBid?.bidderId == uid;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                floating: true,
                backgroundColor: AppColors.white,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                  onPressed: () => context.pop(),
                ),
                actions: [
                  if (!isOwner && isOpen)
                    Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: ElevatedButton(
                        onPressed: () => _showBidSheet(context, gig, uid, ref),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 8),
                        ),
                        child: const Text('Place Bid'),
                      ),
                    ),
                ],
              ),

              SliverToBoxAdapter(
                child: Container(
                  color: AppColors.white,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          AppHelpers.getStatusLabel(gig.status),
                          style: TextStyle(
                            fontSize: 12,
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Title
                      Text(gig.title,
                          style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 12),

                      // Meta row
                      Row(
                        children: [
                          _MetaItem(
                            icon: Icons.account_balance_wallet_outlined,
                            label: AppHelpers.formatCurrency(gig.budget),
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 16),
                          _MetaItem(
                            icon: Icons.schedule,
                            label: AppHelpers.daysRemaining(gig.deadline),
                            color: gig.daysLeft <= 2
                                ? AppColors.error
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 16),
                          _MetaItem(
                            icon: Icons.people_outline,
                            label: '${gig.bidCount} bids',
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 12),

                      // Client info
                      Row(
                        children: [
                          AvatarWidget(
                            imageUrl: gig.clientAvatarUrl,
                            name: gig.clientName,
                            radius: 22,
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(gig.clientName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14)),
                              Text('Posted ${AppHelpers.formatDate(gig.createdAt)}',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary)),
                            ],
                          ),
                          const Spacer(),
                          if (!isOwner)
                            TextButton(
                              onPressed: () async {
                                final chatService =
                                    ref.read(chatServiceProvider);
                                final chatId =
                                    await chatService.getOrCreateChat(
                                        uid, gig.clientId);
                                if (context.mounted) {
                                  context.push(
                                      '/home/chat/$chatId/${gig.clientId}/${Uri.encodeComponent(gig.clientName)}');
                                }
                              },
                              child: const Text('Message'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              DeliverySection(gig: gig, isOwner: isOwner, isWinner: isWinner),

              // Description
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionHeader('Description'),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Text(
                          gig.description,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            height: 1.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Tags
              if (gig.tags.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionHeader('Tags'),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: gig.tags
                              .map((t) => SkillChip(label: t, isSelected: true))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ),

              // Attachments
              if (gig.attachmentUrls.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionHeader('Attachments'),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 80,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: gig.attachmentUrls.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 8),
                            itemBuilder: (_, i) => ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                gig.attachmentUrls[i],
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Bids section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: _SectionHeader('Bids (${gig.bidCount})'),
                ),
              ),

              bidsAsync.when(
                loading: () => const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
                error: (e, _) => const SliverToBoxAdapter(child: SizedBox()),
                data: (bids) {
                  if (bids.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Center(
                          child: Column(
                            children: [
                              const Icon(Icons.inbox_outlined,
                                  size: 40, color: AppColors.textHint),
                              const SizedBox(height: 8),
                              const Text('No bids yet.',
                                  style: TextStyle(
                                      color: AppColors.textSecondary)),
                              if (!isOwner && isOpen) ...[
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: () =>
                                      _showBidSheet(context, gig, uid, ref),
                                  child: const Text('Be the first to bid!'),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _BidCard(
                            bid: bids[i],
                            isOwner: isOwner,
                            gigStatus: gig.status,
                            onAccept: isOwner && isOpen
                                ? () => _acceptBid(
                                    context, ref, gig.id, bids[i].id,
                                    bidderId: bids[i].bidderId)
                                : null,
                            onMessage: !isOwner
                                ? null
                                : () async {
                                    final chatId = await ref
                                        .read(chatServiceProvider)
                                        .getOrCreateChat(
                                            uid, bids[i].bidderId);
                                    if (context.mounted) {
                                      context.push(
                                          '/home/chat/$chatId/${bids[i].bidderId}/${Uri.encodeComponent(bids[i].bidderName)}');
                                    }
                                  },
                          ),
                        ),
                        childCount: bids.length,
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _showBidSheet(
      BuildContext context, GigModel gig, String uid, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => BidSheet(gig: gig, bidderId: uid),
    );
  }

  Future<void> _acceptBid(BuildContext context, WidgetRef ref,
      String gigId, String bidId,
      {required String bidderId}) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Accept Bid'),
        content: const Text(
            'Are you sure you want to accept this bid? The gig will move to "In Progress".'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Accept')),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await ref.read(firestoreServiceProvider).acceptBid(gigId, bidId);
      if (context.mounted) {
        AppHelpers.showSnackBar(context, 'Bid accepted! Gig is now in progress.');
      }
    }
  }
}

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MetaItem(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
              fontSize: 13, color: color, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;

  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _BidCard extends StatelessWidget {
  final BidModel bid;
  final bool isOwner;
  final String gigStatus;
  final VoidCallback? onAccept;
  final VoidCallback? onMessage;

  const _BidCard({
    required this.bid,
    required this.isOwner,
    required this.gigStatus,
    this.onAccept,
    this.onMessage,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = AppHelpers.getBidStatusColor(bid.status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: bid.isAccepted ? AppColors.accentGreen : AppColors.divider,
          width: bid.isAccepted ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AvatarWidget(
                imageUrl: bid.bidderAvatarUrl,
                name: bid.bidderName,
                radius: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(bid.bidderName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    if (bid.bidderRating > 0)
                      StarRatingDisplay(
                          rating: bid.bidderRating,
                          itemSize: 12,
                          showText: true),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    AppHelpers.formatCurrency(bid.amount),
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppColors.primary),
                  ),
                  Text(
                    '${bid.deliveryDays} days',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            bid.proposal,
            style: const TextStyle(
                fontSize: 13, color: AppColors.textSecondary, height: 1.5),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  bid.status.toUpperCase(),
                  style: TextStyle(
                      fontSize: 10,
                      color: statusColor,
                      fontWeight: FontWeight.w700),
                ),
              ),
              const Spacer(),
              if (onMessage != null)
                TextButton(
                    onPressed: onMessage, child: const Text('Message')),
              if (onAccept != null) ...[
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: onAccept,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    backgroundColor: AppColors.accentGreen,
                  ),
                  child: const Text('Accept'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

