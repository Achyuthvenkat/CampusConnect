import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart' as app_auth;
import '../../providers/user_provider.dart';
import '../../providers/jobs_provider.dart';
import '../../models/job_model.dart';
import '../../models/bid_model.dart';
import '../../utils/theme.dart';
import '../../utils/helpers.dart';
import '../jobs/job_detail_screen.dart';
import '../jobs/create_job_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final jobsProvider = context.watch<JobsProvider>();
    final user = userProvider.user;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Dashboard'),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'My Posted Jobs'),
              Tab(text: 'My Bids'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _PostedJobsTab(jobs: jobsProvider.myPostedJobs),
            _MyBidsTab(bids: jobsProvider.myBids),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateJobScreen()),
          ),
          icon: const Icon(Icons.add),
          label: const Text('Post Job'),
          backgroundColor: AppTheme.primaryColor,
        ),
      ),
    );
  }
}

class _PostedJobsTab extends StatelessWidget {
  final List<JobModel> jobs;
  const _PostedJobsTab({required this.jobs});

  @override
  Widget build(BuildContext context) {
    if (jobs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.work_off_outlined,
                size: 64, color: AppTheme.textSecondary),
            const SizedBox(height: 16),
            const Text(
              'No jobs posted yet',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateJobScreen()),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Post Your First Job'),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: jobs.length,
      itemBuilder: (_, i) => _JobStatusCard(job: jobs[i]),
    );
  }
}

class _JobStatusCard extends StatelessWidget {
  final JobModel job;
  const _JobStatusCard({required this.job});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    switch (job.status) {
      case JobStatus.open:
        statusColor = AppTheme.successColor;
        break;
      case JobStatus.inProgress:
        statusColor = Colors.orange;
        break;
      case JobStatus.completed:
        statusColor = AppTheme.primaryColor;
        break;
      case JobStatus.cancelled:
        statusColor = AppTheme.errorColor;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => JobDetailScreen(jobId: job.id, job: job),
          ),
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      job.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      job.status.name,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.attach_money,
                      size: 16, color: AppTheme.successColor),
                  Text(
                    Helpers.formatCurrency(job.budget),
                    style: const TextStyle(
                      color: AppTheme.successColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.people_outline,
                      size: 16, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    '${job.bidCount} bids',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    Helpers.formatDate(job.deadline),
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
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

class _MyBidsTab extends StatelessWidget {
  final List<BidModel> bids;
  const _MyBidsTab({required this.bids});

  @override
  Widget build(BuildContext context) {
    if (bids.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.gavel, size: 64, color: AppTheme.textSecondary),
            SizedBox(height: 16),
            Text(
              'No bids placed yet',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bids.length,
      itemBuilder: (_, i) => _BidStatusCard(bid: bids[i]),
    );
  }
}

class _BidStatusCard extends StatelessWidget {
  final BidModel bid;
  const _BidStatusCard({required this.bid});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    switch (bid.status) {
      case BidStatus.pending:
        statusColor = Colors.orange;
        break;
      case BidStatus.accepted:
        statusColor = AppTheme.successColor;
        break;
      case BidStatus.rejected:
        statusColor = AppTheme.errorColor;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Bid #${bid.id.substring(0, 6)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    bid.status.name,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.attach_money,
                    size: 16, color: AppTheme.successColor),
                Text(
                  Helpers.formatCurrency(bid.amount),
                  style: const TextStyle(
                    color: AppTheme.successColor,
                    fontWeight: FontWeight.w600,
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
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            if (bid.status == BidStatus.accepted) ...[
              const SizedBox(height: 8),
              const Row(
                children: [
                  Icon(Icons.check_circle,
                      size: 16, color: AppTheme.successColor),
                  SizedBox(width: 4),
                  Text(
                    'Your bid was accepted! Get to work.',
                    style: TextStyle(
                      color: AppTheme.successColor,
                      fontSize: 13,
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
}
