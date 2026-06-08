import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:skillswap/config/app_config.dart';
import 'package:skillswap/models/review_model.dart';
import 'package:skillswap/services/auth_service.dart';

class ReviewService {
  static const String _baseUrl = AppConfig.baseUrl;

  /// Fetch all reviews for a specific user.
  /// GET /api/users/{userId}/reviews
  Future<List<ReviewModel>> fetchUserReviews(int userId) async {
    final url = Uri.parse('$_baseUrl/api/users/$userId/reviews');
    final headers = await AuthService.getAuthHeaders();
    final response = await http.get(url, headers: headers).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final List<dynamic> raw = decoded is Map
          ? (decoded['reviews'] ?? decoded['data'] ?? [])
          : (decoded is List ? decoded : []);
      return raw.map((item) => ReviewModel.fromJson(item as Map<String, dynamic>)).toList();
    } else {
      _handleErrorResponse(response);
      return [];
    }
  }

  /// Add a new review.
  /// POST /api/reviews
  Future<ReviewModel> addReview({
    required int userId,
    required int swapRequestId,
    required double rating,
    required String comment,
  }) async {
    final url = Uri.parse('$_baseUrl/api/reviews');
    final headers = await AuthService.getAuthHeaders();
    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode({
        'user_id': userId,
        'swap_request_id': swapRequestId,
        'rating': rating,
        'comment': comment,
      }),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200 || response.statusCode == 201) {
      final decoded = jsonDecode(response.body);
      final data = decoded is Map && decoded.containsKey('data') ? decoded['data'] : decoded;
      return ReviewModel.fromJson(data as Map<String, dynamic>);
    } else {
      _handleErrorResponse(response);
      throw Exception('Failed to add review');
    }
  }

  /// Get details of a specific review.
  /// GET /api/reviews/{id}
  Future<ReviewModel> fetchReviewDetails(int id) async {
    final url = Uri.parse('$_baseUrl/api/reviews/$id');
    final headers = await AuthService.getAuthHeaders();
    final response = await http.get(url, headers: headers).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final data = decoded is Map && decoded.containsKey('data') ? decoded['data'] : decoded;
      return ReviewModel.fromJson(data as Map<String, dynamic>);
    } else {
      _handleErrorResponse(response);
      throw Exception('Failed to fetch review details');
    }
  }

  /// Delete a review.
  /// DELETE /api/reviews/{id}
  Future<void> deleteReview(int id) async {
    final url = Uri.parse('$_baseUrl/api/reviews/$id');
    final headers = await AuthService.getAuthHeaders();
    final response = await http.delete(url, headers: headers).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200 && response.statusCode != 204) {
      _handleErrorResponse(response);
    }
  }

  /// Helper method to extract API validation errors and convert them into exceptions.
  void _handleErrorResponse(http.Response response) {
    String errorMessage = 'Request failed with status ${response.statusCode}';
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) {
        if (decoded.containsKey('message')) {
          errorMessage = decoded['message'].toString();
        } else if (decoded.containsKey('error')) {
          errorMessage = decoded['error'].toString();
        } else if (decoded.containsKey('errors')) {
          final errors = decoded['errors'];
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
      // JSON decoding failed
    }

    if (response.statusCode == 404) {
      throw Exception('Resource not found: $errorMessage');
    } else if (response.statusCode == 422) {
      throw Exception('Validation error: $errorMessage');
    } else {
      throw Exception(errorMessage);
    }
  }
}
