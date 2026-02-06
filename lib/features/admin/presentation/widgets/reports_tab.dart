import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:guardian_app/core/constants/api_constants.dart';
import 'package:guardian_app/features/auth/data/repositories/auth_repository.dart';

/// شاشة التقارير والإحصائيات
class ReportsTab extends StatefulWidget {
  const ReportsTab({super.key});

  @override
  State<ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<ReportsTab> with SingleTickerProviderStateMixin {
  static const primaryColor = Color(0xFF006400);

  late TabController _tabController;
  bool _isLoading = true;

  // Data
  Map<String, dynamic>? _guardianStats;
  Map<String, dynamic>? _entriesStats;
  Map<String, dynamic>? _contractTypesStats;
  List<int> _availableYears = [];

  // Filters
  int? _selectedYear;
  String _periodType = 'annual';
  String? _periodValue;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final authRepo = Provider.of<AuthRepository>(context, listen: false);
      final token = await authRepo.getToken();

      // Load available years first
      if (_availableYears.isEmpty) {
        final yearsResponse = await http.get(
          Uri.parse('${ApiConstants.baseUrl}/reports/years'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
        if (yearsResponse.statusCode == 200) {
          final data = jsonDecode(utf8.decode(yearsResponse.bodyBytes));
          _availableYears = (data['years'] as List).cast<int>();
          _selectedYear ??= data['current'] as int?;
        }
      }

      // Build query params
      final params = <String, String>{};
      if (_selectedYear != null) {
        params['year'] = '$_selectedYear';
      }
      params['period_type'] = _periodType;
      if (_periodValue != null) {
        params['period_value'] = _periodValue!;
      }

      // Load all statistics in parallel
      final futures = await Future.wait([
        http.get(
          Uri.parse('${ApiConstants.baseUrl}/reports/guardian-statistics').replace(queryParameters: params),
          headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
        ),
        http.get(
          Uri.parse('${ApiConstants.baseUrl}/reports/entries-statistics').replace(queryParameters: params),
          headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
        ),
        http.get(
          Uri.parse('${ApiConstants.baseUrl}/reports/contract-types-summary?year=${_selectedYear ?? ''}'),
          headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
        ),
      ]);

      if (futures[0].statusCode == 200) {
        _guardianStats = jsonDecode(utf8.decode(futures[0].bodyBytes));
      }
      if (futures[1].statusCode == 200) {
        _entriesStats = jsonDecode(utf8.decode(futures[1].bodyBytes));
      }
      if (futures[2].statusCode == 200) {
        _contractTypesStats = jsonDecode(utf8.decode(futures[2].bodyBytes));
      }
    } catch (e) {
      debugPrint('Error loading reports: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في تحميل التقارير: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        children: [
          _buildFilters(),
          TabBar(
            controller: _tabController,
            labelColor: primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: primaryColor,
            labelStyle: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: 'إحصائيات القيود', icon: Icon(Icons.bar_chart)),
              Tab(text: 'تقارير الأمناء', icon: Icon(Icons.people)),
              Tab(text: 'أنواع العقود', icon: Icon(Icons.description)),
            ],
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: primaryColor))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildEntriesStatsTab(),
                      _buildGuardianStatsTab(),
                      _buildContractTypesTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with Export button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('تصفية النتائج', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 16)),
              IconButton(
                onPressed: _showExportOptions,
                icon: const Icon(Icons.download, color: primaryColor),
                tooltip: 'تصدير التقرير',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  label: 'السنة الهجرية',
                  value: _selectedYear,
                  items: _availableYears.map((y) => DropdownMenuItem(
                    value: y,
                    child: Text('$y هـ', style: GoogleFonts.tajawal()),
                  )).toList(),
                  onChanged: (v) {
                    setState(() => _selectedYear = v);
                    _loadData();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdown(
                  label: 'نوع الفترة',
                  value: _periodType,
                  items: [
                    DropdownMenuItem(value: 'annual', child: Text('سنوي', style: GoogleFonts.tajawal())),
                    DropdownMenuItem(value: 'semi_annual', child: Text('نصف سنوي', style: GoogleFonts.tajawal())),
                    DropdownMenuItem(value: 'quarterly', child: Text('ربع سنوي', style: GoogleFonts.tajawal())),
                  ],
                  onChanged: (v) {
                    setState(() {
                      _periodType = v ?? 'annual';
                      _periodValue = null;
                    });
                    _loadData();
                  },
                ),
              ),
            ],
          ),
          if (_periodType != 'annual') ...[
            const SizedBox(height: 12),
            _buildPeriodValueDropdown(),
          ],
        ],
      ),
    );
  }

  Widget _buildPeriodValueDropdown() {
    final items = _periodType == 'semi_annual'
        ? [
            const DropdownMenuItem(value: '1', child: Text('النصف الأول')),
            const DropdownMenuItem(value: '2', child: Text('النصف الثاني')),
          ]
        : [
            const DropdownMenuItem(value: 'Q1', child: Text('الربع الأول')),
            const DropdownMenuItem(value: 'Q2', child: Text('الربع الثاني')),
            const DropdownMenuItem(value: 'Q3', child: Text('الربع الثالث')),
            const DropdownMenuItem(value: 'Q4', child: Text('الربع الرابع')),
          ];

    return _buildDropdown(
      label: 'الفترة',
      value: _periodValue,
      items: items,
      onChanged: (v) {
        setState(() => _periodValue = v);
        _loadData();
      },
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.tajawal(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              hint: Text('اختر', style: GoogleFonts.tajawal()),
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  // ========== إحصائيات القيود ==========
  Widget _buildEntriesStatsTab() {
    if (_entriesStats == null) {
      return const Center(child: Text('لا توجد بيانات'));
    }

    final summary = _entriesStats!['summary'] as Map<String, dynamic>;
    final byType = _entriesStats!['by_contract_type'] as List? ?? [];

    return RefreshIndicator(
      onRefresh: _loadData,
      color: primaryColor,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Summary cards
          _buildSummaryCards(summary),
          const SizedBox(height: 24),

          // By contract type
          Text('توزيع حسب نوع العقد', style: GoogleFonts.tajawal(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...byType.map((item) => _buildContractTypeCard(item)),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(Map<String, dynamic> summary) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard('إجمالي القيود', '${summary['total']}', Icons.article, primaryColor),
        _buildStatCard('موثق', '${summary['documented']}', Icons.check_circle, Colors.green),
        _buildStatCard('مسودة', '${summary['draft']}', Icons.edit_note, Colors.orange),
        _buildStatCard('الرسوم', '${_formatAmount(summary['total_fees'])} ر.ي', Icons.attach_money, Colors.amber[700]!),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
            ],
          ),
          const Spacer(),
          Text(value, style: GoogleFonts.tajawal(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          Text(title, style: GoogleFonts.tajawal(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildContractTypeCard(Map<String, dynamic> item) {
    final count = item['count'] as int? ?? 0;
    final fees = (item['fees'] as num?)?.toDouble() ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text('$count', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, color: primaryColor)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['name'] ?? '', style: GoogleFonts.tajawal(fontWeight: FontWeight.w500)),
                Text('${_formatAmount(fees)} ر.ي', style: GoogleFonts.tajawal(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========== تقارير الأمناء ==========
  Widget _buildGuardianStatsTab() {
    if (_guardianStats == null) {
      return const Center(child: Text('لا توجد بيانات'));
    }

    final summary = _guardianStats!['summary'] as Map<String, dynamic>;
    final byGuardian = _guardianStats!['by_guardian'] as List? ?? [];

    return RefreshIndicator(
      onRefresh: _loadData,
      color: primaryColor,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Summary
          _buildGuardianSummary(summary),
          const SizedBox(height: 24),

          // Guardians list
          Text('تفصيل حسب الأمين', style: GoogleFonts.tajawal(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...byGuardian.map((g) => _buildGuardianCard(g)),
        ],
      ),
    );
  }

  Widget _buildGuardianSummary(Map<String, dynamic> summary) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, primaryColor.withValues(alpha: 0.8)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem('الأمناء', '${summary['guardians_count']}', Icons.people),
              _buildSummaryItem('القيود', '${summary['total_entries']}', Icons.article),
              _buildSummaryItem('الرسوم', _formatAmount(summary['total_fees']), Icons.attach_money),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 24),
        const SizedBox(height: 8),
        Text(value, style: GoogleFonts.tajawal(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(label, style: GoogleFonts.tajawal(fontSize: 12, color: Colors.white70)),
      ],
    );
  }

  Widget _buildGuardianCard(Map<String, dynamic> guardian) {
    final byType = guardian['by_type'] as Map<String, dynamic>? ?? {};

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: primaryColor.withValues(alpha: 0.1),
          child: Text(
            '${guardian['total_entries']}',
            style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, color: primaryColor),
          ),
        ),
        title: Text(guardian['name'] ?? '', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
        subtitle: Text(
          '${_formatAmount(guardian['total_fees'])} ر.ي',
          style: GoogleFonts.tajawal(fontSize: 12, color: Colors.grey),
        ),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (byType['marriage'] != 0) _buildTypeChip('زواج', byType['marriage']),
              if (byType['divorce'] != 0) _buildTypeChip('طلاق', byType['divorce']),
              if (byType['sale_immovable'] != 0) _buildTypeChip('غير منقول', byType['sale_immovable']),
              if (byType['sale_movable'] != 0) _buildTypeChip('منقول', byType['sale_movable']),
              if (byType['agency'] != 0) _buildTypeChip('وكالة', byType['agency']),
              if (byType['division'] != 0) _buildTypeChip('قسمة', byType['division']),
              if (byType['dispositions'] != 0) _buildTypeChip('تصرفات', byType['dispositions']),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(String label, dynamic count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$label: $count',
        style: GoogleFonts.tajawal(fontSize: 12, color: primaryColor, fontWeight: FontWeight.w500),
      ),
    );
  }

  // ========== أنواع العقود ==========
  Widget _buildContractTypesTab() {
    if (_contractTypesStats == null) {
      return const Center(child: Text('لا توجد بيانات'));
    }

    final contractTypes = _contractTypesStats!['contract_types'] as List? ?? [];
    final periods = _contractTypesStats!['periods'] as Map<String, dynamic>? ?? {};

    return RefreshIndicator(
      onRefresh: _loadData,
      color: primaryColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(primaryColor.withValues(alpha: 0.1)),
            columns: [
              DataColumn(label: Text('نوع العقد', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('سنوي', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('ن1', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('ن2', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('ر1', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('ر2', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('ر3', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('ر4', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold))),
            ],
            rows: contractTypes.map<DataRow>((ct) {
              final id = '${ct['id']}';
              return DataRow(cells: [
                DataCell(Text(ct['name'] ?? '', style: GoogleFonts.tajawal())),
                DataCell(Text('${_getPeriodCount(periods, 'annual', id)}', style: GoogleFonts.tajawal())),
                DataCell(Text('${_getPeriodCount(periods, 'h1', id)}', style: GoogleFonts.tajawal())),
                DataCell(Text('${_getPeriodCount(periods, 'h2', id)}', style: GoogleFonts.tajawal())),
                DataCell(Text('${_getPeriodCount(periods, 'q1', id)}', style: GoogleFonts.tajawal())),
                DataCell(Text('${_getPeriodCount(periods, 'q2', id)}', style: GoogleFonts.tajawal())),
                DataCell(Text('${_getPeriodCount(periods, 'q3', id)}', style: GoogleFonts.tajawal())),
                DataCell(Text('${_getPeriodCount(periods, 'q4', id)}', style: GoogleFonts.tajawal())),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }

  int _getPeriodCount(Map<String, dynamic> periods, String period, String typeId) {
    final periodData = periods[period] as Map<String, dynamic>?;
    if (periodData == null) return 0;
    final typeData = periodData[typeId] as Map<String, dynamic>?;
    return typeData?['count'] as int? ?? 0;
  }

  String _formatAmount(dynamic amount) {
    if (amount == null) return '0';
    final num = (amount is int) ? amount.toDouble() : (amount as double);
    if (num >= 1000000) {
      return '${(num / 1000000).toStringAsFixed(1)} مليون';
    } else if (num >= 1000) {
      return '${(num / 1000).toStringAsFixed(1)} ألف';
    }
    return num.toStringAsFixed(0);
  }

  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('تصدير التقرير', style: GoogleFonts.tajawal(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.table_chart, color: Colors.green),
              title: Text('ملف Excel', style: GoogleFonts.tajawal()),
              onTap: () {
                Navigator.pop(context);
                _downloadAndShareReport('excel');
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: Text('ملف PDF', style: GoogleFonts.tajawal()),
              onTap: () {
                Navigator.pop(context);
                _downloadAndShareReport('pdf');
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadAndShareReport(String format) async {
    setState(() => _isLoading = true);
    try {
      final authRepo = Provider.of<AuthRepository>(context, listen: false);
      final token = await authRepo.getToken();

      final params = <String, String>{
        'format': format,
        'type': 'guardian', // Using guardian stats as base
        'year': '${_selectedYear}',
        'period_type': _periodType,
        if (_periodValue != null) 'period_value': _periodValue!,
      };

      final uri = Uri.parse('${ApiConstants.baseUrl}/reports/export').replace(queryParameters: params);

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json', // Backend handles format via query param, but basic accept is good
        },
      );

      if (response.statusCode == 200) {
        final dir = await getApplicationDocumentsDirectory();
        final ext = format == 'pdf' ? 'pdf' : 'xlsx';
        final filename = 'report_${DateTime.now().millisecondsSinceEpoch}.$ext';
        final file = File('${dir.path}/$filename');
        
        await file.writeAsBytes(response.bodyBytes);
        
        if (mounted) {
           await Share.shareXFiles([XFile(file.path)], text: 'تقرير الإحصائيات');
        }
      } else {
        throw Exception('Failed to download: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Export error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل التصدير: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
