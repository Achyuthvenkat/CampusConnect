import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/job_model.dart';
import '../../models/bid_model.dart';
import '../../providers/auth_provider.dart' as app_auth;
import '../../providers/user_provider.dart';
import '../../providers/jobs_provider.dart';
import '../../providers/chat_provider.dart';
import '../../utils/theme.dart';
import '../../utils/helpers.dart';
import '../chat/chat_screen.dart';
import 'bids_screen.dart';

class JobDetailScreen extends StatelessWidget {
  final String jobId;
  final JobModel job;

  const JobDetailScreen({super.key, required this.jobId, required this.job});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<app_auth.AuthProvider>();
    final currentUserId = authProvider.currentUser?.uid ?? '';
    final isOwner = job.clientId == currentUserId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Details'),
        actions: [
          if (isOwner)
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BidsScreen(job: job),
                ),
              ),
              child: Text(
                'Bids (${job.bidCount})',
                style: const TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _clientAvatar(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.clientName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        Helpers.timeAgo(job.createdAt),
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                _statusBadge(),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              job.title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                job.category,
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _infoCard(
                  Icons.attach_money,
                  Helpers.formatCurrency(job.budget),
                  'Budget',
                  AppTheme.successColor,
                ),
                const SizedBox(width: 12),
                _infoCard(
                  Icons.calendar_today,
                  Helpers.formatDate(job.deadline),
                  'Deadline',
                  AppTheme.primaryColor,
                ),
                const SizedBox(width: 12),
                _infoCard(
                  Icons.people_outline,
                  '${job.bidCount}',
                  'Bids',
                  Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Description',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              job.description,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                height: 1.6,
              ),
            ),
            if (job.requiredSkills.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text(
                'Required Skills',
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
                children: job.requiredSkills.map((skill) {
                  return Chip(
                    label: Text(skill),
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    side: BorderSide.none,
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 32),
            if (!isOwner && job.status == JobStatus.open)
              _PlaceBidSection(job: job),
            if (!isOwner && job.status != JobStatus.open)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'This job is no longer accepting bids.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ),
            if (isOwner && job.status == JobStatus.inProgress) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Mark as Complete?'),
                      content: const Text(
                          'Confirm that this job has been completed.'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel')),
                        ElevatedButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Confirm')),
                      ],
                    ),
                  );
                  if (confirm == true && context.mounted) {
                    await context
                        .read<JobsProvider>()
                        .completeJob(job.id);
                    if (context.mounted) Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.successColor,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Mark as Complete'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _clientAvatar() {
    if (job.clientPhotoUrl != null) {
      return CircleAvatar(
        radius: 22,
        backgroundImage: CachedNetworkImageProvider(job.clientPhotoUrl!),
      );
    }
    return CircleAvatar(
      radius: 22,
      backgroundColor: AppTheme.primaryColor,
      child: Text(
        Helpers.getInitials(job.clientName),
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _statusBadge() {
    final label = job.status.name;
    Color color;
    switch (job.status) {
      case JobStatus.open:
        color = AppTheme.successColor;
        break;
      case JobStatus.inProgress:
        color = Colors.orange;
        break;
      case JobStatus.completed:
        color = AppTheme.primaryColor;
        break;
      case JobStatus.cancelled:
        color = AppTheme.errorColor;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label[0].toUpperCase() + label.substring(1),
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _infoCard(
      IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceBidSection extends StatefulWidget {
  final JobModel job;
  const _PlaceBidSection({required this.job});

  @override
  State<_PlaceBidSection> createState() => _PlaceBidSectionState();
}

class _PlaceBidSectionState extends State<_PlaceBidSection> {
  bool _expanded = false;
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _proposalCtrl = TextEditingController();
  final _daysCtrl = TextEditingController();

  @override
  void dispose() {
    _amountCtrl.dispose();
    _proposalCtrl.dispose();
    _daysCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitBid() async {
    if (!_formKey.currentState!.validate()) return;
    final authProvider = context.read<app_auth.AuthProvider>();
    final userProvider = context.read<UserProvider>();
    final jobsProvider = context.read<JobsProvider>();
    final user = userProvider.user;
    if (user == null) return;

    final bid = BidModel(
      id: '',
      jobId: widget.job.id,
      freelancerId: authProvider.currentUser?.uid ?? '',
      freelancerName: user.name,
      freelancerPhotoUrl: user.photoUrl,
      amount: double.parse(_amountCtrl.text),
      proposal: _proposalCtrl.text.trim(),
      deliveryDays: int.parse(_daysCtrl.text),
      status: BidStatus.pending,
      createdAt: DateTime.now(),
      freelancerRating: user.rating,
    );

    final success = await jobsProvider.submitBid(bid);
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bid submitted successfully!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      setState(() => _expanded = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_expanded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            onPressed: () => setState(() => _expanded = true),
            icon: const Icon(Icons.gavel),
            label: const Text('Place a Bid'),
            style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50)),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () async {
              final chatProvider = context.read<ChatProvider>();
              final userProvider = context.read<UserProvider>();
              final currentUser = userProvider.user;
              if (currentUser == null) return;

              final room = await chatProvider.getOrCreateChatRoom(
                currentUserId: currentUser.uid,
                currentUserName: currentUser.name,
                currentUserPhoto: currentUser.photoUrl,
                otherUserId: widget.job.clientId,
                otherUserName: widget.job.clientName,
                otherUserPhoto: widget.job.clientPhotoUrl,
              );
              if (room != null && context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(chatRoom: room),
                  ),
                );
              }
            },
            icon: const Icon(Icons.message_outlined),
            label: const Text('Message Client'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              side: const BorderSide(color: AppTheme.primaryColor),
            ),
          ),
        ],
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Submit Your Bid',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Your Bid Amount (\$)',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Amount required';
                  final amount = double.tryParse(v);
                  if (amount == null || amount < 5) {
                    return 'Minimum bid is \$5';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _daysCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Delivery Days',
                  prefixIcon: Icon(Icons.schedule),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Delivery days required';
                  final days = int.tryParse(v);
                  if (days == null || days < 1) return 'Must be at least 1 day';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _proposalCtrl,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Proposal',
                  hintText: 'Explain why you\'re the best fit for this job...',
                  alignLabelWithHint: true,
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Proposal required';
                  if (v.length < 20) {
                    return 'Proposal must be at least 20 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _expanded = false),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Consumer<JobsProvider>(
                      builder: (_, prov, __) => ElevatedButton(
                        onPressed: prov.isLoading ? null : _submitBid,
                        child: prov.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Submit Bid'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
