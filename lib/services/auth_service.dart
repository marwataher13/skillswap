import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../utils/exception_utils.dart';

class LoginResult {
  final bool isSuccess;
  final String? token;
  final String? error;

  const LoginResult({
    required this.isSuccess,
    this.token,
    this.error,
  });
}

class AuthService {
  static const String _baseUrl = AppConfig.baseUrl;
  static const String _tokenKey = 'auth_token';

  static const Map<String, String> _baseHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'ngrok-skip-browser-warning': 'true',
  };

  /// HTTP headers including the saved Bearer token.
  static Future<Map<String, String>> getAuthHeaders() async {
    final token = await getToken();
    return {
      ..._baseHeaders,
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static Future<bool> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(_tokenKey, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<bool> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.remove(_tokenKey);
  }

  static Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Register a new user. Returns `null` on success, or an error message.
  Future<String?> register({
    required String name,
    required String username,
    required String email,
    required String password,
  }) async {
    debugPrint('AuthService: register for $email (username: $username)');
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/register'),
        headers: _baseHeaders,
        body: jsonEncode({
          'name': name,
          'username': username,
          'email': email,
          'password': password,
          'password_confirmation': password,
          'passwordConfirmation': password,
          'confirmPassword': password,
          'confirm_password': password,
        }),
      );

      debugPrint('AuthService.register: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return null;
      }

      return parseErrorMessage(response,
          defaultMessage: 'Registration failed. Please try again.');
    } catch (e) {
      debugPrint('AuthService.register exception: $e');
      return 'Network error: $e';
    }
  }

  /// Log in an existing user.
  Future<LoginResult> login({
    required String usernameOrEmail,
    required String password,
  }) async {
    debugPrint('AuthService: login for $usernameOrEmail');
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/login'),
        headers: _baseHeaders,
        body: jsonEncode({
          'email': usernameOrEmail,
          'login': usernameOrEmail,
          'log_in': usernameOrEmail,
          'username': usernameOrEmail,
          'password': password,
        }),
      );

      debugPrint('AuthService.login: ${response.statusCode}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final token = data['token'] ?? data['accessToken'] ?? '';
        return LoginResult(isSuccess: true, token: token as String?);
      }

      return LoginResult(
        isSuccess: false,
        error: parseErrorMessage(response,
            defaultMessage: 'Login failed. Please try again.'),
      );
    } catch (e) {
      debugPrint('AuthService.login exception: $e');
      return LoginResult(isSuccess: false, error: 'Network error: $e');
    }
  }

  /// Send a password-reset email. Returns `null` on success, or an error message.
  Future<String?> forgotPassword(String email) async {
    debugPrint('AuthService: password reset for $email');
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/forgot-password'),
        headers: _baseHeaders,
        body: jsonEncode({'email': email}),
      );

      debugPrint('AuthService.forgotPassword: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return null;
      }

      return parseErrorMessage(response,
          defaultMessage: 'Failed to request password reset. Please try again.');
    } catch (e) {
      debugPrint('AuthService.forgotPassword exception: $e');
      return 'Network error: $e';
    }
  }
}
