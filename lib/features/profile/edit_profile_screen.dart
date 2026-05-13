import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:campus_connect/app/theme/app_colors.dart';
import 'package:campus_connect/core/constants/app_constants.dart';
import 'package:campus_connect/core/services/auth_service.dart';
import 'package:campus_connect/core/services/firestore_service.dart';
import 'package:campus_connect/core/services/storage_service.dart';
import 'package:campus_connect/core/utils/helpers.dart';
import 'package:campus_connect/core/utils/validators.dart';
import 'package:campus_connect/widgets/common/custom_button.dart';
import 'package:campus_connect/widgets/common/custom_text_field.dart';
import 'package:campus_connect/widgets/common/avatar_widget.dart';
import 'package:campus_connect/widgets/common/skill_chip.dart';

final _editUserProvider =
    FutureProvider.autoDispose.family<dynamic, String>((ref, uid) {
  return ref.read(firestoreServiceProvider).getUser(uid);
});


class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() =>
      _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _deptController = TextEditingController();
  final _rateController = TextEditingController();
  final _linkController = TextEditingController();

  int _year = 1;
  bool _availability = true;
  List<String> _selectedSkills = [];
  File? _newAvatarFile;
  String? _currentAvatarUrl;
  List<String> _portfolioUrls = [];
  List<String> _externalLinks = [];
  List<File> _newPortfolioFiles = [];
  bool _isLoading = false;
  bool _initialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _deptController.dispose();
    _rateController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  void _init(dynamic user) {
    if (_initialized || user == null) return;
    _initialized = true;
    _nameController.text = user.name;
    _bioController.text = user.bio;
    _deptController.text = user.department;
    _rateController.text =
        user.hourlyRate > 0 ? user.hourlyRate.toStringAsFixed(0) : '';
    _year = user.year;
    _availability = user.availability;
    _selectedSkills = List<String>.from(user.skills);
    _currentAvatarUrl = user.avatarUrl;
    _portfolioUrls = List<String>.from(user.portfolioUrls);
    _externalLinks = List.from(user.externalLinks);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final uid = ref.read(authServiceProvider).currentUserId!;
      final storageService = ref.read(storageServiceProvider);
      final firestoreService = ref.read(firestoreServiceProvider);

      String? avatarUrl = _currentAvatarUrl;
      if (_newAvatarFile != null) {
        avatarUrl = await storageService.uploadAvatar(uid, _newAvatarFile!);
      }

      List<String> newUrls = [];
      if (_newPortfolioFiles.isNotEmpty) {
        newUrls =
            await storageService.uploadPortfolioImages(uid, _newPortfolioFiles);
      }
      final allPortfolioUrls = [..._portfolioUrls, ...newUrls];

      // Auto-add pending link if exists
      final pendingLink = _linkController.text.trim();
      if (pendingLink.isNotEmpty && !_externalLinks.contains(pendingLink)) {
        _externalLinks.add(pendingLink);
      }

      await firestoreService.updateUser(uid, {
        'name': _nameController.text.trim(),
        'bio': _bioController.text.trim(),
        'department': _deptController.text.trim(),
        'year': _year,
        'skills': _selectedSkills,
        'hourlyRate': double.tryParse(_rateController.text) ?? 0,
        'availability': _availability,
        'avatarUrl': avatarUrl,
        'portfolioUrls': allPortfolioUrls,
        'externalLinks': _externalLinks,
      });

      if (mounted) {
        AppHelpers.showSnackBar(context, 'Profile updated!');
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
    final uid = ref.watch(authServiceProvider).currentUserId ?? '';
    final userAsync = ref.watch(_editUserProvider(uid));

    userAsync.whenData((user) => _init(user));

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CustomButton(
              label: 'Save',
              onPressed: _save,
              isLoading: _isLoading,
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Avatar
            Center(
              child: GestureDetector(
                onTap: () async {
                  final file =
                      await ref.read(storageServiceProvider).pickImage();
                  if (file != null) {
                    setState(() => _newAvatarFile = file);
                  }
                },
                child: Stack(
                  children: [
                    _newAvatarFile != null
                        ? CircleAvatar(
                            radius: 48,
                            backgroundImage: FileImage(_newAvatarFile!))
                        : AvatarWidget(
                            imageUrl: _currentAvatarUrl,
                            name: _nameController.text.isEmpty ? 'You' : _nameController.text,
                            radius: 48),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: const BoxDecoration(
                            color: AppColors.primary, shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt,
                            color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            CustomTextField(
              label: 'Full Name',
              controller: _nameController,
              validator: Validators.name,
              prefixIcon: Icons.person_outline,
            ),
            const SizedBox(height: 16),

            CustomTextField(
              label: 'Department',
              controller: _deptController,
              validator: (v) => Validators.required(v, fieldName: 'Department'),
              prefixIcon: Icons.school_outlined,
            ),
            const SizedBox(height: 16),

            // Year
            const Text('Year of Study',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Row(
              children: List.generate(4, (i) {
                final y = i + 1;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _year = y),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: EdgeInsets.only(right: i < 3 ? 8 : 0),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _year == y
                            ? AppColors.primary
                            : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text('Year $y',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _year == y
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            )),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),

            CustomTextField(
              label: 'About You',
              controller: _bioController,
              validator: (v) => Validators.required(v, fieldName: 'Bio'),
              maxLines: 4,
            ),
            const SizedBox(height: 16),

            CustomTextField(
              label: 'Hourly Rate (₹)',
              controller: _rateController,
              validator: Validators.hourlyRate,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              prefixIcon: Icons.currency_rupee,
            ),
            const SizedBox(height: 16),

            // Availability
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  const Icon(Icons.event_available_outlined,
                      size: 20, color: AppColors.textSecondary),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text('Available for projects',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500)),
                  ),
                  Switch(
                    value: _availability,
                    onChanged: (v) => setState(() => _availability = v),
                    activeColor: AppColors.primary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Skills
            const Text('Skills',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppConstants.popularSkills.map((skill) {
                final isSelected = _selectedSkills.contains(skill);
                return SkillChip(
                  label: skill,
                  isSelected: isSelected,
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedSkills.remove(skill);
                      } else if (_selectedSkills.length <
                          AppConstants.maxSkillsPerUser) {
                        _selectedSkills.add(skill);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            
            // External Links
            const Text('Portfolio & Social Links',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    label: 'Add Link (GitHub, Behance, etc.)',
                    controller: _linkController,
                    prefixIcon: Icons.link,
                    onChanged: (v) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _linkController.text.isEmpty
                      ? null
                      : () {
                          final link = _linkController.text.trim();
                          if (link.isNotEmpty && !_externalLinks.contains(link)) {
                            setState(() {
                              _externalLinks.add(link);
                              _linkController.clear();
                            });
                          }
                        },
                  icon: const Icon(Icons.add),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
            if (_externalLinks.isNotEmpty) ...[
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _externalLinks.length,
                itemBuilder: (context, index) {
                  final link = _externalLinks[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.link, size: 16, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            link,
                            style: const TextStyle(fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _externalLinks.removeAt(index)),
                          child: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
            const SizedBox(height: 20),

            // Portfolio
            const Text('Portfolio Images',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
              ),
              itemCount: _portfolioUrls.length +
                  _newPortfolioFiles.length +
                  1,
              itemBuilder: (_, i) {
                final totalImages =
                    _portfolioUrls.length + _newPortfolioFiles.length;
                if (i < _portfolioUrls.length) {
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(_portfolioUrls[i],
                            fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 2,
                        right: 2,
                        child: GestureDetector(
                          onTap: () => setState(
                              () => _portfolioUrls.removeAt(i)),
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle),
                            child: const Icon(Icons.close,
                                color: Colors.white, size: 12),
                          ),
                        ),
                      ),
                    ],
                  );
                }
                final fileIndex = i - _portfolioUrls.length;
                if (fileIndex < _newPortfolioFiles.length) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(_newPortfolioFiles[fileIndex],
                        fit: BoxFit.cover),
                  );
                }
                if (totalImages >= AppConstants.maxPortfolioImages) {
                  return const SizedBox.shrink();
                }
                return GestureDetector(
                  onTap: () async {
                    final files = await ref
                        .read(storageServiceProvider)
                        .pickMultipleImages(max: AppConstants.maxPortfolioImages - totalImages);
                    setState(() => _newPortfolioFiles.addAll(files));
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: const Icon(Icons.add_photo_alternate_outlined,
                        color: AppColors.textHint),
                  ),
                );
              },
            ),

            const SizedBox(height: 32),
            FullWidthButton(
                label: 'Save Changes', onPressed: _save, isLoading: _isLoading),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
