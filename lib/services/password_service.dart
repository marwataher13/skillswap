import 'dart:convert';
import 'package:http/http.dart' as http;

// ─── Result model ─────────────────────────────────────────────────────────────
class PasswordServiceResult {
  final bool isSuccess;
  final String? message;
  final String? error;

  const PasswordServiceResult._({
    required this.isSuccess,
    this.message,
    this.error,
  });

  factory PasswordServiceResult.success(String message) =>
      PasswordServiceResult._(isSuccess: true, message: message);

  factory PasswordServiceResult.failure(String error) =>
      PasswordServiceResult._(isSuccess: false, error: error);
}

// ─── Service ──────────────────────────────────────────────────────────────────
class PasswordService {
  static const String _baseUrl =
      'https://lurch-unstopped-backed.ngrok-free.dev/api/auth';

  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // ── Forgot Password ────────────────────────────────────────────────────────
  // POST /forgot-password  { "email": "..." }
  // Success → { "message": "OTP sent to your email." }
  // Error   → { "message": "User not found." }
  Future<PasswordServiceResult> forgotPassword({required String email}) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/forgot-password'),
            headers: _headers,
            body: jsonEncode({'email': email}),
          )
          .timeout(const Duration(seconds: 300));

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final message = body['message'] as String? ?? 'Unknown error';

      if (response.statusCode == 200) {
        return PasswordServiceResult.success(message);
      }
      return PasswordServiceResult.failure(message);
    } catch (e) {
      return PasswordServiceResult.failure(
        'Network error. Please check your connection.',
      );
    }
  }

  // ── Verify OTP ─────────────────────────────────────────────────────────────
  // POST /verify-reset-otp  { "email": "...", "otp": "123456" }
  // Success → { "message": "OTP verified." }
  // Error   → { "message": "Invalid OTP." | "OTP expired." }
  //
  // ⚠️  BACKEND NOTE (see README section below):
  //     The current endpoint does NOT return a reset token.
  //     We store email + otp locally and use them in the reset call.
  Future<PasswordServiceResult> verifyOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/verify-reset-otp'),
            headers: _headers,
            body: jsonEncode({'email': email, 'otp': otp}),
          )
          .timeout(const Duration(seconds: 300));

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final message = body['message'] as String? ?? 'Unknown error';

      // Some backends return 200 for both success/error — check message too
      if (response.statusCode == 200 &&
          message.toLowerCase().contains('verified')) {
        return PasswordServiceResult.success(message);
      }
      if (response.statusCode == 200 &&
          !message.toLowerCase().contains('invalid') &&
          !message.toLowerCase().contains('expired')) {
        return PasswordServiceResult.success(message);
      }
      return PasswordServiceResult.failure(message);
    } catch (e) {
      return PasswordServiceResult.failure(
        'Network error. Please check your connection.',
      );
    }
  }

  // ── Reset Password ─────────────────────────────────────────────────────────
  // POST /reset-password
  // {
  //   "token": "...",          ← see backend note
  //   "email": "...",
  //   "password": "...",
  //   "password_confirmation": "..."
  // }
  // Success → { "message": "Password reset successfully." }
  // Error   → { "message": "Invalid reset token or email." }
  Future<PasswordServiceResult> resetPassword({
    required String email,
    required String password,
    required String passwordConfirmation,
    String token = '', // ← passed from VerifyOtp screen once backend returns it
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/reset-password'),
            headers: _headers,
            body: jsonEncode({
              'token': token,
              'email': email,
              'password': password,
              'password_confirmation': passwordConfirmation,
            }),
          )
          .timeout(const Duration(seconds: 300));

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final message = body['message'] as String? ?? 'Unknown error';

      if (response.statusCode == 200) {
        return PasswordServiceResult.success(message);
      }
      return PasswordServiceResult.failure(message);
    } catch (e) {
      return PasswordServiceResult.failure(
        'Network error. Please check your connection.',
      );
    }
  }
}
