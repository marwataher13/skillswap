import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_widgets.dart';

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
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _authService = AuthService();

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String? _validate() {
    final name = _nameController.text.trim();
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirm = _confirmController.text.trim();

    if (kDebugMode) {
      debugPrint('name: "$name"');
      debugPrint('username: "$username"');
      debugPrint('email: "$email"');
      debugPrint('password length: ${password.length}');
      debugPrint('confirm length: ${confirm.length}');
      debugPrint('are equal: ${password == confirm}');
    }

    if (name.isEmpty) return 'Please enter your full name';
    if (username.isEmpty) return 'Please enter a username';
    if (username.length < 3) return 'Username must be at least 3 characters';
    if (username.length > 30) return 'Username must be under 30 characters';
    if (!RegExp(r'^[a-zA-Z0-9_\.]+$').hasMatch(username)) {
      return 'Username can only contain letters, numbers, underscores, and dots';
    }
    if (email.isEmpty || !email.contains('@')) return 'Please enter a valid email address';
    if (password.length < 6) return 'Password must be at least 6 characters';
    if (password != confirm) return 'Passwords do not match';
    return null;
  }

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
        username: _usernameController.text.trim(),
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

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: c.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(size, c),
            Transform.translate(
              offset: const Offset(0, -20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildFormCard(c),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              child: Transform.translate(
                offset: const Offset(0, -20),
                child: _buildSocialSection(c),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Size size, AppColorsExtension c) {
    return Container(
      width: double.infinity,
      height: size.height * 0.26,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c.gradientStart, c.gradientEnd],
        ),
        borderRadius: const BorderRadius.only(
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
                      child: Icon(LucideIcons.arrowLeft, size: 18, color: c.surface),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'SkillSwap',
                    style: GoogleFonts.poppins(
                      fontSize: 18, fontWeight: FontWeight.w600,
                      color: c.surface.withValues(alpha: 0.90),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Create Account',
                style: GoogleFonts.poppins(
                  fontSize: 28, fontWeight: FontWeight.w700,
                  color: c.surface, letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Join a community of learners & teachers',
                style: GoogleFonts.poppins(
                  fontSize: 13, fontWeight: FontWeight.w400,
                  color: c.surface.withValues(alpha: 0.70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormCard(AppColorsExtension c) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: c.surface,
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
          const FieldLabel('Full Name'),
          AppTextField(
            hintText: 'Enter your full name',
            prefixIcon: LucideIcons.user,
            controller: _nameController,
            keyboardType: TextInputType.name,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 18),
          const FieldLabel('Username'),
          AppTextField(
            hintText: 'Enter your username',
            prefixIcon: LucideIcons.userCheck,
            controller: _usernameController,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 18),
          const FieldLabel('Email Address'),
          AppTextField(
            hintText: 'Enter your email address',
            prefixIcon: LucideIcons.mail,
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 18),
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
                  size: 18, color: c.textSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
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
                  size: 18, color: c.textSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          _isLoading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: CircularProgressIndicator(),
                  ),
                )
              : PrimaryButton(label: 'Create Account', onPressed: _handleRegister),
        ],
      ),
    );
  }

  Widget _buildSocialSection(AppColorsExtension c) {
    return Column(
      children: [
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Already have an account? ',
              style: GoogleFonts.poppins(fontSize: 14, color: c.textSecondary),
            ),
            GestureDetector(
              onTap: _navigateToLogin,
              child: Text(
                'Log In',
                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: c.primary),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
