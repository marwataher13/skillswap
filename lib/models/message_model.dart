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

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as int,
      conversationId: json['conversation_id'] as int? ?? 0,
      body: json['body'] as String? ?? '',
      isFromMe: json['is_from_me'] as bool? ?? false,
      sentAt:
          DateTime.tryParse(
            json['sent_at'] as String? ?? json['created_at'] as String? ?? '',
          ) ??
          DateTime.now(),
    );
  }
}
