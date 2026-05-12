import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:campus_connect/app/theme/app_colors.dart';
import 'package:campus_connect/core/constants/app_constants.dart';
import 'package:campus_connect/core/models/gig_model.dart';
import 'package:campus_connect/core/services/auth_service.dart';
import 'package:campus_connect/core/services/firestore_service.dart';
import 'package:campus_connect/core/services/storage_service.dart';
import 'package:campus_connect/core/utils/helpers.dart';
import 'package:campus_connect/core/utils/validators.dart';
import 'package:campus_connect/widgets/common/custom_button.dart';
import 'package:campus_connect/widgets/common/custom_text_field.dart';
import 'package:campus_connect/widgets/common/skill_chip.dart';
import 'package:intl/intl.dart';

class CreateGigScreen extends ConsumerStatefulWidget {
  const CreateGigScreen({super.key});

  @override
  ConsumerState<CreateGigScreen> createState() => _CreateGigScreenState();
}

class _CreateGigScreenState extends ConsumerState<CreateGigScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _budgetController = TextEditingController();
  final _tagController = TextEditingController();

  String _selectedCategory = AppConstants.gigCategories[1];
  DateTime _deadline = DateTime.now().add(const Duration(days: 7));
  List<String> _tags = [];
  List<File> _attachments = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _budgetController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline,
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 180)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme:
              const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  Future<void> _pickAttachments() async {
    final files = await ref
        .read(storageServiceProvider)
        .pickMultipleImages(max: AppConstants.maxGigAttachments);
    setState(() {
      _attachments.addAll(files);
      if (_attachments.length > AppConstants.maxGigAttachments) {
        _attachments = _attachments.take(AppConstants.maxGigAttachments).toList();
      }
    });
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag) && _tags.length < 5) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  Future<void> _submitGig() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      final uid = authService.currentUserId!;
      final firestoreService = ref.read(firestoreServiceProvider);
      final storageService = ref.read(storageServiceProvider);

      // Get user info
      final user = await firestoreService.getUser(uid);

      // Upload attachments if any
      List<String> attachmentUrls = [];
      if (_attachments.isNotEmpty) {
        final tempGigId =
            DateTime.now().millisecondsSinceEpoch.toString();
        final futures = _attachments
            .map((f) => storageService.uploadGigAttachment(tempGigId, f));
        attachmentUrls = await Future.wait(futures);
      }

      final gig = GigModel(
        id: '',
        clientId: uid,
        clientName: user?.name ?? 'Anonymous',
        clientAvatarUrl: user?.avatarUrl,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        category: _selectedCategory,
        budget: double.parse(_budgetController.text.trim()),
        deadline: _deadline,
        attachmentUrls: attachmentUrls,
        tags: _tags,
        createdAt: DateTime.now(),
      );

      await firestoreService.createGig(gig);

      if (mounted) {
        AppHelpers.showSnackBar(context, 'Gig posted successfully!');
        context.pop();
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
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('Post a Gig'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CustomButton(
              label: 'Post',
              onPressed: _submitGig,
              isLoading: _isLoading,
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title
            CustomTextField(
              label: 'Gig Title',
              hint: 'e.g., Need a logo for my startup',
              controller: _titleController,
              validator: (v) => Validators.required(v, fieldName: 'Title'),
              maxLength: 100,
            ),
            const SizedBox(height: 16),

            // Category
            _buildSectionLabel('Category'),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children:
                    AppConstants.gigCategories.skip(1).map((cat) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: CategoryChip(
                      label: cat,
                      isSelected: cat == _selectedCategory,
                      onTap: () =>
                          setState(() => _selectedCategory = cat),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Description
            CustomTextField(
              label: 'Description',
              hint:
                  'Describe what you need in detail. Include requirements, deliverables, and any specific instructions...',
              controller: _descController,
              validator: (v) =>
                  Validators.required(v, fieldName: 'Description'),
              maxLines: 5,
            ),
            const SizedBox(height: 16),

            // Budget & Deadline
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    label: 'Budget (₹)',
                    hint: 'e.g., 5000',
                    controller: _budgetController,
                    validator: Validators.budget,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    prefixIcon: Icons.currency_rupee,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: _pickDeadline,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Deadline',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_outlined,
                                  size: 16,
                                  color: AppColors.textSecondary),
                              const SizedBox(width: 6),
                              Text(
                                DateFormat('MMM d, y').format(_deadline),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Tags
            _buildSectionLabel('Tags (optional, max 5)'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tagController,
                    decoration: const InputDecoration(
                      hintText: 'Add a tag (e.g., urgent)',
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                    onSubmitted: (_) => _addTag(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addTag,
                  child: const Text('Add'),
                ),
              ],
            ),
            if (_tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: _tags
                    .map((tag) => SkillChip(
                          label: tag,
                          isSelected: true,
                          onDeleted: () =>
                              setState(() => _tags.remove(tag)),
                        ))
                    .toList(),
              ),
            ],
            const SizedBox(height: 16),

            // Attachments
            _buildSectionLabel(
                'Attachments (optional, max ${AppConstants.maxGigAttachments})'),
            const SizedBox(height: 8),
            if (_attachments.isNotEmpty) ...[
              SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _attachments.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _attachments[i],
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 2,
                        right: 2,
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _attachments.removeAt(i)),
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close,
                                color: Colors.white, size: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (_attachments.length < AppConstants.maxGigAttachments)
              OutlinedButton.icon(
                onPressed: _pickAttachments,
                icon: const Icon(Icons.attach_file),
                label: const Text('Attach Images'),
              ),

            const SizedBox(height: 32),

            FullWidthButton(
              label: 'Post Gig',
              onPressed: _submitGig,
              isLoading: _isLoading,
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }
}
