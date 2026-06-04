class TimeSlotModel {
  final int id;
  final int userId;
  final String dayOfWeek;
  final String startTime;
  final String endTime;
  final bool isAvailable;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TimeSlotModel({
    required this.id,
    required this.userId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.isAvailable,
    this.createdAt,
    this.updatedAt,
  });

  factory TimeSlotModel.fromJson(Map<String, dynamic> json) {
    return TimeSlotModel(
      id: json['id'] as int? ?? 0,
      userId: json['user_id'] as int? ?? 0,
      dayOfWeek: json['day_of_week'] as String? ?? '',
      startTime: json['start_time'] as String? ?? '',
      endTime: json['end_time'] as String? ?? '',
      isAvailable: json['is_available'] as bool? ?? true,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'day_of_week': dayOfWeek,
    'start_time': startTime,
    'end_time': endTime,
    'is_available': isAvailable,
  };

  TimeSlotModel copyWith({
    int? id,
    int? userId,
    String? dayOfWeek,
    String? startTime,
    String? endTime,
    bool? isAvailable,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TimeSlotModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Day sort order for display
  static int dayOrder(String day) {
    const order = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final idx = order.indexOf(day);
    return idx == -1 ? 99 : idx;
  }
}
