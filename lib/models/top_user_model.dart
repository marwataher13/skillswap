import 'package:skillswap/config/app_config.dart';

class TopUserSkill {
  final int id;
  final String name;
  final String description;
  final String level;

  const TopUserSkill({
    required this.id,
    required this.name,
    required this.description,
    required this.level,
  });

  factory TopUserSkill.fromJson(Map<String, dynamic> json) {
    return TopUserSkill(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      level: json['level']?.toString() ?? '',
    );
  }
}

class TopUserModel {
  final int userId;
  final String name;
  final String username;
  final String profilePicture;
  final double trustScore;
  final double averageRating;
  final int totalSwaps;
  final TopUserSkill? skill;

  const TopUserModel({
    required this.userId,
    required this.name,
    this.username = '',
    required this.profilePicture,
    required this.trustScore,
    required this.averageRating,
    required this.totalSwaps,
    this.skill,
  });

  factory TopUserModel.fromJson(Map<String, dynamic> json) {
    final rawPic = json['profile_picture']?.toString() ?? '';
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

    return TopUserModel(
      userId: int.tryParse(json['user_id']?.toString() ?? '') ?? int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      profilePicture: resolvedPic,
      trustScore: double.tryParse(json['trust_score']?.toString() ?? '') ?? 0.0,
      averageRating: double.tryParse(json['average_rating']?.toString() ?? '') ?? 0.0,
      totalSwaps: int.tryParse(json['total_swaps']?.toString() ?? '') ?? 0,
      skill: json['skill'] != null && json['skill'] is Map
          ? TopUserSkill.fromJson(json['skill'] as Map<String, dynamic>)
          : null,
    );
  }
}
