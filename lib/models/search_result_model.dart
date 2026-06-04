class SearchSkillModel {
  final int id;
  final String name;
  final String description;
  final String level;
  final String type;
  final String category;

  const SearchSkillModel({
    required this.id,
    required this.name,
    required this.description,
    required this.level,
    required this.type,
    required this.category,
  });

  factory SearchSkillModel.fromJson(Map<String, dynamic> json) {
    return SearchSkillModel(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      level: json['level'] as String? ?? '',
      type: json['type'] as String? ?? '',
      category: json['category'] as String? ?? '',
    );
  }
}

class SearchResultModel {
  final int userId;
  final String name;
  final String profilePicture;
  final int trustScore;
  final double averageRating;
  final List<SearchSkillModel> skills;

  const SearchResultModel({
    required this.userId,
    required this.name,
    required this.profilePicture,
    required this.trustScore,
    required this.averageRating,
    required this.skills,
  });

  factory SearchResultModel.fromJson(Map<String, dynamic> json) {
    return SearchResultModel(
      userId: json['user_id'] as int,
      name: json['name'] as String,
      profilePicture: json['profile_picture'] as String? ?? '',
      trustScore: json['trust_score'] as int? ?? 0,
      averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0.0,
      skills: (json['skills'] as List<dynamic>? ?? [])
          .map((s) => SearchSkillModel.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Convenience: returns the first skill's name, or empty string.
  String get primarySkillName => skills.isNotEmpty ? skills.first.name : '';

  /// Convenience: returns the first skill's category, or empty string.
  String get primaryCategory => skills.isNotEmpty ? skills.first.category : '';
}
