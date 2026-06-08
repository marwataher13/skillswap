class ReviewModel {
  final int id;
  final int reviewerId;
  final String reviewerName;
  final String reviewerImage;
  final double rating;
  final String comment;
  final DateTime createdAt;

  const ReviewModel({
    required this.id,
    required this.reviewerId,
    required this.reviewerName,
    required this.reviewerImage,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  /// Factory constructor to map json payload into a ReviewModel instance.
  /// Handles both direct keys and nested reviewer payloads safely.
  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    // Safely convert rating to double
    final rawRating = json['rating'];
    double resolvedRating = 0.0;
    if (rawRating is num) {
      resolvedRating = rawRating.toDouble();
    } else if (rawRating is String) {
      resolvedRating = double.tryParse(rawRating) ?? 0.0;
    }

    // Extract reviewer fields either from a nested object or root keys
    final reviewerJson = json['reviewer'] as Map<String, dynamic>?;

    final rId = reviewerJson?['id'] ?? json['reviewer_id'] ?? json['reviewerId'] ?? 0;
    final rName = reviewerJson?['name'] ?? json['reviewer_name'] ?? json['reviewerName'] ?? 'Anonymous';
    final rImage = reviewerJson?['profile_picture'] ?? reviewerJson?['avatar'] ?? json['reviewer_image'] ?? json['reviewerImage'] ?? '';

    // Safely parse createdAt timestamp
    final dateStr = json['created_at'] ?? json['createdAt'] ?? '';
    DateTime parsedDate;
    try {
      parsedDate = dateStr.isNotEmpty ? DateTime.parse(dateStr.toString()) : DateTime.now();
    } catch (_) {
      parsedDate = DateTime.now();
    }

    return ReviewModel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      reviewerId: int.tryParse(rId.toString()) ?? 0,
      reviewerName: rName.toString(),
      reviewerImage: rImage.toString(),
      rating: resolvedRating,
      comment: json['comment']?.toString() ?? '',
      createdAt: parsedDate,
    );
  }

  /// Serialize ReviewModel object instance back into standard json map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reviewer_id': reviewerId,
      'reviewer_name': reviewerName,
      'reviewer_image': reviewerImage,
      'rating': rating,
      'comment': comment,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
