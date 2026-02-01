import 'package:flutter/material.dart';

class RecordBook {
  final int id;
  // ... existing fields ...
  final int number; // Mapped from 'book_number'
  final String title; // Mapped from 'name'
  final int hijriYear;
  final String statusLabel;
  final String contractType; // Mapped from 'contract_type_name'
  final int totalPages;
  final int usedPages; // Mapped from 'constraints_count'
  final int usagePercentage; // Mapped from 'used_percentage'
  final String? categoryLabel; // New field for hierarchical grouping
  final bool isActive; // To distinguish current year's books
  final int totalEntries;
  final int completedEntries;
  final int draftEntries;
  final int notebooksCount;
  final int? contractTypeId; // Re-added for filtering
  
  // Specific fields for notebook details view
  final int bookNumber;
  final int entriesCount;
  final String? ministryRecordNumber;
  final int? templateId;
  final String? templateName;
  final int? issuanceYear;
  final List<int> years;

  RecordBook({
    this.id = 0,
    this.number = 0,
    this.title = '',
    this.hijriYear = 0,
    this.statusLabel = '',
    this.contractType = '',
    this.totalPages = 0,
    this.usedPages = 0,
    this.usagePercentage = 0,
    this.categoryLabel,
    this.isActive = false,
    this.totalEntries = 0,
    this.completedEntries = 0,
    this.draftEntries = 0,
    this.notebooksCount = 0,
    this.contractTypeId,
    // Initializing specific fields with defaults or required
    int? bookNumber,
    int? entriesCount,
    this.ministryRecordNumber,
    this.templateId,
    this.templateName,
    this.issuanceYear,
    List<int>? years,
  }) : 
    bookNumber = bookNumber ?? number,
    entriesCount = entriesCount ?? totalEntries,
    years = years ?? [];

  factory RecordBook.fromJson(Map<String, dynamic> json) {
    return RecordBook(
      id: json['id'] ?? 0,
      number: json['book_number'] ?? 0,
      title: json['name'] ?? '',
      hijriYear: json['hijri_year'] ?? 0,
      statusLabel: json['status_label'],
      contractType: json['contract_type_name'] ?? json['type_name'],
      totalPages: json['total_pages'] ?? 0,
      usedPages: json['constraints_count'] ?? 0,
      usagePercentage: json['used_percentage'] ?? 0,
      categoryLabel: json['category_label'],
      isActive: json['is_active'] == true || json['is_active'] == 1,
      totalEntries: json['total_entries_count'] ?? json['constraints_count'] ?? 0,
      completedEntries: json['completed_entries_count'] ?? 0,
      draftEntries: json['draft_entries_count'] ?? 0,
      notebooksCount: json['notebooks_count'] ?? 1,
      contractTypeId: json['contract_type_id'],
      
      // Map for specific notebook view if available
      bookNumber: json['book_number'] as int?,
      entriesCount: json['entries_count'] as int?,
      ministryRecordNumber: json['ministry_record_number'] as String?,
      templateId: json['template_id'] as int?,
      templateName: json['template_name'] as String?,
      issuanceYear: json['issuance_year'] as int?,
      years: (json['years'] as List<dynamic>?)?.map((e) => e as int).toList(),
    );
  }

  Color get statusColor {
    // Basic logic mapping status text to color
    if (statusLabel.contains('نشط') || statusLabel.contains('Active')) return Colors.green;
    if (statusLabel.contains('مكتمل') || statusLabel.contains('Full')) return Colors.blue;
    if (statusLabel.contains('ملغى') || statusLabel.contains('Cancelled')) return Colors.red;
    return Colors.grey;
  }
}
