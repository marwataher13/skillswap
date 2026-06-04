class CategoryModel {
  final int id;
  final String name;
  final int skillsCount;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.skillsCount,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as int,
      name: json['name'] as String,
      skillsCount: json['skills_count'] as int? ?? 0,
    );
  }

  @override
  String toString() => name;
}
