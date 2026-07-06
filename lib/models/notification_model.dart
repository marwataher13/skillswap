class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String type;
  final bool read;
  final DateTime createdAt;
  final Map<String, dynamic> payload;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.read,
    required this.createdAt,
    this.payload = const {},
  });

  NotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    String? type,
    bool? read,
    DateTime? createdAt,
    Map<String, dynamic>? payload,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      read: read ?? this.read,
      createdAt: createdAt ?? this.createdAt,
      payload: payload ?? this.payload,
    );
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] ?? json['_id'] ?? '').toString();
    final title = (json['title'] ?? '').toString();
    final message =
        (json['message'] ?? json['body'] ?? json['content'] ?? '').toString();
    final type = (json['type'] ?? 'info').toString();

    bool read = false;
    if (json.containsKey('read')) {
      read = json['read'] == true || json['read'] == 1;
    } else if (json.containsKey('is_read')) {
      read = json['is_read'] == true || json['is_read'] == 1;
    } else if (json.containsKey('read_at')) {
      read = json['read_at'] != null;
    }

    final createdAtStr = json['created_at'] ?? json['createdAt'] ?? '';
    final createdAt = DateTime.tryParse(createdAtStr.toString()) ?? DateTime.now();

    final dynamic rawPayload = json['data'];
    final Map<String, dynamic> payload =
        rawPayload is Map<String, dynamic> ? rawPayload : {};

    return NotificationModel(
      id: id,
      title: title,
      message: message,
      type: type,
      read: read,
      createdAt: createdAt,
      payload: payload,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'message': message,
        'type': type,
        'read': read,
        'created_at': createdAt.toIso8601String(),
        'data': payload,
      };
}
