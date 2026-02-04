import 'package:flutter/material.dart';
import '../../../registry/data/models/registry_entry.dart';

class DashboardData {
  final String welcomeMessage;
  final String dateGregorian;
  final String dateHijri;
  final DashboardStats stats;
  final RenewalStatus licenseStatus;
  final RenewalStatus cardStatus;
  final List<RegistryEntry> recentActivities;
  final int unreadNotifications; // Keep simple int for now

  DashboardData({
    required this.welcomeMessage,
    required this.dateGregorian,
    required this.dateHijri,
    required this.stats,
    required this.licenseStatus,
    required this.cardStatus,
    required this.recentActivities,
    required this.unreadNotifications,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    final meta = json['meta'] ?? {};
    final statusSummary = json['status_summary'] ?? {};
    
    return DashboardData(
      welcomeMessage: meta['welcome_message'] ?? '',
      dateGregorian: meta['date_gregorian'] ?? '',
      dateHijri: meta['date_hijri'] ?? '',
      stats: DashboardStats.fromJson(json['stats'] ?? {}),
      licenseStatus: RenewalStatus.fromJson(statusSummary['license'] ?? {}),
      cardStatus: RenewalStatus.fromJson(statusSummary['card'] ?? {}),
      recentActivities: (json['recent_activities'] as List?)
          ?.map((e) => RegistryEntry.fromJson(e))
          .toList() ?? [],
      unreadNotifications: json['unread_notifications_count'] ?? 0,
    );
  }
}

class DashboardStats {
  final Map<String, int> registry;
  final Map<String, int> recordBooks;
  final int thisMonthEntries;

  DashboardStats({
    required this.registry,
    required this.recordBooks,
    required this.thisMonthEntries,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    // Determine if it's the new nested structure or old flat structure
    if (json.containsKey('registry_entries')) {
      final reg = json['registry_entries'] as Map<String, dynamic>? ?? {};
      final books = json['record_books'] as Map<String, dynamic>? ?? {};
      
      return DashboardStats(
        registry: reg.map((key, value) => MapEntry(key, (value as num).toInt())),
        recordBooks: books.map((key, value) => MapEntry(key, (value as num).toInt())),
        thisMonthEntries: json['this_month_entries'] ?? 0,
      );
    } else {
      // Backward compatibility
      return DashboardStats(
        registry: {
          'total': json['total_entries'] ?? 0,
          'draft': json['total_drafts'] ?? 0,
          'documented': json['total_documented'] ?? 0,
        },
        recordBooks: {},
        thisMonthEntries: json['this_month_entries'] ?? 0,
      );
    }
  }

  // Helpers for easier access
  int get totalEntries => registry['total'] ?? 0;
  int get draftEntries => registry['draft'] ?? 0;
  int get documentedEntries => registry['documented'] ?? 0;
  int get registeredGuardianEntries => registry['registered_guardian'] ?? 0;
  int get pendingDocumentationEntries => registry['pending_documentation'] ?? 0;

  int get totalRecordBooks => recordBooks['total'] ?? 0;
  int get activeRecordBooks => recordBooks['active'] ?? 0;
  int get closedRecordBooks => recordBooks['closed'] ?? 0;
  int get pendingRecordBooks => recordBooks['pending'] ?? 0;
}


class RenewalStatus {
  final String label;
  final String colorString;
  final String? expiryDateString;
  final int? daysRemaining;

  RenewalStatus({
    required this.label,
    required this.colorString,
    this.expiryDateString,
    this.daysRemaining,
  });

  factory RenewalStatus.fromJson(Map<String, dynamic> json) {
    return RenewalStatus(
      label: json['status_label'] ?? 'غير محدد',
      colorString: json['status_color'] ?? 'gray',
      expiryDateString: json['expiry_date'],
      daysRemaining: json['days_remaining'],
    );
  }

  // Parse color string to Color object
  Color get color {
    switch (colorString.toLowerCase()) {
      case 'success':
      case 'green':
        return Colors.green;
      case 'warning':
      case 'yellow':
      case 'orange':
        return Colors.orange;
      case 'danger':
      case 'red':
        return Colors.red;
      case 'primary':
      case 'blue':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  // Parse expiry date string to DateTime object
  DateTime? get expiryDate {
    if (expiryDateString == null) return null;
    try {
      return DateTime.parse(expiryDateString!);
    } catch (_) {
      return null;
    }
  }
}
