import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class LoginResult {
  final bool isSuccess;
  final String? token;
  final String? error;

  LoginResult({
    required this.isSuccess,
    this.token,
    this.error,
  });
}

class AuthService {
  static const String baseUrl = AppConfig.baseUrl;
  static const String _tokenKey = 'auth_token';

  /// Generate HTTP request headers automatically incorporating the saved session token.
  static Future<Map<String, String>> getAuthHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'ngrok-skip-browser-warning': 'true',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  /// Save authentication token to persistent local storage.
  static Future<bool> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(_tokenKey, token);
  }

  /// Retrieve stored authentication token from local storage.
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Clear stored authentication token (for logout flows).
  static Future<bool> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.remove(_tokenKey);
  }

  /// Verify if a valid authentication token exists locally.
  static Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Register a new user with name, email, and password.
  /// Returns null on success, or an error message on failure.
  Future<String?> register({
    required String name,
    required String email,
    required String password,
  }) async {
    debugPrint('AuthService: Attempting register for email: $email');
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/register'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': password,
          'passwordConfirmation': password,
          'confirmPassword': password,
          'confirm_password': password,
        }),
      );

      debugPrint('AuthService.register: status code = ${response.statusCode}');
      debugPrint('AuthService.register: response body = ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return null; // Success!
      }

      // Robust response error extraction
      String errorMessage = 'Registration failed. Please try again.';
      try {
        final data = jsonDecode(response.body);
        if (data is Map) {
          if (data.containsKey('message')) {
            errorMessage = data['message'].toString();
          } else if (data.containsKey('error')) {
            errorMessage = data['error'].toString();
          } else if (data.containsKey('errors')) {
            final errors = data['errors'];
            if (errors is Map) {
              errorMessage = errors.values.map((e) {
                if (e is List) return e.join(', ');
                return e.toString();
              }).join('\n');
            } else if (errors is List) {
              errorMessage = errors.join(', ');
            } else {
              errorMessage = errors.toString();
            }
          }
        }
      } catch (_) {
        errorMessage = 'Server error (${response.statusCode})';
      }

      return errorMessage;
    } catch (e) {
      debugPrint('AuthService.register exception: $e');
      return 'Network error: $e';
    }
  }

  /// Log in an existing user.
  /// Returns a LoginResult with details.
  Future<LoginResult> login({
    required String email,
    required String password,
  }) async {
    debugPrint('AuthService: Attempting login for email: $email');
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      debugPrint('AuthService.login: status code = ${response.statusCode}');
      debugPrint('AuthService.login: response body = ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final token = data['token'] ?? data['accessToken'] ?? '';
        return LoginResult(isSuccess: true, token: token);
      }

      String errorMessage = 'Login failed. Please try again.';
      if (data is Map) {
        if (data.containsKey('message')) {
          errorMessage = data['message'].toString();
        } else if (data.containsKey('error')) {
          errorMessage = data['error'].toString();
        }
      }
      return LoginResult(isSuccess: false, error: errorMessage);
    } catch (e) {
      debugPrint('AuthService.login exception: $e');
      return LoginResult(isSuccess: false, error: 'Network error: $e');
    }
  }

  /// Send forgot password reset email request.
  /// Returns null on success, or an error message on failure.
  Future<String?> forgotPassword(String email) async {
    debugPrint('AuthService: Requesting password reset for email: $email');
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/forgot-password'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({
          'email': email,
        }),
      );

      debugPrint('AuthService.forgotPassword: status code = ${response.statusCode}');
      debugPrint('AuthService.forgotPassword: response body = ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return null; // Success!
      }

      // Robust response error extraction
      String errorMessage = 'Failed to request password reset. Please try again.';
      try {
        final data = jsonDecode(response.body);
        if (data is Map) {
          if (data.containsKey('message')) {
            errorMessage = data['message'].toString();
          } else if (data.containsKey('error')) {
            errorMessage = data['error'].toString();
          } else if (data.containsKey('errors')) {
            final errors = data['errors'];
            if (errors is Map) {
              errorMessage = errors.values.map((e) {
                if (e is List) return e.join(', ');
                return e.toString();
              }).join('\n');
            } else {
              errorMessage = errors.toString();
            }
          }
        }
      } catch (_) {
        errorMessage = 'Server error (${response.statusCode})';
      }

      return errorMessage;
    } catch (e) {
      debugPrint('AuthService.forgotPassword exception: $e');
      return 'Network error: $e';
    }
  }
}
