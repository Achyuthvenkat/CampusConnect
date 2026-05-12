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
import 'package:campus_connect/widgets/common/skill_chip.dart';
import 'package:campus_connect/widgets/common/avatar_widget.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() =>
      _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _step1Key = GlobalKey<FormState>();
  final _step2Key = GlobalKey<FormState>();
  final _bioController = TextEditingController();
  final _deptController = TextEditingController();
  final _rateController = TextEditingController();

  int _currentStep = 0;
  int _year = 1;
  bool _isLoading = false;
  bool _availability = true;
  File? _avatarFile;
  List<File> _portfolioFiles = [];
  List<String> _selectedSkills = [];
  String _userType = 'freelancer'; // 'freelancer', 'client', 'both'

  @override
  void dispose() {
    _bioController.dispose();
    _deptController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final file = await ref.read(storageServiceProvider).pickImage();
    if (file != null) setState(() => _avatarFile = file);
  }

  Future<void> _pickPortfolio() async {
    final files = await ref
        .read(storageServiceProvider)
        .pickMultipleImages(max: AppConstants.maxPortfolioImages);
    setState(() {
      _portfolioFiles.addAll(files);
      if (_portfolioFiles.length > AppConstants.maxPortfolioImages) {
        _portfolioFiles =
            _portfolioFiles.take(AppConstants.maxPortfolioImages).toList();
      }
    });
  }

  Future<void> _complete() async {
    // Skills are on Step 2, so validate Step 2 one last time (or just check the skills list)
    if (_selectedSkills.isEmpty) {
      AppHelpers.showSnackBar(context, 'Please select at least one skill',
          isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      final uid = authService.currentUserId!;
      final storageService = ref.read(storageServiceProvider);
      final firestoreService = ref.read(firestoreServiceProvider);

      // Upload avatar
      String? avatarUrl;
      if (_avatarFile != null) {
        avatarUrl = await storageService.uploadAvatar(uid, _avatarFile!);
      }

      // Upload portfolio images
      List<String> portfolioUrls = [];
      if (_portfolioFiles.isNotEmpty) {
        portfolioUrls = await storageService.uploadPortfolioImages(
            uid, _portfolioFiles);
      }

      // Update user profile (set+merge in case the doc doesn't exist yet)
      await firestoreService.updateUser(uid, {
        'bio': _bioController.text.trim(),
        'department': _deptController.text.trim(),
        'year': _year,
        'skills': _selectedSkills,
        'hourlyRate': double.tryParse(_rateController.text) ?? 0,
        'availability': _availability,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
        'portfolioUrls': portfolioUrls,
        'userType': _userType,
        'profileComplete': true,
      });

      if (mounted) context.go('/home');
    } on Exception catch (e) {
      if (mounted) {
        AppHelpers.showSnackBar(context, 'Error: ${e.toString()}',
            isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.hub_rounded,
                            color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'CampusConnect',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Step indicator
                  Row(
                    children: List.generate(3, (i) {
                      final isActive = i == _currentStep;
                      final isDone = i < _currentStep;
                      return Expanded(
                        child: Container(
                          height: 4,
                          margin:
                              EdgeInsets.only(right: i < 2 ? 6 : 0),
                          decoration: BoxDecoration(
                            color: isActive || isDone
                                ? AppColors.primary
                                : AppColors.divider,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Step ${_currentStep + 1} of 3 — ${_stepTitle(_currentStep)}',
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),

            // Step content
            Expanded(
              child: IndexedStack(
                index: _currentStep,
                children: [
                  Form(key: _step1Key, child: _buildStep1()),
                  Form(key: _step2Key, child: _buildStep2()),
                  _buildStep3(),
                ],
              ),
            ),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      flex: 1,
                      child: CustomButton(
                        label: 'Back',
                        onPressed: () =>
                            setState(() => _currentStep--),
                        isOutlined: true,
                        width: double.infinity,
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FullWidthButton(
                      label: _currentStep == 2 ? 'Complete Setup' : 'Next',
                      isLoading: _isLoading,
                      onPressed: () {
                        if (_currentStep == 0) {
                          if (_step1Key.currentState!.validate()) {
                            setState(() => _currentStep++);
                          }
                        } else if (_currentStep == 1) {
                          if (_step2Key.currentState!.validate()) {
                            if (_selectedSkills.isEmpty) {
                              AppHelpers.showSnackBar(
                                  context, 'Please select at least one skill',
                                  isError: true);
                            } else {
                              setState(() => _currentStep++);
                            }
                          }
                        } else if (_currentStep == 2) {
                          _complete();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _stepTitle(int step) {
    switch (step) {
      case 0:
        return 'Basic Info';
      case 1:
        return 'Your Skills';
      case 2:
        return 'Portfolio';
      default:
        return '';
    }
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tell us about yourself',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          const Text(
            'This helps clients and freelancers find you.',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 28),

          // Avatar picker
          Center(
            child: GestureDetector(
              onTap: _pickAvatar,
              child: Stack(
                children: [
                  _avatarFile != null
                      ? CircleAvatar(
                          radius: 52,
                          backgroundImage: FileImage(_avatarFile!),
                        )
                      : const AvatarWidget(name: 'You', radius: 52),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt,
                          color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
          const Text('Account Type',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildTypeCard('freelancer', Icons.person_search_outlined, 'Freelancer'),
              const SizedBox(width: 8),
              _buildTypeCard('client', Icons.business_center_outlined, 'Client'),
              const SizedBox(width: 8),
              _buildTypeCard('both', Icons.people_outline, 'Both'),
            ],
          ),
          const SizedBox(height: 24),

          CustomTextField(
            label: 'Department',
            hint: 'e.g., Computer Science',
            controller: _deptController,
            validator: (v) =>
                Validators.required(v, fieldName: 'Department'),
            prefixIcon: Icons.school_outlined,
          ),

          const SizedBox(height: 16),

          // Year of study
          const Text('Year of Study',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Row(
            children: List.generate(4, (i) {
              final year = i + 1;
              final isSelected = _year == year;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _year = year),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: EdgeInsets.only(right: i < 3 ? 8 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.divider),
                    ),
                    child: Center(
                      child: Text(
                        'Year $year',
                        style: TextStyle(
                          fontSize: 13,
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
            }),
          ),

          const SizedBox(height: 16),

          CustomTextField(
            label: 'About You',
            hint: 'Briefly describe yourself and what you offer...',
            controller: _bioController,
            validator: (v) =>
                Validators.required(v, fieldName: 'Bio'),
            maxLines: 4,
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your Skills',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          const Text(
            'Select skills you can offer (max 10)',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),

          // Hourly rate
          CustomTextField(
            label: 'Hourly Rate (₹)',
            hint: 'e.g., 200',
            controller: _rateController,
            validator: Validators.hourlyRate,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            prefixIcon: Icons.currency_rupee,
          ),

          const SizedBox(height: 16),

          // Availability toggle
          Container(
            padding: const EdgeInsets.all(14),
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
                  child: Text(
                    'Available for new projects',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
                Switch(
                  value: _availability,
                  onChanged: (v) =>
                      setState(() => _availability = v),
                  activeColor: AppColors.primary,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          const Text('Select Skills',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 12),

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

          const SizedBox(height: 8),
          Text(
            '${_selectedSkills.length}/${AppConstants.maxSkillsPerUser} selected',
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Portfolio',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          const Text(
            'Add up to 6 images showcasing your work (optional)',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),

          // Portfolio grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _portfolioFiles.length + 1,
            itemBuilder: (context, index) {
              if (index == _portfolioFiles.length) {
                // Add button
                if (_portfolioFiles.length >=
                    AppConstants.maxPortfolioImages) {
                  return const SizedBox.shrink();
                }
                return GestureDetector(
                  onTap: _pickPortfolio,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.divider,
                          style: BorderStyle.solid),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined,
                            size: 28, color: AppColors.textHint),
                        SizedBox(height: 4),
                        Text('Add',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textHint)),
                      ],
                    ),
                  ),
                );
              }
              return Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _portfolioFiles[index],
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => setState(
                          () => _portfolioFiles.removeAt(index)),
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 14),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.tips_and_updates_outlined,
                    color: AppColors.primary, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'A good portfolio increases your chances of getting hired by 3x.',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildTypeCard(String type, IconData icon, String label) {
    final isSelected = _userType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _userType = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.divider),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  size: 24),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
