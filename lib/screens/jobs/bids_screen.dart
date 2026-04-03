import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/job_model.dart';
import '../../models/bid_model.dart';
import '../../providers/jobs_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart' as app_auth;
import '../../utils/theme.dart';
import '../../utils/helpers.dart';
import '../chat/chat_screen.dart';
import '../profile/profile_screen.dart';

class BidsScreen extends StatelessWidget {
  final JobModel job;

  const BidsScreen({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    final jobsProvider = context.read<JobsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Bids for "${job.title}"'),
      ),
      body: StreamBuilder<List<BidModel>>(
        stream: jobsProvider.getJobBids(job.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final bids = snapshot.data ?? [];
          if (bids.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined,
                      size: 64, color: AppTheme.textSecondary),
                  SizedBox(height: 16),
                  Text(
                    'No bids yet',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bids.length,
            itemBuilder: (_, i) => _BidCard(
              bid: bids[i],
              job: job,
            ),
          );
        },
      ),
    );
  }
}

class _BidCard extends StatelessWidget {
  final BidModel bid;
  final JobModel job;

  const _BidCard({required this.bid, required this.job});

  @override
  Widget build(BuildContext context) {
    final isPending = bid.status == BidStatus.pending;
    final isOwner = job.clientId ==
        context.read<app_auth.AuthProvider>().currentUser?.uid;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _avatar(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ProfileScreen(userId: bid.freelancerId),
                          ),
                        ),
                        child: Text(
                          bid.freelancerName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star,
                              size: 13, color: Colors.amber),
                          const SizedBox(width: 3),
                          Text(
                            bid.freelancerRating.toStringAsFixed(1),
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _statusChip(),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.attach_money,
                    size: 16, color: AppTheme.successColor),
                Text(
                  Helpers.formatCurrency(bid.amount),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.successColor,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.schedule,
                    size: 16, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text(
                  '${bid.deliveryDays} days',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                Text(
                  Helpers.timeAgo(bid.createdAt),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              bid.proposal,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            if (isOwner && isPending) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _messageFreelancer(context),
                      icon: const Icon(Icons.message_outlined, size: 16),
                      label: const Text('Message'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _rejectBid(context),
                      style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.errorColor,
                          side: const BorderSide(
                              color: AppTheme.errorColor)),
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _acceptBid(context),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.successColor),
                      child: const Text('Accept'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _avatar() {
    if (bid.freelancerPhotoUrl != null) {
      return CircleAvatar(
        radius: 22,
        backgroundImage:
            CachedNetworkImageProvider(bid.freelancerPhotoUrl!),
      );
    }
    return CircleAvatar(
      radius: 22,
      backgroundColor: AppTheme.primaryColor,
      child: Text(
        bid.freelancerName.isNotEmpty
            ? bid.freelancerName[0].toUpperCase()
            : '?',
        style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _statusChip() {
    Color color;
    switch (bid.status) {
      case BidStatus.pending:
        color = Colors.orange;
        break;
      case BidStatus.accepted:
        color = AppTheme.successColor;
        break;
      case BidStatus.rejected:
        color = AppTheme.errorColor;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        bid.status.name,
        style: TextStyle(
            color: color, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }

  Future<void> _acceptBid(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Accept Bid'),
        content: Text(
            'Accept bid from ${bid.freelancerName} for ${Helpers.formatCurrency(bid.amount)}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Accept')),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      await context
          .read<JobsProvider>()
          .acceptBid(bid.id, bid.jobId, bid.freelancerId);
      if (context.mounted) Navigator.pop(context);
    }
  }

  Future<void> _rejectBid(BuildContext context) async {
    await context.read<JobsProvider>().rejectBid(bid.id);
  }

  Future<void> _messageFreelancer(BuildContext context) async {
    final chatProvider = context.read<ChatProvider>();
    final userProvider = context.read<UserProvider>();
    final currentUser = userProvider.user;
    if (currentUser == null) return;

    final room = await chatProvider.getOrCreateChatRoom(
      currentUserId: currentUser.uid,
      currentUserName: currentUser.name,
      currentUserPhoto: currentUser.photoUrl,
      otherUserId: bid.freelancerId,
      otherUserName: bid.freelancerName,
      otherUserPhoto: bid.freelancerPhotoUrl,
    );
    if (room != null && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ChatScreen(chatRoom: room)),
      );
    }
  }
}
