class PaginatedResponse<T> {
  final List<T> results;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  const PaginatedResponse({
    required this.results,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    List<T> results,
  ) {
    final pagination = json['pagination'] as Map<String, dynamic>? ?? json;
    
    int parseInt(dynamic value, int defaultValue) {
      if (value == null) return defaultValue;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString()) ?? defaultValue;
    }

    return PaginatedResponse<T>(
      results: results,
      currentPage: parseInt(pagination['current_page'] ?? pagination['currentPage'], 1),
      lastPage: parseInt(pagination['last_page'] ?? pagination['lastPage'], 1),
      perPage: parseInt(pagination['per_page'] ?? pagination['perPage'], 10),
      total: parseInt(pagination['total'], 0),
    );
  }
}
