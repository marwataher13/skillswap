import 'package:flutter/material.dart';
import 'package:skillswap/models/category_model.dart';
import 'package:skillswap/services/skill_service.dart';
import 'package:skillswap/theme/app_theme.dart';
import 'package:skillswap/services/auth_service.dart';

class AddSkillBottomSheet extends StatefulWidget {
  final List<CategoryModel> categories;
  final VoidCallback onSaved;

  const AddSkillBottomSheet({
    super.key,
    required this.categories,
    required this.onSaved,
  });

  @override
  State<AddSkillBottomSheet> createState() => _AddSkillBottomSheetState();
}

class _AddSkillBottomSheetState extends State<AddSkillBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final SkillService _skillService = SkillService();

  CategoryModel? _selectedCategory;
  String _selectedType = 'teach';
  String _selectedLevel = 'beginner';
  bool _isSaving = false;

  static const _types = ['teach', 'learn'];
  static const _levels = ['beginner', 'intermediate', 'advanced'];

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      _showError('Please select a category');
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _skillService.createSkill(
        token: (await AuthService.getToken()) ?? '',
        name: _nameController.text.trim(),
        categoryId: _selectedCategory!.id,
        type: _selectedType,
        description: _descController.text.trim(),
        level: _selectedLevel,
      );
      if (!mounted) return;
      Navigator.pop(context);
      widget.onSaved();
      _showSuccess('Skill added successfully!');
    } catch (e) {
      if (!mounted) return;
      _showError('Failed to add skill. Please try again.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
      ),
    );
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text('Add New Skill', style: AppTextStyles.headlineMedium),
              Text(
                'Share what you can teach or want to learn',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 24),

              // Skill Name
              _buildLabel('Skill Name'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'e.g. Digital Illustration',
                  prefixIcon: Icon(Icons.star_outline_rounded),
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Please enter a skill name'
                    : null,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              // Category
              _buildLabel('Category'),
              const SizedBox(height: 8),
              _buildDropdown<CategoryModel>(
                value: _selectedCategory,
                hint: 'Select category',
                icon: Icons.category_outlined,
                items: widget.categories,
                itemLabel: (c) => c.name,
                onChanged: (v) => setState(() => _selectedCategory = v),
              ),
              const SizedBox(height: 16),

              // Type
              _buildLabel('Type'),
              const SizedBox(height: 8),
              _buildDropdown<String>(
                value: _selectedType,
                hint: 'Select type',
                icon: Icons.swap_horiz_rounded,
                items: _types,
                itemLabel: (t) => t[0].toUpperCase() + t.substring(1),
                onChanged: (v) => setState(() => _selectedType = v!),
              ),
              const SizedBox(height: 16),

              // Level
              _buildLabel('Level'),
              const SizedBox(height: 8),
              _buildDropdown<String>(
                value: _selectedLevel,
                hint: 'Select level',
                icon: Icons.bar_chart_rounded,
                items: _levels,
                itemLabel: (l) => l[0].toUpperCase() + l.substring(1),
                onChanged: (v) => setState(() => _selectedLevel = v!),
              ),
              const SizedBox(height: 16),

              // Description
              _buildLabel('Description (optional)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Briefly describe this skill...',
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 40),
                    child: Icon(Icons.notes_rounded),
                  ),
                ),
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 28),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Add Skill'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: AppTextStyles.labelMedium.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    required String hint,
    required IconData icon,
    required List<T> items,
    required String Function(T) itemLabel,
    required void Function(T?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonFormField<T>(
        value: value,
        isExpanded: true,
        decoration: InputDecoration(
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          prefixIcon: Icon(icon, color: AppColors.textSecondary),
        ),
        hint: Text(hint, style: AppTextStyles.bodyMedium),
        dropdownColor: AppColors.surface,
        icon: const Icon(
          Icons.keyboard_arrow_down_rounded,
          color: AppColors.textSecondary,
        ),
        items: items
            .map(
              (item) => DropdownMenuItem<T>(
                value: item,
                child: Text(itemLabel(item), style: AppTextStyles.bodyLarge),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}
