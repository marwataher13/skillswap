import 'package:skillswap/config/app_config.dart';

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
    final catVal = json['category'] ?? json['category_name'] ?? json['categoryName'];
    String resolvedCategory = '';
    if (catVal is String) {
      resolvedCategory = catVal;
    } else if (catVal is Map) {
      resolvedCategory = catVal['name']?.toString() ?? catVal['title']?.toString() ?? '';
    }

    return SearchSkillModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      level: json['level']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      category: resolvedCategory,
    );
  }
}

class SearchResultModel {
  final int userId;
  final String name;
  final String username;
  final String profilePicture;
  final double trustScore;
  final double averageRating;
  final List<SearchSkillModel> skills;

  const SearchResultModel({
    required this.userId,
    required this.name,
    this.username = '',
    required this.profilePicture,
    required this.trustScore,
    required this.averageRating,
    required this.skills,
  });

  factory SearchResultModel.fromJson(Map<String, dynamic> json) {
    final rawPic = json['profile_picture'] as String? ?? '';
    String resolvedPic = rawPic;
    if (resolvedPic.isNotEmpty) {
      if (resolvedPic.startsWith('http')) {
        if (resolvedPic.contains('/profile_pictures/') && !resolvedPic.contains('/storage/profile_pictures/')) {
          resolvedPic = resolvedPic.replaceFirst('/profile_pictures/', '/storage/profile_pictures/');
        }
      } else {
        if (resolvedPic.startsWith('profile_pictures') && !resolvedPic.startsWith('storage/')) {
          resolvedPic = 'storage/$resolvedPic';
        }
        final baseUrlClean = AppConfig.baseUrl.endsWith('/')
            ? AppConfig.baseUrl.substring(0, AppConfig.baseUrl.length - 1)
            : AppConfig.baseUrl;
        final pathClean = resolvedPic.startsWith('/') ? resolvedPic : '/$resolvedPic';
        resolvedPic = '$baseUrlClean$pathClean';
      }
    }
    return SearchResultModel(
      userId: int.tryParse(json['user_id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      profilePicture: resolvedPic,
      trustScore: double.tryParse(json['trust_score']?.toString() ?? '0') ?? 0.0,
      averageRating: double.tryParse(json['average_rating']?.toString() ?? '0') ?? 0.0,
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
