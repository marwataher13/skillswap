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
      id: json['id'] as int,
      otherUser: OtherUser.fromJson(json['other_user'] as Map<String, dynamic>),
      lastMessage: json['last_message'] != null
          ? LastMessage.fromJson(json['last_message'] as Map<String, dynamic>)
          : null,
      unreadCount: json['unread_count'] as int? ?? 0,
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
    return OtherUser(
      id: json['id'] as int,
      name: json['name'] as String? ?? 'Unknown',
      avatarUrl:
          json['avatar_url'] as String? ?? json['profile_photo_url'] as String?,
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
      isFromMe: json['is_from_me'] as bool? ?? false,
      sentAt:
          DateTime.tryParse(json['sent_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
