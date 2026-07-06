import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_widgets.dart';

class PasswordResetSuccessScreen extends StatelessWidget {
  const PasswordResetSuccessScreen({super.key});

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
              offset: const Offset(0, -28),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildFormCard(context, c),
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
      height: size.height * 0.30,
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 22),
              const Spacer(),
              Text(
                'Success!',
                style: GoogleFonts.poppins(
                  fontSize: 28, fontWeight: FontWeight.w700,
                  color: Colors.white, letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Your account is secured',
                style: GoogleFonts.poppins(
                  fontSize: 13, fontWeight: FontWeight.w400,
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

  Widget _buildFormCard(BuildContext context, AppColorsExtension c) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
      decoration: BoxDecoration(
        color: c.surface,
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
                color: c.success.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(LucideIcons.checkCircle2, size: 30, color: c.success),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Password Updated',
              style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w700, color: c.textPrimary),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Your password has been changed successfully.\nYou can now sign in with your new credentials.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13, fontWeight: FontWeight.w400,
                color: c.textSecondary, height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 32),
          PrimaryButton(
            label: 'Back to Login',
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            },
          ),
        ],
      ),
    );
  }
}
