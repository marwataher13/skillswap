class MessageModel {
  final int id;
  final int conversationId;
  final String body;
  final bool isFromMe;
  final DateTime sentAt;

  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.body,
    required this.isFromMe,
    required this.sentAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json, int currentUserId) {
    final senderId = int.tryParse(json['sender_id']?.toString() ?? '') ??
                     int.tryParse(json['sender']?['id']?.toString() ?? '') ?? 0;
    return MessageModel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      conversationId: int.tryParse(json['conversation_id']?.toString() ?? '') ?? 0,
      body: json['body'] as String? ?? '',
      isFromMe: senderId == currentUserId,
      sentAt:
          DateTime.tryParse(
            json['sent_at'] as String? ?? json['created_at'] as String? ?? '',
          ) ??
          DateTime.now(),
    );
  }
}
