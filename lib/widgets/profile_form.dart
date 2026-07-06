import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:provider/provider.dart';
import 'package:skillswap/providers/profile_provider.dart';
import '../theme/app_theme.dart';
import 'auth_widgets.dart';

/// Editable form for Name, Bio, and Phone.
/// Validates on save and commits to [ProfileProvider].
class ProfileForm extends StatefulWidget {
  const ProfileForm({super.key});

  @override
  State<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<ProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _usernameCtrl;
  late TextEditingController _bioCtrl;
  late TextEditingController _phoneCtrl;

  @override
  void initState() {
    super.initState();
    final profile = context.read<ProfileProvider>().profile;
    _nameCtrl  = TextEditingController(text: profile.name);
    _usernameCtrl = TextEditingController(text: profile.username);
    _bioCtrl   = TextEditingController(text: profile.bio);
    _phoneCtrl = TextEditingController(text: profile.phone);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _bioCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  // ── Validation helpers ─────────────────────────────────────────────────────

  String? _validateName(String? v) {
    if (v == null || v.trim().isEmpty) return 'Name is required';
    if (v.trim().length < 2) return 'Name must be at least 2 characters';
    if (v.trim().length > 60) return 'Name must be under 60 characters';
    return null;
  }

  String? _validateUsername(String? v) {
    if (v == null || v.trim().isEmpty) return 'Username is required';
    if (v.trim().length < 3) return 'Username must be at least 3 characters';
    if (v.trim().length > 30) return 'Username must be under 30 characters';
    if (!RegExp(r'^[a-zA-Z0-9_\.]+$').hasMatch(v.trim())) {
      return 'Username can only contain letters, numbers, underscores, and dots';
    }
    return null;
  }

  String? _validateBio(String? v) {
    if (v != null && v.length > 200) return 'Bio must be under 200 characters';
    return null;
  }

  String? _validatePhone(String? v) {
    if (v == null || v.trim().isEmpty) return 'Phone number is required';
    final cleaned = v.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (!RegExp(r'^\+?\d{7,15}$').hasMatch(cleaned)) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  // ── Save ───────────────────────────────────────────────────────────────────

  Future<void> _onSave() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final provider = context.read<ProfileProvider>();
    try {
      await provider.saveProfile(
        provider.profile.copyWith(
          name: _nameCtrl.text.trim(),
          username: _usernameCtrl.text.trim(),
          bio: _bioCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
        ),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profile saved successfully ✅',
              style: GoogleFonts.poppins(fontSize: 13)),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save profile: $e',
              style: GoogleFonts.poppins(fontSize: 13)),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isSaving = context.watch<ProfileProvider>().isSaving;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: AppShadows.card,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _cardTitle('Personal Info'),
            const SizedBox(height: 20),

            // ── Name ──
            const FieldLabel('Full Name'),
            const SizedBox(height: 8),
            _buildField(
              controller: _nameCtrl,
              hint: 'Your full name',
              icon: LucideIcons.user,
              validator: _validateName,
              maxLength: 60,
              action: TextInputAction.next,
            ),
            const SizedBox(height: 16),

            // ── Username ──
            const FieldLabel('Username'),
            const SizedBox(height: 8),
            _buildField(
              controller: _usernameCtrl,
              hint: 'Your username',
              icon: LucideIcons.userCheck,
              validator: _validateUsername,
              maxLength: 30,
              action: TextInputAction.next,
            ),
            const SizedBox(height: 16),

            // ── Bio ──
            const FieldLabel('Bio'),
            const SizedBox(height: 8),
            _buildField(
              controller: _bioCtrl,
              hint: 'Tell us about yourself…',
              icon: LucideIcons.alignLeft,
              validator: _validateBio,
              maxLines: 4,
              maxLength: 200,
              action: TextInputAction.next,
              showCounter: true,
            ),
            const SizedBox(height: 16),

            // ── Phone ──
            const FieldLabel('Phone Number'),
            const SizedBox(height: 8),
            _buildField(
              controller: _phoneCtrl,
              hint: '+1 555 000 0000',
              icon: LucideIcons.phone,
              validator: _validatePhone,
              keyboard: TextInputType.phone,
              action: TextInputAction.done,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d\s\+\-\(\)]')),
              ],
            ),
            const SizedBox(height: 24),

            // ── Save button ──
            isSaving
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: CircularProgressIndicator(
                          color: AppColors.primary),
                    ),
                  )
                : PrimaryButton(
                    label: 'Save Changes',
                    onPressed: _onSave,
                  ),
          ],
        ),
      ),
    );
  }

  Widget _cardTitle(String title) => Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      );

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType keyboard = TextInputType.text,
    TextInputAction action = TextInputAction.next,
    int maxLines = 1,
    int? maxLength,
    bool showCounter = false,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      textInputAction: action,
      maxLines: maxLines,
      maxLength: showCounter ? maxLength : null,
      inputFormatters: inputFormatters,
      validator: validator,
      style: GoogleFonts.poppins(
        fontSize: 14,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(
          fontSize: 14,
          color: AppColors.textSecondary.withValues(alpha: 0.6),
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        prefixIconConstraints:
            const BoxConstraints(minWidth: 48, minHeight: 48),
        filled: true,
        fillColor: AppColors.primary.withValues(alpha: 0.05),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.error, width: 1.5),
        ),
        errorStyle: GoogleFonts.poppins(
            fontSize: 11, color: AppColors.error),
        counterStyle: GoogleFonts.poppins(
            fontSize: 10, color: AppColors.textSecondary),
      ),
    );
  }
}