import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../services/password_service.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_widgets.dart';

class VerifyOtpScreen extends StatefulWidget {
  const VerifyOtpScreen({super.key});

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  static const int _otpLength = 6;
  static const int _resendSeconds = 4 * 60 + 53;

  final List<TextEditingController> _controllers = List.generate(_otpLength, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(_otpLength, (_) => FocusNode());
  final List<FocusNode> _keyboardFocusNodes = List.generate(_otpLength, (_) => FocusNode());

  final _passwordService = PasswordService();

  bool _isLoading = false;
  int _timerSeconds = _resendSeconds;
  bool _canResend = false;
  Timer? _timer;
  String _email = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _email = args?['email'] as String? ?? '';
  }

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) { c.dispose(); }
    for (final f in _focusNodes) { f.dispose(); }
    for (final f in _keyboardFocusNodes) { f.dispose(); }
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _timerSeconds = _resendSeconds;
      _canResend = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        if (_timerSeconds > 0) {
          _timerSeconds--;
        } else {
          _canResend = true;
          t.cancel();
        }
      });
    });
  }

  String get _formattedTimer {
    final m = _timerSeconds ~/ 60;
    final s = _timerSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String get _otpValue => _controllers.map((c) => c.text.trim()).join();

  void _clearOtp() {
    for (final c in _controllers) { c.clear(); }
    _focusNodes.first.requestFocus();
  }

  void _onOtpChanged(int index, String value) {
    if (value.length == _otpLength) {
      for (int i = 0; i < _otpLength; i++) { _controllers[i].text = value[i]; }
      _focusNodes.last.requestFocus();
      return;
    }
    if (value.isNotEmpty && index < _otpLength - 1) {
      _focusNodes[index + 1].requestFocus();
    }
  }

  void _onKeyPressed(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  Future<void> _onConfirmPressed() async {
    final code = _otpValue;
    if (code.length < _otpLength) {
      _showSnackBar('Please enter the complete 6-digit code', isError: true);
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final successColor = context.appColors.success;

    final result = await _passwordService.verifyOtp(email: _email, otp: code);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.isSuccess) {
      scaffoldMessenger.showSnackBar(_snackBar('OTP verified successfully! ✅', isError: false, successColor: successColor));
      Navigator.pushNamed(
        context,
        '/new-password',
        arguments: {'email': _email, 'token': ''},
      );
    } else {
      scaffoldMessenger.showSnackBar(_snackBar(result.error ?? 'Verification failed', isError: true, successColor: successColor));
      _clearOtp();
    }
  }

  Future<void> _onResendPressed() async {
    if (!_canResend) return;
    _clearOtp();

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final successColor = context.appColors.success;

    final result = await _passwordService.forgotPassword(email: _email);
    if (!mounted) return;

    if (result.isSuccess) {
      _startTimer();
      scaffoldMessenger.showSnackBar(_snackBar('A new OTP has been sent to your email! ✉️', isError: false, successColor: successColor));
    } else {
      scaffoldMessenger.showSnackBar(_snackBar(result.error ?? 'Failed to resend OTP', isError: true, successColor: successColor));
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      _snackBar(message, isError: isError, successColor: context.appColors.success),
    );
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
                'Verify OTP',
                style: GoogleFonts.poppins(
                  fontSize: 28, fontWeight: FontWeight.w700,
                  color: Colors.white, letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Verify security code matching',
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
              child: Icon(LucideIcons.terminal, size: 30, color: c.primary),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Enter 6-digit Code',
              style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w700, color: c.textPrimary),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w400, color: c.textSecondary, height: 1.5),
                children: [
                  const TextSpan(text: 'We sent a secure code to '),
                  TextSpan(
                    text: _email,
                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: c.primary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          _buildOtpRow(c),
          const SizedBox(height: 24),
          _buildResendRow(c),
          const SizedBox(height: 28),
          _isLoading
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: CircularProgressIndicator(color: c.primary),
                  ),
                )
              : PrimaryButton(label: 'Confirm OTP Code', onPressed: _onConfirmPressed),
        ],
      ),
    );
  }

  Widget _buildOtpRow(AppColorsExtension c) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(_otpLength, (index) {
        return KeyboardListener(
          focusNode: _keyboardFocusNodes[index],
          onKeyEvent: (event) => _onKeyPressed(index, event),
          child: SizedBox(
            width: 44,
            height: 52,
            child: TextField(
              controller: _controllers[index],
              focusNode: _focusNodes[index],
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              maxLength: 1,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: c.textPrimary),
              decoration: InputDecoration(
                counterText: '',
                filled: true,
                fillColor: c.primary.withValues(alpha: 0.08),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: c.primary, width: 2),
                ),
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (value) => _onOtpChanged(index, value),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildResendRow(AppColorsExtension c) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Resend code in:', style: GoogleFonts.poppins(fontSize: 13, color: c.textSecondary)),
        _canResend
            ? GestureDetector(
                onTap: _onResendPressed,
                child: Text(
                  'Resend',
                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: c.primary),
                ),
              )
            : Text(
                _formattedTimer,
                style: GoogleFonts.poppins(
                  fontSize: 13, fontWeight: FontWeight.w600, color: c.primary,
                  fontFeatures: [const FontFeature.tabularFigures()],
                ),
              ),
      ],
    );
  }
}
