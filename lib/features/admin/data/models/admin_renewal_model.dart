class AdminRenewal {
  final int id;
  final String guardianName;
  final String renewalDate;
  final String status;
  final String statusColor;
  final String type;

  AdminRenewal({
    required this.id,
    required this.guardianName,
    required this.renewalDate,
    required this.status,
    required this.statusColor,
    required this.type,
  });

  factory AdminRenewal.fromJson(Map<String, dynamic> json) {
    return AdminRenewal(
      id: json['id'],
      guardianName: json['guardian_name'] ?? 'غير معروف',
      renewalDate: json['renewal_date'] ?? '',
      status: json['status'] ?? '',
      statusColor: json['status_color'] ?? 'grey',
      type: json['type'] ?? '',
    );
  }
}
