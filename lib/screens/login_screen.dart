import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:provider/provider.dart';
import 'package:skillswap/providers/profile_provider.dart';
import 'package:skillswap/providers/notification_provider.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true;
  bool _isLoading = false;

  final _usernameOrEmailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  @override
  void dispose() {
    _usernameOrEmailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _navigateToRegister() {
    Navigator.pushReplacementNamed(context, '/register');
  }

  String? _validate() {
    final usernameOrEmail = _usernameOrEmailController.text.trim();
    final password = _passwordController.text;
    if (usernameOrEmail.isEmpty) return 'Please enter your username or email';
    if (usernameOrEmail.length < 3) return 'Username or email must be at least 3 characters';
    if (password.isEmpty) return 'Please enter your password';
    return null;
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();

    final validationError = _validate();
    if (validationError != null) {
      _showSnackBar(validationError, isError: true);
      return;
    }

    if (mounted) setState(() => _isLoading = true);

    try {
      final result = await _authService.login(
        usernameOrEmail: _usernameOrEmailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (result.isSuccess) {
        await AuthService.saveToken(result.token ?? '');
        if (!mounted) return;

        await Future.wait([
          context.read<ProfileProvider>().loadData(),
          context.read<NotificationProvider>().loadData(),
        ]);
        if (!mounted) return;

        _showSnackBar('Logged in successfully! Welcome back.', isError: false);
        Navigator.pushReplacementNamed(context, '/main');
      } else {
        _showSnackBar(result.error!, isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnackBar('Something went wrong: $e', isError: true);
    }
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
      height: size.height * 0.28,
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
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(LucideIcons.refreshCw, size: 22, color: c.surface),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'SkillSwap',
                    style: GoogleFonts.poppins(
                      fontSize: 20, fontWeight: FontWeight.w700,
                      color: c.surface, letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Welcome Back',
                style: GoogleFonts.poppins(
                  fontSize: 28, fontWeight: FontWeight.w700,
                  color: c.surface, letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Sign in to continue your journey',
                style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.w400,
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
            selectedIndex: 0,
            onTabSelected: (index) {
              if (index == 1) _navigateToRegister();
            },
          ),
          const SizedBox(height: 28),
          const FieldLabel('Username or Email'),
          AppTextField(
            hintText: 'Enter your username or email',
            prefixIcon: LucideIcons.user,
            controller: _usernameOrEmailController,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 20),
          const FieldLabel('Password'),
          AppTextField(
            hintText: 'Enter your password',
            prefixIcon: LucideIcons.lock,
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            suffixIcon: GestureDetector(
              onTap: () => setState(() => _obscurePassword = !_obscurePassword),
              child: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(
                  _obscurePassword ? LucideIcons.eye : LucideIcons.eyeOff,
                  size: 18,
                  color: c.textSecondary,
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.pushNamed(context, '/forgot-password'),
              style: TextButton.styleFrom(
                foregroundColor: c.primary,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              ),
              child: Text(
                'Forgot Password?',
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: c.primary),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _isLoading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: CircularProgressIndicator(),
                  ),
                )
              : PrimaryButton(label: 'Log In', onPressed: _handleLogin),
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
              "Don't have an account? ",
              style: GoogleFonts.poppins(fontSize: 14, color: c.textSecondary),
            ),
            GestureDetector(
              onTap: _navigateToRegister,
              child: Text(
                'Sign Up',
                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: c.primary),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
