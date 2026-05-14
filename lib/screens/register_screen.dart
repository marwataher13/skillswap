import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../theme/app_theme.dart';
import '../widgets/auth_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() =>
      _RegisterScreenState();
}

class _RegisterScreenState
    extends State<RegisterScreen> {
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  final _nameController =
      TextEditingController();

  final _emailController =
      TextEditingController();

  final _passwordController =
      TextEditingController();

  final _confirmController =
      TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();

    super.dispose();
  }

  void _navigateToLogin() {
    Navigator.pushReplacementNamed(
      context,
      '/login',
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.background,

      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Gradient Header ───────────────────────────
            _buildHeader(size),

            // ── Form Card ─────────────────────────────────
            Transform.translate(
              offset: const Offset(0, -20),

              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                ),

                child: _buildFormCard(),
              ),
            ),

            // ── Social Section ────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                20,
                0,
                20,
                40,
              ),

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

  Widget _buildHeader(Size size) {
    return Container(
      width: double.infinity,
      height: size.height * 0.26,

      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,

          colors: [
            Color(0xFF7A5A48),
            AppColors.gradientEnd,
          ],
        ),

        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(
            AppSpacing.radiusXl,
          ),

          bottomRight: Radius.circular(
            AppSpacing.radiusXl,
          ),
        ),
      ),

      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 28,
            vertical: 16,
          ),

          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,

            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: _navigateToLogin,

                    child: Container(
                      padding: const EdgeInsets.all(8),

                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(
                          0.15,
                        ),

                        borderRadius:
                            BorderRadius.circular(10),
                      ),

                      child: const Icon(
                        LucideIcons.arrowLeft,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Text(
                    'SkillSwap',

                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(
                        0.90,
                      ),
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
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                'Join a community of learners & teachers',

                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withOpacity(
                    0.70,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(
        AppSpacing.lg,
      ),

      decoration: BoxDecoration(
        color: AppColors.surface,

        borderRadius: BorderRadius.circular(
          AppSpacing.radiusLg,
        ),

        boxShadow: AppShadows.card,
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          // Tab Switcher
          AuthTabSwitcher(
            selectedIndex: 1,

            onTabSelected: (index) {
              if (index == 0) {
                _navigateToLogin();
              }
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
            hintText:
                'Enter your email address',

            prefixIcon: LucideIcons.mail,
            controller: _emailController,

            keyboardType:
                TextInputType.emailAddress,

            textInputAction:
                TextInputAction.next,
          ),

          const SizedBox(height: 18),

          // Password
          const FieldLabel('Password'),

          AppTextField(
            hintText: 'Create a password',

            prefixIcon: LucideIcons.lock,

            controller: _passwordController,

            obscureText: _obscurePassword,

            textInputAction:
                TextInputAction.next,

            suffixIcon: GestureDetector(
              onTap: () {
                setState(() {
                  _obscurePassword =
                      !_obscurePassword;
                });
              },

              child: Padding(
                padding:
                    const EdgeInsets.only(
                  right: 4,
                ),

                child: Icon(
                  _obscurePassword
                      ? LucideIcons.eye
                      : LucideIcons.eyeOff,

                  size: 18,

                  color:
                      AppColors.textSecondary,
                ),
              ),
            ),
          ),

          const SizedBox(height: 18),

          // Confirm Password
          const FieldLabel(
            'Confirm Password',
          ),

          AppTextField(
            hintText:
                'Confirm your password',

            prefixIcon:
                LucideIcons.shieldCheck,

            controller: _confirmController,

            obscureText: _obscureConfirm,

            textInputAction:
                TextInputAction.done,

            suffixIcon: GestureDetector(
              onTap: () {
                setState(() {
                  _obscureConfirm =
                      !_obscureConfirm;
                });
              },

              child: Padding(
                padding:
                    const EdgeInsets.only(
                  right: 4,
                ),

                child: Icon(
                  _obscureConfirm
                      ? LucideIcons.eye
                      : LucideIcons.eyeOff,

                  size: 18,

                  color:
                      AppColors.textSecondary,
                ),
              ),
            ),
          ),

          const SizedBox(height: 28),

          // Sign Up Button
          PrimaryButton(
            label: 'Create Account',
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSocialSection() {
    return Column(
      children: [
        const AuthDivider(
          label: 'Or sign up with',
        ),

        const SizedBox(height: 20),

        // Google
        SocialButton(
          assetPath:
              'assets/images/google.png',

          label: 'Continue with Google',

          onTap: () {},
        ),

        const SizedBox(height: 12),

        // Apple
        SocialButton(
          assetPath:
              'assets/images/apple.png',

          label: 'Continue with Apple',

          onTap: () {},
        ),

        const SizedBox(height: 28),

        // Navigate to Login
        Row(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [
            Text(
              'Already have an account? ',

              style: GoogleFonts.poppins(
                fontSize: 14,
                color:
                    AppColors.textSecondary,
              ),
            ),

            GestureDetector(
              onTap: _navigateToLogin,

              child: Text(
                'Log In',

                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight:
                      FontWeight.w600,

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