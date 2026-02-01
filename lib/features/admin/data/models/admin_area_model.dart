class AdminArea {
  final int id;
  final String name;
  final String type;
  final String? parentName;
  final int childrenCount;
  final int guardiansCount;
  final String color;
  final String icon;
  final bool isActive;

  AdminArea({
    required this.id,
    required this.name,
    required this.type,
    this.parentName,
    required this.childrenCount,
    required this.guardiansCount,
    required this.color,
    required this.icon,
    required this.isActive,
  });

  factory AdminArea.fromJson(Map<String, dynamic> json) {
    return AdminArea(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      parentName: json['parent_name'],
      childrenCount: json['children_count'] ?? 0,
      guardiansCount: json['guardians_count'] ?? 0,
      color: json['color'] ?? '#808080',
      icon: json['icon'] ?? '',
      isActive: json['is_active'] ?? false,
    );
  }
}
