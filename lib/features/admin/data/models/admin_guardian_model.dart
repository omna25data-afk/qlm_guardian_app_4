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

  // Status Extras
  final String? stopDate;
  final String? stopReason;
  final String? notes;

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
    this.stopDate,
    this.stopReason,
    this.notes,
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
      
      birthDate: json['birth_date'],
      birthPlace: json['birth_place'],
      homePhone: json['home_phone'],

      proofType: json['proof_type'],
      proofNumber: json['proof_number'],
      issuingAuthority: json['issuing_authority'],
      issueDate: json['issue_date'],
      expiryDate: json['expiry_date'],

      qualification: json['qualification'],
      job: json['job'],
      workplace: json['workplace'],
      experienceNotes: json['experience_notes'],

      ministerialDecisionNumber: json['ministerial_decision_number'],
      ministerialDecisionDate: json['ministerial_decision_date'],
      licenseNumber: json['license_number'],
      licenseIssueDate: json['license_issue_date'],
      licenseExpiryDate: json['license_expiry_date'],

      professionCardNumber: json['profession_card_number'],
      professionCardIssueDate: json['profession_card_issue_date'],
      professionCardExpiryDate: json['profession_card_expiry_date'],

      mainDistrictId: json['main_district_id'],
      
      stopDate: json['stop_date'],
      stopReason: json['stop_reason'],
      notes: json['notes'],
    );
  }
}
