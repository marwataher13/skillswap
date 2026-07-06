import 'package:skillswap/utils/url_utils.dart';

class ReviewModel {
  final int id;
  final int reviewerId;
  final String reviewerName;
  final String reviewerImage;
  final double rating;
  final String comment;
  final DateTime createdAt;
  final List<String> reviewerTeachSkills;

  const ReviewModel({
    required this.id,
    required this.reviewerId,
    required this.reviewerName,
    required this.reviewerImage,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.reviewerTeachSkills = const [],
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    final rawRating = json['rating'];
    final resolvedRating = rawRating is num
        ? rawRating.toDouble()
        : double.tryParse(rawRating?.toString() ?? '') ?? 0.0;

    final reviewerJson = json['reviewer'] as Map<String, dynamic>?;

    final rId = reviewerJson?['id'] ??
        json['reviewer_id'] ??
        json['reviewerId'] ??
        0;
    final rName = (reviewerJson?['name'] ??
            json['reviewer_name'] ??
            json['reviewerName'] ??
            'Anonymous')
        .toString();

    final rawImage = reviewerJson?['profile_picture'] ??
        reviewerJson?['avatar'] ??
        json['reviewer_image'] ??
        json['reviewerImage'] ??
        '';
    final resolvedImage =
        resolveAvatarUrl(rawImage.toString()) ?? rawImage.toString();

    final dateStr =
        (json['created_at'] ?? json['createdAt'] ?? '').toString();
    DateTime parsedDate;
    try {
      parsedDate =
          dateStr.isNotEmpty ? DateTime.parse(dateStr) : DateTime.now();
    } catch (_) {
      parsedDate = DateTime.now();
    }

    final rawTeachSkills =
        reviewerJson?['teach_skills'] ?? json['reviewer_teach_skills'] ?? [];
    final teachSkills = <String>[];
    if (rawTeachSkills is List) {
      for (final s in rawTeachSkills) {
        if (s is Map) {
          final skillName = s['name']?.toString();
          if (skillName != null && skillName.isNotEmpty) {
            teachSkills.add(skillName);
          }
        } else if (s is String && s.isNotEmpty) {
          teachSkills.add(s);
        }
      }
    }

    return ReviewModel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      reviewerId: int.tryParse(rId.toString()) ?? 0,
      reviewerName: rName,
      reviewerImage: resolvedImage,
      rating: resolvedRating,
      comment: json['comment']?.toString() ?? '',
      createdAt: parsedDate,
      reviewerTeachSkills: teachSkills,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'reviewer_id': reviewerId,
        'reviewer_name': reviewerName,
        'reviewer_image': reviewerImage,
        'rating': rating,
        'comment': comment,
        'created_at': createdAt.toIso8601String(),
      };

  /// Extracts the embedded skill tag from the comment, e.g. `[Skill: Flutter]`.
  String? get swappedSkill {
    final match =
        RegExp(r'^\[Skill:\s*(.*?)\](?:\r?\n|$)').firstMatch(comment);
    return match?.group(1);
  }

  /// Comment body with the embedded skill tag stripped.
  String get cleanComment =>
      comment.replaceFirst(RegExp(r'^\[Skill:\s*(.*?)\](?:\r?\n|$)'), '');
}
