class AdminAssignment {
  final int id;
  final String guardianName;
  final String areaName;
  final String type;
  final String typeText;
  final String? startDate;
  final String? endDate;
  final String status;
  final String statusColor;
  final String? notes;

  AdminAssignment({
    required this.id,
    required this.guardianName,
    required this.areaName,
    required this.type,
    required this.typeText,
    this.startDate,
    this.endDate,
    required this.status,
    required this.statusColor,
    this.notes,
  });

  factory AdminAssignment.fromJson(Map<String, dynamic> json) {
    return AdminAssignment(
      id: json['id'],
      guardianName: json['guardian_name'] ?? 'غيـر محدد',
      areaName: json['area_name'] ?? 'غيـر محدد',
      type: json['type'],
      typeText: json['type_text'],
      startDate: json['start_date'],
      endDate: json['end_date'],
      status: json['status'],
      statusColor: json['status_color'],
      notes: json['notes'],
    );
  }
}
