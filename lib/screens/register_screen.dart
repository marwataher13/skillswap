import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_widgets.dart';

// ─────────────────────────────────────────────
// Register Screen
// ─────────────────────────────────────────────
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _authService = AuthService();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String? _validate() {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirm = _confirmController.text.trim();

    if (kDebugMode) {
      debugPrint('name: "$name"');
      debugPrint('email: "$email"');
      debugPrint('password length: ${password.length}');
      debugPrint('confirm length: ${confirm.length}');
      debugPrint('are equal: ${password == confirm}');
    }

    if (name.isEmpty) {
      if (kDebugMode) {
        debugPrint('FAILED: name empty');
      }
      return 'Please enter your full name';
    }
    if (email.isEmpty || !email.contains('@')) {
      if (kDebugMode) {
        debugPrint('FAILED: email invalid');
      }
      return 'Please enter a valid email address';
    }
    if (password.length < 6) {
      if (kDebugMode) {
        debugPrint('FAILED: password too short');
      }
      return 'Password must be at least 6 characters';
    }
    if (password != confirm) {
      if (kDebugMode) {
        debugPrint('FAILED: passwords do not match');
      }
      return 'Passwords do not match';
    }
    if (kDebugMode) {
      debugPrint('VALIDATION PASSED');
    }
    return null;
  }

  // ── Submit ───────────────────────────────────
  Future<void> _handleRegister() async {
    FocusScope.of(context).unfocus();

    final validationError = _validate();
    if (validationError != null) {
      _showSnackBar(validationError, isError: true);
      return;
    }

    if (mounted) setState(() => _isLoading = true);

    try {
      final error = await _authService.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (error != null) {
        _showSnackBar(error, isError: true);
      } else {
        _showSnackBar('Account created successfully! 🎉', isError: false);
        Future.delayed(const Duration(seconds: 1), _navigateToLogin);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnackBar('Something went wrong: $e', isError: true);
    }
  }

  // ── Helpers ──────────────────────────────────
  void _navigateToLogin() {
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────
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
              offset: const Offset(0, -20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildFormCard(),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              child: Transform.translate(
                offset: const Offset(0, -20),
                child: _buildSocialSection(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ───────────────────────────────────
  Widget _buildHeader(Size size) {
    return Container(
      width: double.infinity,
      height: size.height * 0.26,
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
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: _navigateToLogin,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        LucideIcons.arrowLeft,
                        size: 18,
                        color: AppColors.surface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'SkillSwap',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.surface.withValues(alpha: 0.90),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Create Account',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.surface,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Join a community of learners & teachers',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: AppColors.surface.withValues(alpha: 0.70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Form Card ────────────────────────────────
  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AuthTabSwitcher(
            selectedIndex: 1,
            onTabSelected: (index) {
              if (index == 0) _navigateToLogin();
            },
          ),

          const SizedBox(height: 28),

          // Full Name
          const FieldLabel('Full Name'),
          AppTextField(
            hintText: 'Enter your full name',
            prefixIcon: LucideIcons.user,
            controller: _nameController,
            keyboardType: TextInputType.name,
            textInputAction: TextInputAction.next,
          ),

          const SizedBox(height: 18),

          // Email
          const FieldLabel('Email Address'),
          AppTextField(
            hintText: 'Enter your email address',
            prefixIcon: LucideIcons.mail,
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
          ),

          const SizedBox(height: 18),

          // Password
          const FieldLabel('Password'),
          AppTextField(
            hintText: 'Create a password',
            prefixIcon: LucideIcons.lock,
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
            suffixIcon: GestureDetector(
              onTap: () => setState(() => _obscurePassword = !_obscurePassword),
              child: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(
                  _obscurePassword ? LucideIcons.eye : LucideIcons.eyeOff,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),

          const SizedBox(height: 18),

          // Confirm Password
          const FieldLabel('Confirm Password'),
          AppTextField(
            hintText: 'Confirm your password',
            prefixIcon: LucideIcons.shieldCheck,
            controller: _confirmController,
            obscureText: _obscureConfirm,
            textInputAction: TextInputAction.done,
            suffixIcon: GestureDetector(
              onTap: () => setState(() => _obscureConfirm = !_obscureConfirm),
              child: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(
                  _obscureConfirm ? LucideIcons.eye : LucideIcons.eyeOff,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),

          const SizedBox(height: 28),

          // Submit Button
          _isLoading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: CircularProgressIndicator(),
                  ),
                )
              : PrimaryButton(
                  label: 'Create Account',
                  onPressed: _handleRegister,
                ),
        ],
      ),
    );
  }

  Widget _buildSocialSection() {
    return Column(
      children: [
        const SizedBox(height: 12),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Already have an account? ',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            GestureDetector(
              onTap: _navigateToLogin,
              child: Text(
                'Log In',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
