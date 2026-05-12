import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_connect/app/theme/app_colors.dart';
import 'package:campus_connect/core/models/gig_model.dart';
import 'package:campus_connect/core/models/bid_model.dart';
import 'package:campus_connect/core/models/user_model.dart';
import 'package:campus_connect/core/services/auth_service.dart';
import 'package:campus_connect/core/services/firestore_service.dart';
import 'package:campus_connect/core/utils/helpers.dart';
import 'package:campus_connect/core/utils/validators.dart';
import 'package:campus_connect/widgets/common/custom_text_field.dart';

class BidSheet extends ConsumerStatefulWidget {
  final GigModel gig;
  final String bidderId;

  const BidSheet({super.key, required this.gig, required this.bidderId});

  @override
  ConsumerState<BidSheet> createState() => _BidSheetState();
}

class _BidSheetState extends ConsumerState<BidSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _proposalController = TextEditingController();
  final _daysController = TextEditingController(text: '7');
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _proposalController.dispose();
    _daysController.dispose();
    super.dispose();
  }

  Future<void> _submitBid() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      final user = await firestoreService.getUser(widget.bidderId);

      final bid = BidModel(
        id: '',
        gigId: widget.gig.id,
        bidderId: widget.bidderId,
        bidderName: user?.name ?? 'Anonymous',
        bidderAvatarUrl: user?.avatarUrl,
        bidderRating: user?.rating ?? 0,
        amount: double.parse(_amountController.text.trim()),
        proposal: _proposalController.text.trim(),
        deliveryDays: int.parse(_daysController.text.trim()),
        createdAt: DateTime.now(),
      );

      await firestoreService.createBid(bid);

      if (mounted) {
        Navigator.pop(context);
        AppHelpers.showSnackBar(context, 'Bid submitted successfully!');
      }
    } on Exception catch (e) {
      if (mounted) {
        AppHelpers.showSnackBar(context, 'Error: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Place a Bid',
                          style: Theme.of(context).textTheme.headlineSmall),
                      Text(
                        'Budget: ${AppHelpers.formatCurrency(widget.gig.budget)}',
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Amount & Days
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: 'Your Bid (₹)',
                      hint: 'Amount',
                      controller: _amountController,
                      validator: (v) =>
                          Validators.bidAmount(v, widget.gig.budget),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      prefixIcon: Icons.currency_rupee,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      label: 'Deliver in (days)',
                      hint: 'e.g., 7',
                      controller: _daysController,
                      validator: Validators.deliveryDays,
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.timer_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Proposal
              CustomTextField(
                label: 'Your Proposal',
                hint:
                    'Explain why you are the best fit for this gig. Mention relevant experience and how you plan to approach it...',
                controller: _proposalController,
                validator: (v) =>
                    Validators.required(v, fieldName: 'Proposal'),
                maxLines: 4,
                textInputAction: TextInputAction.newline,
                keyboardType: TextInputType.multiline,
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitBid,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Submit Bid',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
