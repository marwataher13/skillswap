import 'package:skillswap/utils/url_utils.dart';

class ConversationModel {
  final int id;
  final OtherUser otherUser;
  final LastMessage? lastMessage;
  final int unreadMessagesCount;
  final DateTime updatedAt;

  const ConversationModel({
    required this.id,
    required this.otherUser,
    this.lastMessage,
    int? unreadMessagesCount,
    int? unreadCount,
    required this.updatedAt,
  }) : unreadMessagesCount = unreadMessagesCount ?? unreadCount ?? 0;

  int get unreadCount => (unreadMessagesCount as int?) ?? 0;

  ConversationModel copyWith({
    int? id,
    OtherUser? otherUser,
    LastMessage? lastMessage,
    int? unreadMessagesCount,
    int? unreadCount,
    DateTime? updatedAt,
  }) {
    return ConversationModel(
      id: id ?? this.id,
      otherUser: otherUser ?? this.otherUser,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadMessagesCount: unreadMessagesCount ?? unreadCount ?? (this.unreadMessagesCount as int?) ?? 0,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory ConversationModel.fromJson(
      Map<String, dynamic> json, int currentUserId) {
    final userOneId =
        int.tryParse(json['user_one_id']?.toString() ?? '') ?? 0;
    final userOneMap = json['user_one'] as Map<String, dynamic>? ?? {};
    final userTwoMap = json['user_two'] as Map<String, dynamic>? ?? {};
    final otherUserMap =
        (currentUserId == userOneId) ? userTwoMap : userOneMap;
    final otherUser = OtherUser.fromJson(otherUserMap);

    LastMessage? lastMsg;
    if (json['last_message'] != null) {
      lastMsg = LastMessage.fromJson(
          json['last_message'] as Map<String, dynamic>, currentUserId);
    } else if (json['messages'] is List &&
        (json['messages'] as List).isNotEmpty) {
      final msgsList = json['messages'] as List;
      var latestJson = msgsList.first as Map<String, dynamic>;
      var latestTime = _parseDate(latestJson);

      for (var i = 1; i < msgsList.length; i++) {
        final currentJson = msgsList[i] as Map<String, dynamic>;
        final currentTime = _parseDate(currentJson);
        if (currentTime.isAfter(latestTime)) {
          latestTime = currentTime;
          latestJson = currentJson;
        }
      }
      lastMsg = LastMessage.fromJson(latestJson, currentUserId);
    }

    final computedUnread = _computeUnreadCount(json, currentUserId);

    return ConversationModel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      otherUser: otherUser,
      lastMessage: lastMsg,
      unreadMessagesCount: computedUnread,
      updatedAt:
          DateTime.tryParse(json['updated_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  static DateTime _parseDate(Map<String, dynamic> json) =>
      DateTime.tryParse(
          json['sent_at']?.toString() ?? json['created_at']?.toString() ?? '') ??
      DateTime.fromMillisecondsSinceEpoch(0);

  static int _computeUnreadCount(
      Map<String, dynamic> json, int currentUserId) {
    if (json['unreadMessagesCount'] != null) {
      return int.tryParse(json['unreadMessagesCount'].toString()) ?? 0;
    }
    if (json['unread_messages_count'] != null) {
      return int.tryParse(json['unread_messages_count'].toString()) ?? 0;
    }
    if (json['unread_count'] != null) {
      return int.tryParse(json['unread_count'].toString()) ?? 0;
    }
    if (json['unreadCount'] != null) {
      return int.tryParse(json['unreadCount'].toString()) ?? 0;
    }
    if (json['messages'] is List) {
      return (json['messages'] as List).where((m) {
        if (m is! Map) return false;
        final msgMap = Map<String, dynamic>.from(m);
        final senderId =
            int.tryParse(msgMap['sender_id']?.toString() ?? '') ??
            int.tryParse(
                msgMap['sender']?['id']?.toString() ?? '') ??
            0;
        final isRead = msgMap['is_read'] == 1 ||
            msgMap['is_read'] == true ||
            msgMap['is_read']?.toString() == 'true';
        return senderId != currentUserId && !isRead;
      }).length;
    }
    return 0;
  }
}

class OtherUser {
  final int id;
  final String name;
  final String username;
  final String? avatarUrl;

  const OtherUser({required this.id, required this.name, this.username = '', this.avatarUrl});

  factory OtherUser.fromJson(Map<String, dynamic> json) {
    final raw = json['profile_picture'] ??
        json['avatar_url'] ??
        json['profile_photo_url'] ??
        json['avatar'];

    final resolvedAvatar = resolveAvatarUrl(raw);

    return OtherUser(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name'] as String? ?? 'Unknown',
      username: json['username']?.toString() ?? '',
      avatarUrl: resolvedAvatar,
    );
  }

  /// Two-letter initials for avatar fallback (e.g. "John Doe" → "JD").
  String get initials => initialsOf(name);
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

  factory LastMessage.fromJson(
      Map<String, dynamic> json, int currentUserId) {
    final senderId =
        int.tryParse(json['sender_id']?.toString() ?? '') ??
        int.tryParse(json['sender']?['id']?.toString() ?? '') ??
        0;
    return LastMessage(
      body: json['body'] as String? ?? '',
      isFromMe: senderId == currentUserId,
      sentAt: DateTime.tryParse(
              json['sent_at'] as String? ??
              json['created_at'] as String? ??
              '') ??
          DateTime.now(),
    );
  }
}
