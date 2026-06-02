import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_widgets.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _showEmailError = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(() {
      if (_showEmailError && _emailController.text.trim().isNotEmpty) {
        setState(() => _showEmailError = false);
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _onSendCodePressed() {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _showEmailError = true);
      return;
    }

    setState(() {
      _showEmailError = false;
      _isLoading = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnackBar(
        'A 6-digit OTP has been sent to your email! ✉️',
        isError: false,
      );
      Navigator.pushReplacementNamed(context, '/verify-otp');
    });
  }

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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Gradient Header ───────────────────────────────────────────
            _buildHeader(size),

            // ── Form Card ─────────────────────────────────────────────────
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
              // ── Top Bar: back arrow ──
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 22,
                ),
              ),

              const Spacer(),

              // ── Title & Subtitle ──
              Text(
                'Forgot Password',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Verify your credentials to reset',
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
          // ── Lock icon circle ──
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

          // ── Card title ──
          Center(
            child: Text(
              'Enter Registered Email',
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // ── Card subtitle ──
          Center(
            child: Text(
              'We will send a 6-digit confirmation OTP to your\nverified email account.',
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

          // ── Email label ──
          const FieldLabel('Email Address'),
          const SizedBox(height: 8),

          // ── Email field ──
          AppTextField(
            hintText: 'Your email address',
            prefixIcon: LucideIcons.mail,
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
          ),

          // ── Inline error ──
          if (_showEmailError) ...[
            const SizedBox(height: 6),
            Text(
              'Email address is required',
              style: GoogleFonts.poppins(fontSize: 12, color: AppColors.error),
            ),
          ],

          const SizedBox(height: 28),

          // ── Send Verification Code Button ──
          _isLoading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              : PrimaryButton(
                  label: 'Send Verification Code',
                  onPressed: _onSendCodePressed,
                ),
        ],
      ),
    );
  }
}
