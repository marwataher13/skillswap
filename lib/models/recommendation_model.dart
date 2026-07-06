import 'package:skillswap/config/app_config.dart';

class RecommendationModel {
  final int userId;
  final String name;
  final String username;
  final String profilePicture;
  final double? matchScore;
  final List<String> skillsTeach;
  final List<String> skillsLearn;

  const RecommendationModel({
    required this.userId,
    required this.name,
    required this.username,
    required this.profilePicture,
    this.matchScore,
    required this.skillsTeach,
    required this.skillsLearn,
  });

  factory RecommendationModel.fromJson(Map<String, dynamic> json) {
    // Resolve profile picture path
    final rawPic = json['profile_picture'] as String? ?? json['avatar_url'] as String? ?? '';
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

    // Extract match score
    final rawScore = json['match_score'] ?? json['score'];
    double? resolvedScore;
    if (rawScore != null) {
      resolvedScore = double.tryParse(rawScore.toString());
    }

    // Extract skills they teach
    final List<String> teach = [];
    final rawTeach = json['skills_teach'] ?? json['teaching'] ?? json['teach_skills'] ?? json['teach'];
    if (rawTeach is List) {
      for (final s in rawTeach) {
        if (s is String) {
          teach.add(s);
        } else if (s is Map) {
          teach.add(s['name']?.toString() ?? '');
        }
      }
    }

    // Extract skills they want to learn
    final List<String> learn = [];
    final rawLearn = json['skills_learn'] ?? json['learning'] ?? json['learn_skills'] ?? json['learn'];
    if (rawLearn is List) {
      for (final s in rawLearn) {
        if (s is String) {
          learn.add(s);
        } else if (s is Map) {
          learn.add(s['name']?.toString() ?? '');
        }
      }
    }

    // Fallback: if teach and learn are empty, look at a unified "skills" array if present
    final rawSkills = json['skills'];
    if (teach.isEmpty && learn.isEmpty && rawSkills is List) {
      for (final s in rawSkills) {
        if (s is Map) {
          final sName = s['name']?.toString() ?? '';
          final sType = s['type']?.toString() ?? '';
          if (sType == 'teach') {
            teach.add(sName);
          } else if (sType == 'learn') {
            learn.add(sName);
          } else {
            teach.add(sName);
          }
        }
      }
    }

    return RecommendationModel(
      userId: int.tryParse(json['id']?.toString() ?? json['user_id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      profilePicture: resolvedPic,
      matchScore: resolvedScore,
      skillsTeach: teach.where((s) => s.isNotEmpty).toList(),
      skillsLearn: learn.where((s) => s.isNotEmpty).toList(),
    );
  }
}
