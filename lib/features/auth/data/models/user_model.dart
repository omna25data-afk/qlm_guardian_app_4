class User {
  final int id;
  final String name;
  final String phoneNumber; // Changed from email to phoneNumber
  final String? token;
  final bool isGuardian;
  final List<String> roles; // Added roles list
  // Guardian profile fields
  final int? guardianId;
  final String? guardianFullName;
  final String? avatarUrl;
  final String? registerNumber;
  final String? licenseStatus;
  final String? cardStatus;

  User({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.token,
    required this.isGuardian,
    required this.roles,
    this.guardianId,
    this.guardianFullName,
    this.avatarUrl,
    this.registerNumber,
    this.licenseStatus,
    this.cardStatus,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final userData = json['user'] ?? json;
    final guardianData = json['guardian'];
    
    return User(
      id: userData['id'],
      name: userData['name'],
      phoneNumber: userData['phone_number'] ?? '', // Map from phone_number
      token: json['access_token'] ?? json['token'],
      isGuardian: (userData['role_names'] as List?)?.contains('legitimate_guardian') ?? false,
      roles: (userData['role_names'] as List?)?.map((e) => e.toString()).toList() ?? [],
      // Guardian profile
      guardianId: guardianData?['id'],
      guardianFullName: guardianData?['full_name'],
      avatarUrl: guardianData?['avatar_url'],
      registerNumber: guardianData?['register_number']?.toString(),
      licenseStatus: guardianData?['license_status'],
      cardStatus: guardianData?['card_status'],
    );
  }
}

