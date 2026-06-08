import 'package:skillswap/config/app_config.dart';

class ConversationModel {
  final int id;
  final OtherUser otherUser;
  final LastMessage? lastMessage;
  final int unreadCount;
  final DateTime updatedAt;

  const ConversationModel({
    required this.id,
    required this.otherUser,
    this.lastMessage,
    required this.unreadCount,
    required this.updatedAt,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      otherUser: OtherUser.fromJson(
        (json['other_user'] ?? <String, dynamic>{}) as Map<String, dynamic>,
      ),
      lastMessage: json['last_message'] != null
          ? LastMessage.fromJson(json['last_message'] as Map<String, dynamic>)
          : null,
      unreadCount: int.tryParse(json['unread_count']?.toString() ?? '') ?? 0,
      updatedAt:
          DateTime.tryParse(json['updated_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class OtherUser {
  final int id;
  final String name;
  final String? avatarUrl;

  const OtherUser({required this.id, required this.name, this.avatarUrl});

  factory OtherUser.fromJson(Map<String, dynamic> json) {
    final avatarVal = json['avatar_url'] as String? ?? json['profile_photo_url'] as String?;
    String? resolvedAvatar = avatarVal;
    if (resolvedAvatar != null && resolvedAvatar.isNotEmpty && !resolvedAvatar.startsWith('http')) {
      final baseUrlClean = AppConfig.baseUrl.endsWith('/')
          ? AppConfig.baseUrl.substring(0, AppConfig.baseUrl.length - 1)
          : AppConfig.baseUrl;
      final pathClean = resolvedAvatar.startsWith('/') ? resolvedAvatar : '/$resolvedAvatar';
      resolvedAvatar = '$baseUrlClean$pathClean';
    }
    return OtherUser(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name'] as String? ?? 'Unknown',
      avatarUrl: resolvedAvatar,
    );
  }

  /// Returns initials for avatar fallback (e.g. "John Doe" → "JD")
  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}

class LastMessage {
  final String body;
  final bool isFromMe;
  final DateTime sentAt;

  const LastMessage({
    required this.body,
    required this.isFromMe,
    required this.sentAt,
  });

  factory LastMessage.fromJson(Map<String, dynamic> json) {
    return LastMessage(
      body: json['body'] as String? ?? '',
      isFromMe: json['is_from_me'] == true || json['is_from_me'] == 1 || json['is_from_me']?.toString() == 'true',
      sentAt:
          DateTime.tryParse(json['sent_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
