class ChatItemData {
  final String name;
  final String lastMessage;
  final String time;
  final int unreadCount;
  final String avatarUrl;

  const ChatItemData({
    required this.name,
    required this.lastMessage,
    required this.time,
    required this.unreadCount,
    required this.avatarUrl,
  });
}
