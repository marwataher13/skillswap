import 'package:flutter/material.dart';
import 'package:skillswap/models/skill_card_data.dart';
import 'package:skillswap/models/category_model.dart';
import 'package:skillswap/services/skill_service.dart';
import 'package:skillswap/theme/app_theme.dart';
import 'package:skillswap/services/auth_service.dart';

class ManageSkillBottomSheet extends StatefulWidget {
  final SkillCardData skill;
  final List<CategoryModel> categories;
  final VoidCallback onUpdated;
  final VoidCallback onDeleted;

  const ManageSkillBottomSheet({
    super.key,
    required this.skill,
    required this.categories,
    required this.onUpdated,
    required this.onDeleted,
  });

  @override
  State<ManageSkillBottomSheet> createState() => _ManageSkillBottomSheetState();
}

class _ManageSkillBottomSheetState extends State<ManageSkillBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  final SkillService _skillService = SkillService();

  CategoryModel? _selectedCategory;
  late String _selectedType;
  late String _selectedLevel;
  bool _isSaving = false;
  bool _isDeleting = false;

  static const _types = ['teach', 'learn'];
  static const _levels = ['beginner', 'intermediate', 'advanced'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.skill.name);
    _descController = TextEditingController(text: widget.skill.description);
    _selectedType = _types.contains(widget.skill.type) ? widget.skill.type : 'teach';
    _selectedLevel = _levels.contains(widget.skill.level) ? widget.skill.level : 'beginner';
    _selectedCategory = widget.categories.where((c) => c.name == widget.skill.category).firstOrNull;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      _showSnackBar('Please select a category', isError: true);
      return;
    }

    setState(() => _isSaving = true);
    final successColor = context.appColors.success;
    final errorColor = context.appColors.error;

    try {
      await _skillService.updateSkill(
        token: (await AuthService.getToken()) ?? '',
        skillId: widget.skill.id,
        name: _nameController.text.trim(),
        categoryId: _selectedCategory!.id,
        type: _selectedType,
        description: _descController.text.trim(),
        level: _selectedLevel,
      );
      if (!mounted) return;
      Navigator.pop(context);
      widget.onUpdated();
      _showSnackBar('Skill updated successfully!', isError: false, successColor: successColor);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Failed to update skill. Please try again.', isError: true, errorColor: errorColor);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _confirmDelete() async {
    final c = context.appColors;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
        backgroundColor: c.surface,
        title: Text('Delete Skill', style: AppTextStyles.headlineMedium),
        content: Text(
          'Are you sure you want to delete "${widget.skill.name}"? This action cannot be undone.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: AppTextStyles.labelMedium.copyWith(color: c.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: c.error, minimumSize: const Size(90, 40)),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    _delete();
  }

  Future<void> _delete() async {
    setState(() => _isDeleting = true);
    final successColor = context.appColors.success;
    final errorColor = context.appColors.error;

    try {
      await _skillService.deleteSkill(
        token: (await AuthService.getToken()) ?? '',
        skillId: widget.skill.id,
      );
      if (!mounted) return;
      Navigator.pop(context);
      widget.onDeleted();
      _showSnackBar('Skill deleted.', isError: false, successColor: successColor);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Failed to delete skill. Please try again.', isError: true, errorColor: errorColor);
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  void _showSnackBar(String msg, {required bool isError, Color? successColor, Color? errorColor}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError
            ? (errorColor ?? context.appColors.error)
            : (successColor ?? context.appColors.success),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: c.divider, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Manage Skill', style: AppTextStyles.headlineMedium),
                        Text('Edit or remove this skill', style: AppTextStyles.bodyMedium),
                      ],
                    ),
                  ),
                  Material(
                    color: c.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                      onTap: (_isDeleting || _isSaving) ? null : _confirmDelete,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        child: _isDeleting
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(color: c.error, strokeWidth: 2),
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.delete_outline_rounded, color: c.error, size: 18),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Delete',
                                    style: AppTextStyles.labelMedium.copyWith(color: c.error, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildLabel('Skill Name', c),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'e.g. Digital Illustration',
                  prefixIcon: Icon(Icons.star_outline_rounded),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Please enter a skill name' : null,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              _buildLabel('Category', c),
              const SizedBox(height: 8),
              _buildDropdown<CategoryModel>(
                value: _selectedCategory,
                hint: 'Select category',
                icon: Icons.category_outlined,
                items: widget.categories,
                itemLabel: (cat) => cat.name,
                onChanged: (v) => setState(() => _selectedCategory = v),
                c: c,
              ),
              const SizedBox(height: 16),
              _buildLabel('Type', c),
              const SizedBox(height: 8),
              _buildDropdown<String>(
                value: _selectedType,
                hint: 'Select type',
                icon: Icons.swap_horiz_rounded,
                items: _types,
                itemLabel: (t) => t[0].toUpperCase() + t.substring(1),
                onChanged: (v) => setState(() => _selectedType = v!),
                c: c,
              ),
              const SizedBox(height: 16),
              _buildLabel('Level', c),
              const SizedBox(height: 8),
              _buildDropdown<String>(
                value: _selectedLevel,
                hint: 'Select level',
                icon: Icons.bar_chart_rounded,
                items: _levels,
                itemLabel: (l) => l[0].toUpperCase() + l.substring(1),
                onChanged: (v) => setState(() => _selectedLevel = v!),
                c: c,
              ),
              const SizedBox(height: 16),
              _buildLabel('Description (optional)', c),
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
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_isSaving || _isDeleting) ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, AppColorsExtension c) {
    return Text(
      text,
      style: AppTextStyles.labelMedium.copyWith(color: c.textPrimary, fontWeight: FontWeight.w600),
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    required String hint,
    required IconData icon,
    required List<T> items,
    required String Function(T) itemLabel,
    required void Function(T?) onChanged,
    required AppColorsExtension c,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        filled: true,
        fillColor: c.inputFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        prefixIcon: Icon(icon, color: c.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: c.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: c.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: c.primary, width: 1.5),
        ),
      ),
      hint: Text(hint, style: AppTextStyles.bodyMedium),
      dropdownColor: c.surface,
      icon: Icon(Icons.keyboard_arrow_down_rounded, color: c.textSecondary),
      items: items
          .map((item) => DropdownMenuItem<T>(
                value: item,
                child: Text(itemLabel(item), style: AppTextStyles.bodyLarge),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }
}
