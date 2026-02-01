import 'package:flutter/material.dart';

class RegistryEntry {
  final int? id;
  final int? serialNumber;
  final String statusLabel;
  final String firstParty;
  final String secondParty;
  final String contractType;
  final String dateHijri;
  final String dateGregorian;
  final double totalFees;
  final int? hijriYear;
  final String? deliveryStatusLabel;
  final String? statusColorStr;
  final String? deliveryStatusColorStr;

  RegistryEntry({
    this.id,
    this.serialNumber,
    required this.statusLabel,
    required this.firstParty,
    required this.secondParty,
    required this.contractType,
    required this.dateHijri,
    required this.dateGregorian,
    this.hijriYear,
    required this.totalFees,
    this.deliveryStatusLabel,
    this.statusColorStr,
    this.deliveryStatusColorStr,
  });

  factory RegistryEntry.fromJson(Map<String, dynamic> json) {
    // Handle flattened or nested structures if API varies
    final contract = json['contract_type'] ?? {};
    final dates = json['document_date'] ?? {};
    final fees = json['fees'] ?? {};

    return RegistryEntry(
      id: json['id'],
      serialNumber: json['serial_number'],
      hijriYear: json['hijri_year'],
      statusLabel: json['status_label'] ?? '',
      statusColorStr: json['status_color'], // Parsing backend color
      deliveryStatusLabel: json['delivery_status_label'],
      deliveryStatusColorStr: json['delivery_status_color'],
      firstParty: json['first_party_name'] ?? '',
      secondParty: json['second_party_name'] ?? '',
      contractType: contract['name'] ?? json['contract_type_name'] ?? '',
      dateHijri: dates['hijri'] ?? json['hijri_date'] ?? '',
      dateGregorian: dates['gregorian'] ?? json['document_gregorian_date'] ?? '',
      totalFees: (fees['total'] ?? json['fee_amount'] ?? 0).toDouble(),
    );
  }

  Color get statusColor {
    return _mapColor(statusColorStr) ?? _mapColorByLabel(statusLabel) ?? Colors.grey;
  }

  Color get deliveryStatusColor {
    return _mapColor(deliveryStatusColorStr) ?? Colors.blueGrey;
  }

  Color? _mapColor(String? colorStr) {
    if (colorStr == null) return null;
    if (colorStr == 'success' || colorStr == 'green') return Colors.green;
    if (colorStr == 'warning' || colorStr == 'amber' || colorStr == 'orange') return Colors.orange;
    if (colorStr == 'danger' || colorStr == 'red') return Colors.red;
    if (colorStr == 'info' || colorStr == 'blue') return Colors.blue;
    if (colorStr == 'gray') return Colors.grey;
    return null;
  }

  Color? _mapColorByLabel(String label) {
    if (label.contains('مسودة') || label.contains('Draft')) return Colors.orange;
    if (label.contains('معتمد') || label.contains('Approved')) return Colors.green;
    return null;
  }
}
