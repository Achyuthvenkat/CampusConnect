import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart' as app_auth;
import '../../providers/user_provider.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';
import '../../utils/validators.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _bioCtrl;
  late TextEditingController _collegeCtrl;
  late TextEditingController _rateCtrl;
  List<String> _selectedSkills = [];
  String? _selectedAvailability;
  bool _isAvailable = true;
  File? _selectedImage;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final user = context.read<UserProvider>().user;
      _nameCtrl = TextEditingController(text: user?.name ?? '');
      _bioCtrl = TextEditingController(text: user?.bio ?? '');
      _collegeCtrl = TextEditingController(text: user?.college ?? '');
      _rateCtrl = TextEditingController(
          text: user?.hourlyRate != null && user!.hourlyRate > 0
              ? user.hourlyRate.toStringAsFixed(2)
              : '');
      _selectedSkills = List<String>.from(user?.skills ?? []);
      _selectedAvailability = user?.availability;
      _isAvailable = user?.isAvailable ?? true;
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _collegeCtrl.dispose();
    _rateCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image != null) {
      setState(() => _selectedImage = File(image.path));
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    final authProvider = context.read<app_auth.AuthProvider>();
    final userProvider = context.read<UserProvider>();
    final uid = authProvider.currentUser?.uid ?? '';

    if (_selectedImage != null) {
      await userProvider.uploadProfilePhoto(uid, _selectedImage!);
    }

    final success = await userProvider.updateProfile(
      uid: uid,
      name: _nameCtrl.text.trim(),
      bio: _bioCtrl.text.trim(),
      college: _collegeCtrl.text.trim(),
      skills: _selectedSkills,
      availability: _selectedAvailability,
      hourlyRate: _rateCtrl.text.isNotEmpty
          ? double.tryParse(_rateCtrl.text) ?? 0
          : 0,
      isAvailable: _isAvailable,
    );

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 52,
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                      backgroundImage: _selectedImage != null
                          ? FileImage(_selectedImage!) as ImageProvider
                          : userProvider.user?.photoUrl != null
                              ? NetworkImage(userProvider.user!.photoUrl!)
                              : null,
                      child: (_selectedImage == null &&
                              userProvider.user?.photoUrl == null)
                          ? const Icon(Icons.person,
                              size: 52, color: AppTheme.primaryColor)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt,
                            size: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            CustomTextField(
              label: 'Full Name',
              controller: _nameCtrl,
              validator: Validators.validateName,
              prefixIcon: Icons.person_outline,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'College',
              controller: _collegeCtrl,
              validator: (v) => Validators.validateRequired(v, 'College'),
              prefixIcon: Icons.school_outlined,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Bio',
              controller: _bioCtrl,
              maxLines: 4,
              maxLength: 300,
              prefixIcon: Icons.info_outline,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Hourly Rate (\$)',
              controller: _rateCtrl,
              keyboardType: TextInputType.number,
              prefixIcon: Icons.attach_money,
            ),
            const SizedBox(height: 20),
            const Text(
              'Skills',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppConstants.skillCategories
                  .where((s) => s != 'All')
                  .map((skill) {
                final selected = _selectedSkills.contains(skill);
                return FilterChip(
                  label: Text(skill),
                  selected: selected,
                  onSelected: (_) {
                    setState(() {
                      if (selected) {
                        _selectedSkills.remove(skill);
                      } else {
                        _selectedSkills.add(skill);
                      }
                    });
                  },
                  selectedColor: AppTheme.primaryColor.withOpacity(0.15),
                  checkmarkColor: AppTheme.primaryColor,
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _selectedAvailability,
              decoration: const InputDecoration(
                labelText: 'Availability',
                prefixIcon: Icon(Icons.schedule),
              ),
              items: AppConstants.availabilityOptions.map((opt) {
                return DropdownMenuItem(value: opt, child: Text(opt));
              }).toList(),
              onChanged: (v) => setState(() => _selectedAvailability = v),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              value: _isAvailable,
              onChanged: (v) => setState(() => _isAvailable = v),
              title: const Text('Available for work'),
              activeColor: AppTheme.primaryColor,
            ),
            const SizedBox(height: 24),
            CustomButton(
              label: 'Save Changes',
              onPressed: _saveProfile,
              isLoading: userProvider.isLoading,
              width: double.infinity,
            ),
          ],
        ),
      ),
    );
  }
}
