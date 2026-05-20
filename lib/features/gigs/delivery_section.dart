import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_connect/app/theme/app_colors.dart';
import 'package:campus_connect/core/models/gig_model.dart';
import 'package:campus_connect/core/services/firestore_service.dart';
import 'package:campus_connect/widgets/common/custom_button.dart';
import 'package:campus_connect/core/utils/helpers.dart';
import 'package:url_launcher/url_launcher.dart';

class DeliverySection extends ConsumerWidget {
  final GigModel gig;
  final bool isOwner;
  final bool isWinner;

  const DeliverySection({
    super.key,
    required this.gig,
    required this.isOwner,
    required this.isWinner,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (gig.isOpen) return const SliverToBoxAdapter(child: SizedBox.shrink());
    if (!isOwner && !isWinner) return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _getBackgroundColor(),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _getBorderColor()),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_getIcon(), color: _getBorderColor()),
                  const SizedBox(width: 8),
                  Text(
                    _getTitle(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Revision Notes
              if (gig.isRevisionRequested && gig.revisionNotes != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Client Feedback:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(gig.revisionNotes!, style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Delivery Content
              if (gig.deliveryMessage != null && (gig.isInReview || gig.isCompleted)) ...[
                const Text('Delivery Message:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text(gig.deliveryMessage!, style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 12),
              ],

              if (gig.deliveryUrls.isNotEmpty && (gig.isInReview || gig.isCompleted)) ...[
                const Text('Deliverables:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: gig.deliveryUrls.map((url) => ActionChip(
                    label: const Text('Open Link', style: TextStyle(fontSize: 12)),
                    avatar: const Icon(Icons.link, size: 16),
                    onPressed: () => _launchUrl(url),
                  )).toList(),
                ),
                const SizedBox(height: 12),
              ],

              // Actions
              if (isWinner && (gig.isInProgress || gig.isRevisionRequested))
                CustomButton(
                  label: 'Deliver Work',
                  onPressed: () => _showDeliverySheet(context, ref),
                ),
              
              if (isOwner && gig.isInReview)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _showRevisionSheet(context, ref),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                        ),
                        child: const Text('Request Revision'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _approveDelivery(context, ref),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentGreen),
                        child: const Text('Approve & Close'),
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

  Color _getBackgroundColor() {
    if (gig.isCompleted) return AppColors.accentGreen.withOpacity(0.05);
    if (gig.isInReview) return AppColors.primary.withOpacity(0.05);
    if (gig.isRevisionRequested) return AppColors.error.withOpacity(0.05);
    return Colors.amber.withOpacity(0.05);
  }

  Color _getBorderColor() {
    if (gig.isCompleted) return AppColors.accentGreen;
    if (gig.isInReview) return AppColors.primary;
    if (gig.isRevisionRequested) return AppColors.error;
    return Colors.amber;
  }

  IconData _getIcon() {
    if (gig.isCompleted) return Icons.check_circle;
    if (gig.isInReview) return Icons.rate_review;
    if (gig.isRevisionRequested) return Icons.error_outline;
    return Icons.rocket_launch;
  }

  String _getTitle() {
    if (gig.isCompleted) return 'Gig Completed';
    if (isOwner) {
      if (gig.isInProgress) return 'Work in Progress';
      if (gig.isInReview) return 'Review Delivery';
      if (gig.isRevisionRequested) return 'Waiting for Revision';
    } else {
      if (gig.isInProgress) return 'Deliver Your Work';
      if (gig.isInReview) return 'Waiting for Client Approval';
      if (gig.isRevisionRequested) return 'Revision Requested';
    }
    return 'Status';
  }

  void _showDeliverySheet(BuildContext context, WidgetRef ref) {
    final messageCtrl = TextEditingController();
    final urlCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          left: 20, right: 20, top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Submit Delivery', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: messageCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Describe your delivery...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlCtrl,
              decoration: const InputDecoration(
                hintText: 'Link to files (Google Drive, GitHub, etc.)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              ),
            ),
            const SizedBox(height: 24),
            CustomButton(
              label: 'Submit Delivery',
              onPressed: () async {
                if (messageCtrl.text.isEmpty && urlCtrl.text.isEmpty) {
                  AppHelpers.showSnackBar(context, 'Please provide a message or a link.');
                  return;
                }
                Navigator.pop(sheetContext);
                await ref.read(firestoreServiceProvider).submitDelivery(
                  gig.id,
                  messageCtrl.text,
                  urlCtrl.text.isNotEmpty ? [urlCtrl.text] : [],
                );
                if (context.mounted) AppHelpers.showSnackBar(context, 'Delivery submitted successfully!');
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showRevisionSheet(BuildContext context, WidgetRef ref) {
    final notesCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          left: 20, right: 20, top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Request Revision', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: notesCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Explain what needs to be changed...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                if (notesCtrl.text.isEmpty) {
                  AppHelpers.showSnackBar(context, 'Please provide revision notes.');
                  return;
                }
                Navigator.pop(sheetContext);
                await ref.read(firestoreServiceProvider).requestRevision(gig.id, notesCtrl.text);
                if (context.mounted) AppHelpers.showSnackBar(context, 'Revision requested.');
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: AppColors.error,
              ),
              child: const Text('Send Revision Request'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _approveDelivery(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Approve Delivery'),
        content: const Text('Are you sure you want to approve this delivery? This will close the contract. Payments should be settled off-platform.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentGreen),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await ref.read(firestoreServiceProvider).updateGigStatus(gig.id, 'completed');
      if (context.mounted) AppHelpers.showSnackBar(context, 'Gig completed successfully!');
    }
  }

  Future<void> _launchUrl(String urlString) async {
    String formattedUrl = urlString;
    if (!urlString.startsWith('http://') && !urlString.startsWith('https://')) {
      formattedUrl = 'https://$urlString';
    }
    final uri = Uri.parse(formattedUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
