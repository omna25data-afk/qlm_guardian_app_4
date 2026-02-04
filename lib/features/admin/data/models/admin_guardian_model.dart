import 'package:flutter/material.dart';

class AdminGuardian {
  final int id;
  final String name;
  final String serialNumber;
  final String? phone;
  final String? photoUrl;
  final String? employmentStatus;
  final String? employmentStatusColor;
  final String? licenseStatus;
  final String? licenseColor;
  final String? cardStatus;
  final String? cardColor;

  final String? firstName;
  final String? fatherName;
  final String? grandfatherName;
  final String? familyName;
  // Basic Extended
  final String? greatGrandfatherName;
  final String? birthDate;
  final String? birthPlace;
  final String? homePhone;
  
  // Identity
  final String? proofType;
  final String? proofNumber;
  final String? issuingAuthority;
  final String? issueDate;
  final String? expiryDate;

  // Professional
  final String? qualification;
  final String? job;
  final String? workplace;
  final String? experienceNotes;

  // Ministerial & License
  final String? ministerialDecisionNumber;
  final String? ministerialDecisionDate;
  final String? licenseNumber;
  final String? licenseIssueDate;
  final String? licenseExpiryDate;

  // Profession Card
  final String? professionCardNumber;
  final String? professionCardIssueDate;
  final String? professionCardExpiryDate;

  // Geographic
  final int? mainDistrictId;
  final String? mainDistrictName;
  final List<Map<String, dynamic>>? villages;
  final List<Map<String, dynamic>>? localities;

  // Status Extras
  final String? stopDate;
  final String? stopReason;
  final String? notes;

  // Renewals History
  final List<Map<String, dynamic>>? licenseRenewals;
  final List<Map<String, dynamic>>? cardRenewals;

  AdminGuardian({
    required this.id,
    required this.name,
    required this.serialNumber,
    this.phone,
    this.photoUrl,
    this.employmentStatus,
    this.employmentStatusColor,
    this.licenseStatus,
    this.licenseColor,
    this.cardStatus,
    this.cardColor,
    this.firstName,
    this.fatherName,
    this.grandfatherName,
    this.familyName,
    this.greatGrandfatherName,
    this.birthDate,
    this.birthPlace,
    this.homePhone,
    this.proofType,
    this.proofNumber,
    this.issuingAuthority,
    this.issueDate,
    this.expiryDate,
    this.qualification,
    this.job,
    this.workplace,
    this.experienceNotes,
    this.ministerialDecisionNumber,
    this.ministerialDecisionDate,
    this.licenseNumber,
    this.licenseIssueDate,
    this.licenseExpiryDate,
    this.professionCardNumber,
    this.professionCardIssueDate,
    this.professionCardExpiryDate,
    this.mainDistrictId,
    this.mainDistrictName,
    this.villages,
    this.localities,
    this.stopDate,
    this.stopReason,
    this.notes,
    this.licenseRenewals,
    this.cardRenewals,
  });

  factory AdminGuardian.fromJson(Map<String, dynamic> json) {
    return AdminGuardian(
      id: json['id'],
      name: json['name'] ?? '',
      serialNumber: json['serial_number'] ?? '',
      phone: json['phone'] ?? json['phone_number'], // Handle alias
      photoUrl: json['photo_url'],
      employmentStatus: json['employment_status'],
      employmentStatusColor: json['employment_status_color'],
      licenseStatus: json['license_status'],
      licenseColor: json['license_color'],
      cardStatus: json['card_status'],
      cardColor: json['card_color'],
      
      firstName: json['first_name'],
      fatherName: json['father_name'],
      grandfatherName: json['grandfather_name'],
      familyName: json['family_name'],
      greatGrandfatherName: json['great_grandfather_name'],
      
      birthDate: _formatDate(json['birth_date']),
      birthPlace: json['birth_place'],
      homePhone: json['home_phone'],

      proofType: json['proof_type'],
      proofNumber: json['proof_number'],
      issuingAuthority: json['issuing_authority'],
      issueDate: _formatDate(json['issue_date']),
      expiryDate: _formatDate(json['expiry_date']),

      qualification: json['qualification'],
      job: json['job'],
      workplace: json['workplace'],
      experienceNotes: json['experience_notes'],

      ministerialDecisionNumber: json['ministerial_decision_number'],
      ministerialDecisionDate: _formatDate(json['ministerial_decision_date']),
      licenseNumber: json['license_number'],
      licenseIssueDate: _formatDate(json['license_issue_date']),
      licenseExpiryDate: _formatDate(json['license_expiry_date']),

      professionCardNumber: json['profession_card_number'],
      professionCardIssueDate: _formatDate(json['profession_card_issue_date']),
      professionCardExpiryDate: _formatDate(json['profession_card_expiry_date']),

      mainDistrictId: json['main_district_id'],
      mainDistrictName: json['main_district_name'],
      villages: json['villages'] != null ? List<Map<String, dynamic>>.from(json['villages']) : [],
      localities: json['localities'] != null ? List<Map<String, dynamic>>.from(json['localities']) : [],
      
      stopDate: _formatDate(json['stop_date']),
      stopReason: json['stop_reason'],
      notes: json['notes'],
      
      licenseRenewals: json['license_renewals'] != null 
          ? List<Map<String, dynamic>>.from(json['license_renewals']) 
          : [],
      cardRenewals: json['card_renewals'] != null 
          ? List<Map<String, dynamic>>.from(json['card_renewals']) 
          : [],
    );
  }

  static String? _formatDate(String? date) {
    if (date == null || date.isEmpty) return null;
    try {
      final dt = DateTime.parse(date);
      return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
    } catch (e) {
      return date; // Fallback if parsing fails
    }
  }

  String get shortName {
    if (firstName != null && fatherName != null && familyName != null) {
      return "$firstName $fatherName $familyName";
    }
    return name;
  }

  // --- Status Helpers ---

  Color get identityStatusColor {
    return _getStatusColorFromDate(expiryDate);
  }

  Color get licenseStatusColor {
    // defined color from API or calc
    if (licenseColor != null) return _parseColor(licenseColor!);
    return _getStatusColorFromDate(licenseExpiryDate);
  }

  Color get cardStatusColor {
     if (cardColor != null) return _parseColor(cardColor!);
    return _getStatusColorFromDate(professionCardExpiryDate);
  }
  
  Color _getStatusColorFromDate(String? dateStr) {
    if (dateStr == null) return Colors.grey;
    try {
      final dt = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = dt.difference(now).inDays;

      if (difference < 0) return Colors.red;
      if (difference <= 30) return Colors.orange;
      return Colors.green;
    } catch (e) {
      return Colors.grey;
    }
  }

  Color _parseColor(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'danger':
      case 'red': return Colors.red;
      case 'warning':
      case 'orange': return Colors.orange;
      case 'success':
      case 'green': return Colors.green;
      case 'primary':
      case 'blue': return Colors.blue;
      default: return Colors.grey;
    }
  }
  // --- Remaining Days Helpers ---

  int? get identityRemainingDays => _getRemainingDays(expiryDate);
  int? get licenseRemainingDays => _getRemainingDays(licenseExpiryDate);
  int? get cardRemainingDays => _getRemainingDays(professionCardExpiryDate);

  int? _getRemainingDays(String? dateStr) {
    if (dateStr == null) return null;
    try {
      final dt = DateTime.parse(dateStr);
      final now = DateTime.now();
      return dt.difference(now).inDays;
    } catch (e) {
      return null;
    }
  }
}
