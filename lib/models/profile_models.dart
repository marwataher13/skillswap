import 'package:flutter/foundation.dart';
import 'package:skillswap/config/app_config.dart';

/// Immutable data class representing the user's profile.
@immutable
class ProfileData {
  final String name;
  final String bio;
  final String phone;
  final String? avatarUrl;

  const ProfileData({
    required this.name,
    required this.bio,
    required this.phone,
    this.avatarUrl,
  });

  factory ProfileData.fromJson(Map<String, dynamic> json) {
    debugPrint('=== PROFILE FROM JSON ===');
    debugPrint('JSON: $json');

    // Auto-unwrap nested structure if present
    Map<String, dynamic> targetJson = json;
    if (json.containsKey('data') && json['data'] is Map) {
      targetJson = Map<String, dynamic>.from(json['data'] as Map);
    } else if (json.containsKey('user') && json['user'] is Map) {
      targetJson = Map<String, dynamic>.from(json['user'] as Map);
    } else if (json.containsKey('profile') && json['profile'] is Map) {
      targetJson = Map<String, dynamic>.from(json['profile'] as Map);
    }

    final avatarVal = targetJson['profile_picture'] ?? targetJson['avatar_url'] ?? targetJson['avatar'];
    String? resolvedAvatar;
    if (avatarVal is String) {
      resolvedAvatar = avatarVal;
    } else if (avatarVal is Map) {
      resolvedAvatar = avatarVal['profile_picture'] as String? ??
          avatarVal['avatar_url'] as String? ??
          avatarVal['url'] as String? ??
          avatarVal['path'] as String? ??
          avatarVal['file_url'] as String?;
    }

    if (resolvedAvatar != null && resolvedAvatar.isNotEmpty) {
      if (resolvedAvatar.startsWith('http')) {
        if (resolvedAvatar.contains('/profile_pictures/') && !resolvedAvatar.contains('/storage/profile_pictures/')) {
          resolvedAvatar = resolvedAvatar.replaceFirst('/profile_pictures/', '/storage/profile_pictures/');
        }
      } else {
        if (resolvedAvatar.startsWith('profile_pictures') && !resolvedAvatar.startsWith('storage/')) {
          resolvedAvatar = 'storage/$resolvedAvatar';
        }
        final baseUrlClean = AppConfig.baseUrl.endsWith('/')
            ? AppConfig.baseUrl.substring(0, AppConfig.baseUrl.length - 1)
            : AppConfig.baseUrl;
        final pathClean = resolvedAvatar.startsWith('/') ? resolvedAvatar : '/$resolvedAvatar';
        resolvedAvatar = '$baseUrlClean$pathClean';
      }
    }

    return ProfileData(
      name: targetJson['name'] as String? ?? '',
      bio: targetJson['bio'] as String? ?? '',
      phone: targetJson['phone'] as String? ?? '',
      avatarUrl: resolvedAvatar,
    );
  }

  Map<String, dynamic> toJson() {
    String? cleanUrl = avatarUrl;
    if (cleanUrl != null && cleanUrl.contains('?t=')) {
      cleanUrl = cleanUrl.split('?t=').first;
    } else if (cleanUrl != null && cleanUrl.contains('&t=')) {
      cleanUrl = cleanUrl.split('&t=').first;
    }
    return {
      'id': id,
      'name': name,
      'bio': bio,
      'phone': phone,
      'avatar_url': cleanUrl,
      'profile_picture': cleanUrl,
    };
  }

  ProfileData copyWith({
    int? id,
    String? name,
    String? bio,
    String? phone,
    String? avatarUrl,
    bool clearAvatar = false,
  }) {
    return ProfileData(
      id: id ?? this.id,
      name: name ?? this.name,
      bio: bio ?? this.bio,
      phone: phone ?? this.phone,
      avatarUrl: clearAvatar ? null : (avatarUrl ?? this.avatarUrl),
    );
  }
}

/// Supported portfolio file types.
enum FileType { image, pdf, word }

/// A single item in the portfolio grid.
class PortfolioItem {
  final String id;
  final String title;
  final FileType type;
  final String? fileUrl;

  const PortfolioItem({
    required this.id,
    required this.title,
    required this.type,
    this.fileUrl,
  });

  factory PortfolioItem.fromJson(Map<String, dynamic> json) {
    // Auto-unwrap nested structure if present
    Map<String, dynamic> targetJson = json;
    if (json.containsKey('data') && json['data'] is Map) {
      targetJson = Map<String, dynamic>.from(json['data'] as Map);
    } else if (json.containsKey('portfolio') && json['portfolio'] is Map) {
      targetJson = Map<String, dynamic>.from(json['portfolio'] as Map);
    } else if (json.containsKey('portfolio_file') && json['portfolio_file'] is Map) {
      targetJson = Map<String, dynamic>.from(json['portfolio_file'] as Map);
    } else if (json.containsKey('file') && json['file'] is Map && (json['file'] as Map).containsKey('id')) {
      targetJson = Map<String, dynamic>.from(json['file'] as Map);
    }

    final fileVal = targetJson['file'];
    String? resolvedUrl;
    if (fileVal is String) {
      resolvedUrl = fileVal;
    } else if (fileVal is Map) {
      resolvedUrl = fileVal['url'] as String? ??
          fileVal['path'] as String? ??
          fileVal['file_url'] as String?;
    }

    resolvedUrl ??= targetJson['file_url'] as String? ??
        targetJson['url'] as String? ??
        targetJson['path'] as String?;

    if (resolvedUrl != null && resolvedUrl.isNotEmpty) {
      if (resolvedUrl.startsWith('http')) {
        if ((resolvedUrl.contains('/profile_pictures/') || resolvedUrl.contains('/portfolio/')) &&
            !resolvedUrl.contains('/storage/profile_pictures/') && !resolvedUrl.contains('/storage/portfolio/')) {
          resolvedUrl = resolvedUrl.replaceFirst('/profile_pictures/', '/storage/profile_pictures/')
                                   .replaceFirst('/portfolio/', '/storage/portfolio/');
        }
      } else {
        if ((resolvedUrl.startsWith('profile_pictures') || resolvedUrl.startsWith('portfolio')) &&
            !resolvedUrl.startsWith('storage/')) {
          resolvedUrl = 'storage/$resolvedUrl';
        }
        final baseUrlClean = AppConfig.baseUrl.endsWith('/')
            ? AppConfig.baseUrl.substring(0, AppConfig.baseUrl.length - 1)
            : AppConfig.baseUrl;
        final pathClean = resolvedUrl.startsWith('/') ? resolvedUrl : '/$resolvedUrl';
        resolvedUrl = '$baseUrlClean$pathClean';
      }
    }

    final titleVal = targetJson['title'] ?? targetJson['name'] ?? targetJson['file_name'] ?? targetJson['original_name'];
    final titleString = titleVal?.toString().toLowerCase() ?? '';
    final typeString = (targetJson['type'] as String? ?? '').toLowerCase();
    final urlString = (resolvedUrl ?? '').toLowerCase();

    FileType resolvedType = FileType.image;
    if (typeString.contains('pdf') || titleString.endsWith('.pdf') || urlString.endsWith('.pdf') || urlString.contains('.pdf?')) {
      resolvedType = FileType.pdf;
    } else if (typeString.contains('word') || typeString.contains('doc') || typeString.contains('msword') || typeString.contains('officedocument') ||
        titleString.endsWith('.doc') || titleString.endsWith('.docx') ||
        urlString.endsWith('.doc') || urlString.endsWith('.docx') ||
        urlString.contains('.doc?') || urlString.contains('.docx?')) {
      resolvedType = FileType.word;
    } else {
      resolvedType = FileType.image;
    }

    return PortfolioItem(
      id: (targetJson['id'] ?? '').toString(),
      title: titleVal?.toString() ?? '',
      type: resolvedType,
      fileUrl: resolvedUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type.name,
      'file_url': fileUrl,
    };
  }
}