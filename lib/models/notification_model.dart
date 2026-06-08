class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String type;
  final bool read;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.read,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    // Resilient parsing to handle different backend responses
    final id = (json['id'] ?? json['_id'] ?? '').toString();
    final title = (json['title'] ?? '').toString();
    final message = (json['message'] ?? json['body'] ?? json['content'] ?? '').toString();
    final type = (json['type'] ?? 'info').toString();
    
    // Check various common read field names
    bool read = false;
    if (json.containsKey('read')) {
      read = json['read'] == true || json['read'] == 1;
    } else if (json.containsKey('is_read')) {
      read = json['is_read'] == true || json['is_read'] == 1;
    } else if (json.containsKey('read_at')) {
      read = json['read_at'] != null;
    }

    final createdAtStr = json['created_at'] ?? json['createdAt'] ?? '';
    final createdAt = DateTime.tryParse(createdAtStr) ?? DateTime.now();

    return NotificationModel(
      id: id,
      title: title,
      message: message,
      type: type,
      read: read,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type,
      'read': read,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
