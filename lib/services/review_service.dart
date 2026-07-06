import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:skillswap/config/app_config.dart';
import 'package:skillswap/models/review_model.dart';
import 'package:skillswap/services/auth_service.dart';
import 'package:skillswap/utils/exception_utils.dart';

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
        'rating': rating.toInt(),
        'comment': comment,
      }),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200 || response.statusCode == 201) {
      final decoded = jsonDecode(response.body);
      final data = decoded is Map
          ? (decoded['review'] ?? decoded['data'] ?? decoded)
          : decoded;
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
      final data = decoded is Map
          ? (decoded['review'] ?? decoded['data'] ?? decoded)
          : decoded;
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

  void _handleErrorResponse(http.Response response) {
    final msg = parseErrorMessage(response, defaultMessage: 'Request failed');
    if (response.statusCode == 404) {
      throw Exception('Resource not found: $msg');
    } else if (response.statusCode == 422) {
      throw Exception('Validation error: $msg');
    } else {
      throw Exception(msg);
    }
  }
}
