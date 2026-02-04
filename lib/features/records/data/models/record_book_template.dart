class RecordBookTemplate {
  final int id;
  final String name;
  final int totalPages;
  final int constraintsPerPage;
  final String? description;

  RecordBookTemplate({
    required this.id,
    required this.name,
    required this.totalPages,
    required this.constraintsPerPage,
    this.description,
  });

  factory RecordBookTemplate.fromJson(Map<String, dynamic> json) {
    return RecordBookTemplate(
      id: json['id'],
      name: json['name'] ?? '',
      totalPages: json['total_pages'] ?? 100,
      constraintsPerPage: json['constraints_per_page'] ?? 10,
      description: json['description'],
    );
  }
}
