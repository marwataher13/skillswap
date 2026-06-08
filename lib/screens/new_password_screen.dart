import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../services/password_service.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_widgets.dart';

class NewPasswordScreen extends StatefulWidget {
  const NewPasswordScreen({super.key});

  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _passwordService = PasswordService();

  bool _isLoading = false;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _showNewPasswordError = false;
  bool _showConfirmPasswordError = false;
  String _confirmErrorText = 'Confirm password is required';
  String _newPasswordErrorText = 'Password must be at least 8 characters';

  String _email = '';
  String _token = '';

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _email = args?['email'] as String? ?? '';
    _token = args?['token'] as String? ?? '';
  }

  @override
  void initState() {
    super.initState();
    _newPasswordController.addListener(() {
      if (_showNewPasswordError &&
          _newPasswordController.text.trim().length >= 8) {
        setState(() => _showNewPasswordError = false);
      }
    });
    _confirmPasswordController.addListener(() {
      if (_showConfirmPasswordError &&
          _confirmPasswordController.text.trim().isNotEmpty) {
        setState(() => _showConfirmPasswordError = false);
      }
    });
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ── Validation ─────────────────────────────────────────────────────────────

  bool _validate() {
    final newPass = _newPasswordController.text;
    final confirmPass = _confirmPasswordController.text;
    bool valid = true;

    if (newPass.isEmpty || newPass.length < 8) {
      setState(() {
        _newPasswordErrorText = newPass.isEmpty
            ? 'Password is required'
            : 'Password must be at least 8 characters';
        _showNewPasswordError = true;
      });
      valid = false;
    }

    if (confirmPass.isEmpty) {
      setState(() {
        _confirmErrorText = 'Confirm password is required';
        _showConfirmPasswordError = true;
      });
      valid = false;
    } else if (newPass != confirmPass) {
      setState(() {
        _confirmErrorText = 'Passwords do not match';
        _showConfirmPasswordError = true;
      });
      valid = false;
    }

    return valid;
  }

  // ── Submit ─────────────────────────────────────────────────────────────────

  Future<void> _onUpdatePasswordPressed() async {
    FocusScope.of(context).unfocus();
    if (!_validate()) return;

    setState(() {
      _showNewPasswordError = false;
      _showConfirmPasswordError = false;
      _isLoading = true;
    });

    final result = await _passwordService.resetPassword(
      email: _email,
      password: _newPasswordController.text,
      passwordConfirmation: _confirmPasswordController.text,
      token: _token,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.isSuccess) {
      Navigator.pushReplacementNamed(context, '/password-reset-success');
    } else {
      _showSnackBar(result.error ?? 'Failed to reset password', isError: true);
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? const Color.fromARGB(255, 205, 36, 36)
            : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(size),
            Transform.translate(
              offset: const Offset(0, -28),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildFormCard(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Size size) {
    return Container(
      width: double.infinity,
      height: size.height * 0.30,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.gradientStart, AppColors.gradientEnd],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(AppSpacing.radiusXl),
          bottomRight: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const Spacer(),
              Text(
                'New Password',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Create a strong safety boundary',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.lock,
                size: 30,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Create New Password',
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Choose a secure credentials combination to\ncomplete the flow.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── New Password ──
          const FieldLabel('New Password'),
          const SizedBox(height: 8),
          AppTextField(
            hintText: 'At least 8 characters',
            prefixIcon: LucideIcons.lock,
            controller: _newPasswordController,
            obscureText: _obscureNew,
            textInputAction: TextInputAction.next,
            suffixIcon: GestureDetector(
              onTap: () => setState(() => _obscureNew = !_obscureNew),
              child: Icon(
                _obscureNew ? LucideIcons.eye : LucideIcons.eyeOff,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          if (_showNewPasswordError) ...[
            const SizedBox(height: 6),
            Text(
              _newPasswordErrorText,
              style: GoogleFonts.poppins(fontSize: 12, color: AppColors.error),
            ),
          ],

          const SizedBox(height: 16),

          // ── Confirm Password ──
          const FieldLabel('Confirm Password'),
          const SizedBox(height: 8),
          AppTextField(
            hintText: 'Re-enter new password',
            prefixIcon: LucideIcons.lock,
            controller: _confirmPasswordController,
            obscureText: _obscureConfirm,
            textInputAction: TextInputAction.done,
            suffixIcon: GestureDetector(
              onTap: () => setState(() => _obscureConfirm = !_obscureConfirm),
              child: Icon(
                _obscureConfirm ? LucideIcons.eye : LucideIcons.eyeOff,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          if (_showConfirmPasswordError) ...[
            const SizedBox(height: 6),
            Text(
              _confirmErrorText,
              style: GoogleFonts.poppins(fontSize: 12, color: AppColors.error),
            ),
          ],

          const SizedBox(height: 28),
          _isLoading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              : PrimaryButton(
                  label: 'Update Password',
                  onPressed: _onUpdatePasswordPressed,
                ),
        ],
      ),
    );
  }
}
