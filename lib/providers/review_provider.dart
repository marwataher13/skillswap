import 'package:flutter/material.dart';
import 'package:skillswap/models/review_model.dart';
import 'package:skillswap/services/review_service.dart';

/// Enum defining state boundaries for the Reviews feature.
enum ReviewUiState { initial, loading, success, error, empty }

class ReviewProvider extends ChangeNotifier {
  final _reviewService = ReviewService();

  List<ReviewModel> _reviews = [];
  ReviewModel? _activeReviewDetails;
  ReviewUiState _state = ReviewUiState.initial;
  String? _error;

  // ─── Getters ──────────────────────────────────────────────────────────────
  List<ReviewModel> get reviews => List.unmodifiable(_reviews);
  ReviewModel? get activeReviewDetails => _activeReviewDetails;
  ReviewUiState get state => _state;
  String? get error => _error;

  // Helper flags for UI readability
  bool get isInitial => _state == ReviewUiState.initial;
  bool get isLoading => _state == ReviewUiState.loading;
  bool get isSuccess => _state == ReviewUiState.success;
  bool get isError => _state == ReviewUiState.error;
  bool get isEmpty => _state == ReviewUiState.empty;

  // ─── Actions ──────────────────────────────────────────────────────────────

  /// Fetch all reviews targeting a specific user ID.
  /// Sets State to Loading, Error, Success, or Empty.
  Future<void> loadUserReviews(int userId) async {
    _state = ReviewUiState.loading;
    _error = null;
    notifyListeners();

    try {
      final list = await _reviewService.fetchUserReviews(userId);
      _reviews = list;
      _state = list.isEmpty ? ReviewUiState.empty : ReviewUiState.success;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _state = ReviewUiState.error;
      debugPrint('ReviewProvider.loadUserReviews error: $e');
    } finally {
      notifyListeners();
    }
  }

  /// Create and post a new review.
  /// Updates internal cache to prepend the created review dynamically.
  Future<void> createReview({
    required int userId,
    required int swapRequestId,
    required double rating,
    required String comment,
  }) async {
    _state = ReviewUiState.loading;
    _error = null;
    notifyListeners();

    try {
      final newReview = await _reviewService.addReview(
        userId: userId,
        swapRequestId: swapRequestId,
        rating: rating,
        comment: comment,
      );
      _reviews = [newReview, ..._reviews];
      _state = ReviewUiState.success;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _state = ReviewUiState.error;
      debugPrint('ReviewProvider.createReview error: $e');
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  /// Fetch detailed payload for a single review.
  Future<void> loadReviewDetails(int reviewId) async {
    _state = ReviewUiState.loading;
    _error = null;
    notifyListeners();

    try {
      _activeReviewDetails = await _reviewService.fetchReviewDetails(reviewId);
      _state = ReviewUiState.success;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _state = ReviewUiState.error;
      debugPrint('ReviewProvider.loadReviewDetails error: $e');
    } finally {
      notifyListeners();
    }
  }

  /// Remove a review and update internal list.
  /// Fallbacks to Empty state if cached list drains.
  Future<void> removeReview(int reviewId) async {
    _state = ReviewUiState.loading;
    _error = null;
    notifyListeners();

    try {
      await _reviewService.deleteReview(reviewId);
      _reviews = _reviews.where((r) => r.id != reviewId).toList();
      _state = _reviews.isEmpty ? ReviewUiState.empty : ReviewUiState.success;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _state = ReviewUiState.error;
      debugPrint('ReviewProvider.removeReview error: $e');
      rethrow;
    } finally {
      notifyListeners();
    }
  }
}
