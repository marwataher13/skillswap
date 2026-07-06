import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../services/password_service.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_widgets.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _passwordService = PasswordService();

  bool _isLoading = false;
  bool _showEmailError = false;
  String _emailErrorText = 'Email address is required';

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

  bool _validate() {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _emailErrorText = 'Email address is required';
        _showEmailError = true;
      });
      return false;
    }
    if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,}$').hasMatch(email)) {
      setState(() {
        _emailErrorText = 'Please enter a valid email address';
        _showEmailError = true;
      });
      return false;
    }
    return true;
  }

  Future<void> _onSendCodePressed() async {
    FocusScope.of(context).unfocus();
    if (!_validate()) return;

    setState(() {
      _showEmailError = false;
      _isLoading = true;
    });

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final successColor = context.appColors.success;

    final result = await _passwordService.forgotPassword(
      email: _emailController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.isSuccess) {
      scaffoldMessenger.showSnackBar(_snackBar('OTP sent to your email! ✉️', isError: false, successColor: successColor));
      Navigator.pushNamed(
        context,
        '/verify-otp',
        arguments: {'email': _emailController.text.trim()},
      );
    } else {
      scaffoldMessenger.showSnackBar(_snackBar(result.error ?? 'Something went wrong', isError: true, successColor: successColor));
    }
  }

  SnackBar _snackBar(String message, {required bool isError, required Color successColor}) => SnackBar(
    content: Text(message),
    backgroundColor: isError ? const Color.fromARGB(255, 205, 36, 36) : successColor,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    margin: const EdgeInsets.all(16),
  );

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
                child: _buildFormCard(c),
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
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
              ),
              const Spacer(),
              Text(
                'Forgot Password',
                style: GoogleFonts.poppins(
                  fontSize: 28, fontWeight: FontWeight.w700,
                  color: Colors.white, letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Verify your credentials to reset',
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

  Widget _buildFormCard(AppColorsExtension c) {
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
                color: c.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(LucideIcons.lock, size: 30, color: c.primary),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Enter Registered Email',
              style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w700, color: c.textPrimary),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'We will send a 6-digit confirmation OTP to your\nverified email account.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13, fontWeight: FontWeight.w400,
                color: c.textSecondary, height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const FieldLabel('Email Address'),
          const SizedBox(height: 8),
          AppTextField(
            hintText: 'Your email address',
            prefixIcon: LucideIcons.mail,
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
          ),
          if (_showEmailError) ...[
            const SizedBox(height: 6),
            Text(_emailErrorText, style: GoogleFonts.poppins(fontSize: 12, color: c.error)),
          ],
          const SizedBox(height: 28),
          _isLoading
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: CircularProgressIndicator(color: c.primary),
                  ),
                )
              : PrimaryButton(label: 'Send Verification Code', onPressed: _onSendCodePressed),
        ],
      ),
    );
  }
}
