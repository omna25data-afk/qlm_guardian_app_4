import 'package:flutter/material.dart';

class AdminDashboardData {
  final AdminStats stats;
  final List<UrgentAction> urgentActions;
  // logs can be added later

  AdminDashboardData({
    required this.stats,
    required this.urgentActions,
  });

  factory AdminDashboardData.fromJson(Map<String, dynamic> json) {
    return AdminDashboardData(
      stats: AdminStats.fromJson(json['stats'] ?? {}),
      urgentActions: (json['urgent_actions'] as List?)
              ?.map((e) => UrgentAction.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class AdminStats {
  final StatCategory guardians;
  final StatCategory licenses;
  final StatCategory cards;

  AdminStats({
    required this.guardians,
    required this.licenses,
    required this.cards,
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) {
    return AdminStats(
      guardians: StatCategory.fromJson(json['guardians'] ?? {}),
      licenses: StatCategory.fromJson(json['licenses'] ?? {}),
      cards: StatCategory.fromJson(json['cards'] ?? {}),
    );
  }
}

class StatCategory {
  final int total;
  final int active;
  final int inactive; // generic for stopped/expired
  final int warning; // generic for expiring

  StatCategory({
    required this.total,
    required this.active,
    required this.inactive,
    required this.warning,
  });

  factory StatCategory.fromJson(Map<String, dynamic> json) {
    return StatCategory(
      total: json['total'] ?? 0,
      active: json['active'] ?? 0,
      // Map 'stopped' (guardians) or 'expired' (licenses/cards) to 'inactive'
      inactive: (json['stopped'] ?? json['expired']) ?? 0,
       // Map 'expiring' to 'warning'
      warning: json['expiring'] ?? 0,
    );
  }
}

class UrgentAction {
  final String type;
  final String title;
  final String subtitle;
  final String actionLabel;
  final String bgColorString;

  UrgentAction({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.bgColorString,
  });

  factory UrgentAction.fromJson(Map<String, dynamic> json) {
    return UrgentAction(
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      actionLabel: json['action_label'] ?? '',
      bgColorString: json['bg_color'] ?? 'red',
    );
  }

  Color get color {
    switch (bgColorString.toLowerCase()) {
      case 'red': return Colors.red;
      case 'orange': return Colors.orange;
      case 'blue': return Colors.blue;
      default: return Colors.grey;
    }
  }
}
