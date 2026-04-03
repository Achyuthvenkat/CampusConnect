import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/job_model.dart';
import '../../providers/auth_provider.dart' as app_auth;
import '../../providers/user_provider.dart';
import '../../providers/jobs_provider.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';
import '../../utils/validators.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';

class CreateJobScreen extends StatefulWidget {
  const CreateJobScreen({super.key});

  @override
  State<CreateJobScreen> createState() => _CreateJobScreenState();
}

class _CreateJobScreenState extends State<CreateJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _budgetCtrl = TextEditingController();
  String _selectedCategory = AppConstants.skillCategories[1];
  List<String> _selectedSkills = [];
  DateTime _deadline = DateTime.now().add(const Duration(days: 7));

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _budgetCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline,
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final authProvider = context.read<app_auth.AuthProvider>();
    final userProvider = context.read<UserProvider>();
    final jobsProvider = context.read<JobsProvider>();
    final user = userProvider.user;
    if (user == null) return;

    final job = JobModel(
      id: '',
      clientId: authProvider.currentUser?.uid ?? '',
      clientName: user.name,
      clientPhotoUrl: user.photoUrl,
      title: _titleCtrl.text.trim(),
      description: _descriptionCtrl.text.trim(),
      category: _selectedCategory,
      budget: double.parse(_budgetCtrl.text),
      deadline: _deadline,
      status: JobStatus.open,
      requiredSkills: _selectedSkills,
      createdAt: DateTime.now(),
    );

    final success = await jobsProvider.createJob(job);
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Job posted successfully!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final jobsProvider = context.watch<JobsProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Post a Job')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            CustomTextField(
              label: 'Job Title',
              controller: _titleCtrl,
              validator: (v) => Validators.validateRequired(v, 'Title'),
              prefixIcon: Icons.work_outline,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: AppConstants.skillCategories
                  .where((c) => c != 'All')
                  .map((cat) =>
                      DropdownMenuItem(value: cat, child: Text(cat)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedCategory = v!),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Description',
              controller: _descriptionCtrl,
              maxLines: 6,
              maxLength: 1000,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Description is required';
                if (v.length < 30) {
                  return 'Description must be at least 30 characters';
                }
                return null;
              },
              prefixIcon: Icons.description_outlined,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Budget (\$)',
              controller: _budgetCtrl,
              keyboardType: TextInputType.number,
              validator: Validators.validateBudget,
              prefixIcon: Icons.attach_money,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickDeadline,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Deadline',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  '${_deadline.day}/${_deadline.month}/${_deadline.year}',
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Required Skills',
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
            const SizedBox(height: 24),
            CustomButton(
              label: 'Post Job',
              onPressed: _submit,
              isLoading: jobsProvider.isLoading,
              width: double.infinity,
              icon: Icons.publish,
            ),
          ],
        ),
      ),
    );
  }
}
