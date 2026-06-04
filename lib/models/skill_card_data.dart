class SkillCardData {
  final int id;
  final String name;
  final String type;
  final String description;
  final String level;
  final String category;

  const SkillCardData({
    required this.id,
    required this.name,
    required this.type,
    required this.description,
    required this.level,
    required this.category,
  });

  factory SkillCardData.fromJson(Map<String, dynamic> json) {
    return SkillCardData(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      description: json['description'] ?? '',
      level: json['level'] ?? '',
      category: json['category']?['name'] ?? '',
    );
  }
}
