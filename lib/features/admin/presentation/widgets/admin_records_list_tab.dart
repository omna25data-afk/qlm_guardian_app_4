import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:guardian_app/core/constants/api_constants.dart';
import 'package:guardian_app/features/auth/data/repositories/auth_repository.dart';

/// تبويب السجلات للإدارة - يعتمد على جدول القيود المركزي
class AdminRecordsListTab extends StatefulWidget {
  const AdminRecordsListTab({super.key});

  @override
  State<AdminRecordsListTab> createState() => _AdminRecordsListTabState();
}

class _AdminRecordsListTabState extends State<AdminRecordsListTab> {
  static const primaryColor = Color(0xFF006400);
  
  // State
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  static const int _perPage = 50; // تحميل 50 في كل مرة حتى 300
  static const int _maxRecords = 300;
  
  // Data
  List<Map<String, dynamic>> _records = [];
  List<Map<String, dynamic>> _contractTypes = [];
  List<Map<String, dynamic>> _recordBookTypes = [];
  List<Map<String, dynamic>> _guardians = [];
  
  // Filters
  String _searchQuery = '';
  int? _yearFilter;
  int? _contractTypeFilter;
  int? _recordBookTypeFilter;
  int? _guardianFilter;
  String _sortBy = 'document_date';
  bool _sortAsc = false;
  
  // Grouping
  String _groupBy = 'none'; // none, guardian, contract_type, book_number
  
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMore && _records.length < _maxRecords) {
        _loadMore();
      }
    }
  }

  Future<void> _loadData({bool reset = true}) async {
    if (reset) {
      setState(() {
        _isLoading = true;
        _currentPage = 1;
        _hasMore = true;
        _records.clear();
      });
    }

    try {
      final authRepo = Provider.of<AuthRepository>(context, listen: false);
      final token = await authRepo.getToken();

      // Build query params
      final params = <String, String>{
        'page': '$_currentPage',
        'per_page': '$_perPage',
        'sort_by': _sortBy,
        'sort_order': _sortAsc ? 'asc' : 'desc',
      };
      
      if (_yearFilter != null) {
        params['hijri_year'] = '$_yearFilter';
      }
      if (_contractTypeFilter != null) {
        params['contract_type_id'] = '$_contractTypeFilter';
      }
      if (_recordBookTypeFilter != null) {
        params['record_book_type_id'] = '$_recordBookTypeFilter';
      }
      if (_guardianFilter != null) {
        params['guardian_id'] = '$_guardianFilter';
      }
      if (_searchQuery.isNotEmpty) {
        params['search'] = _searchQuery;
      }

      final uri = Uri.parse('${ApiConstants.baseUrl}/admin/record-books').replace(queryParameters: params);

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      // Load contract types (once)
      if (_contractTypes.isEmpty) {
        final typesResponse = await http.get(
          Uri.parse(ApiConstants.contractTypes),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
        if (typesResponse.statusCode == 200) {
          final data = jsonDecode(utf8.decode(typesResponse.bodyBytes));
          _contractTypes = (data as List).cast<Map<String, dynamic>>();
        }
      }

      // Load guardians (once)
      if (_guardians.isEmpty) {
        final guardiansResponse = await http.get(
          Uri.parse('${ApiConstants.baseUrl}/admin/guardians?per_page=100'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
        if (guardiansResponse.statusCode == 200) {
          final data = jsonDecode(utf8.decode(guardiansResponse.bodyBytes));
          final list = data['data'] as List? ?? data as List? ?? [];
          _guardians = list.cast<Map<String, dynamic>>();
        }
      }

      // Load record book types (once)
      if (_recordBookTypes.isEmpty) {
        final typesResponse = await http.get(
          Uri.parse('${ApiConstants.baseUrl}/record-book-types'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
        if (typesResponse.statusCode == 200) {
          final data = jsonDecode(utf8.decode(typesResponse.bodyBytes));
          final list = data['data'] as List? ?? data as List? ?? [];
          _recordBookTypes = list.cast<Map<String, dynamic>>();
        }
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final recordsList = data['data'] as List? ?? [];
        
        if (reset) {
          _records = recordsList.cast<Map<String, dynamic>>();
        } else {
          _records.addAll(recordsList.cast<Map<String, dynamic>>());
        }

        // Check if more available
        final meta = data['meta'] as Map<String, dynamic>?;
        final lastPage = meta?['last_page'] ?? 1;
        _hasMore = _currentPage < lastPage && _records.length < _maxRecords;
      }
    } catch (e) {
      debugPrint('Error loading records: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في تحميل البيانات: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore || _records.length >= _maxRecords) return;
    
    setState(() => _isLoadingMore = true);
    _currentPage++;
    await _loadData(reset: false);
  }

  Map<String, List<Map<String, dynamic>>> _getGroupedRecords() {
    if (_groupBy == 'none') {
      return {'الكل': _records};
    }

    final grouped = <String, List<Map<String, dynamic>>>{};
    
    for (final record in _records) {
      String key;
      switch (_groupBy) {
        case 'guardian':
          key = record['guardian']?['name'] ?? record['writer_name'] ?? 'غير محدد';
        case 'contract_type':
          key = record['contract_type']?['name'] ?? record['contract_type_name'] ?? 'غير محدد';
        case 'book_number':
          key = 'دفتر رقم ${record['guardian_record_book_number'] ?? 'غير محدد'}';
        default:
          key = 'الكل';
      }
      
      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(record);
    }

    return grouped;
  }

  List<int> _getAvailableYears() {
    final years = _records
        .map((r) => r['hijri_year'] as int?)
        .whereType<int>()
        .toSet()
        .toList();
    years.sort((a, b) => b.compareTo(a));
    return years;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        children: [
          _buildHeader(),
          _buildToolbar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: primaryColor))
                : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final totalCount = _records.length;
    // For Record Books, maybe sum total pages or entries count?
    final totalEntries = _records.fold<int>(
      0, (sum, r) => sum + ((r['guardian_entries_count'] ?? 0) as int)
    );
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor.withValues(alpha: 0.1), Colors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.article_outlined,
              title: 'إجمالي القيود',
              value: '$totalCount',
              color: primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.attach_money,
              title: 'إجمالي القيود في السجلات',
              value: '$totalEntries',
              color: Colors.amber[700]!,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.tajawal(fontSize: 11, color: Colors.grey[600])),
                Text(value, style: GoogleFonts.tajawal(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) {
                    _searchQuery = v;
                    _loadData();
                  },
                  decoration: InputDecoration(
                    hintText: 'بحث برقم الدفتر أو اسم الأمين...',
                    hintStyle: GoogleFonts.tajawal(color: Colors.grey),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: primaryColor),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Issue Book Button
              ElevatedButton.icon(
                onPressed: () {
                   // Open Issue Sheet
                   // showModalBottomSheet(context: context, builder: (_) => const IssueRecordBookSheet());
                   // For now placeholder
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('سيتم إضافة شاشة صرف السجل قريباً')));
                },
                icon: const Icon(Icons.add_box, size: 20),
                label: Text('صرف سجل', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Action buttons
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildActionChip(
                  icon: Icons.filter_list,
                  label: 'تصفية',
                  isActive: _yearFilter != null || _contractTypeFilter != null || _guardianFilter != null,
                  activeColor: primaryColor,
                  onTap: _showFilterSheet,
                ),
                const SizedBox(width: 8),
                _buildActionChip(
                  icon: Icons.group_work,
                  label: 'تجميع: ${_getGroupLabel()}',
                  isActive: _groupBy != 'none',
                  activeColor: Colors.purple,
                  onTap: _showGroupSheet,
                ),
                const SizedBox(width: 8),
                _buildActionChip(
                  icon: Icons.sort,
                  label: 'ترتيب',
                  isActive: _sortBy != 'document_date',
                  activeColor: Colors.blue,
                  onTap: _showSortSheet,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getGroupLabel() {
    return switch (_groupBy) {
      'guardian' => 'الأمين',
      'contract_type' => 'نوع العقد',
      'book_number' => 'رقم الدفتر',
      _ => 'بدون',
    };
  }

  Widget _buildActionChip({
    required IconData icon,
    required String label,
    required bool isActive,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withValues(alpha: 0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isActive ? activeColor.withValues(alpha: 0.3) : Colors.grey.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: isActive ? activeColor : Colors.grey[600]),
            const SizedBox(width: 6),
            Text(label, style: GoogleFonts.tajawal(
              fontSize: 13,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color: isActive ? activeColor : Colors.grey[700],
            )),
            if (isActive) ...[
              const SizedBox(width: 4),
              Container(width: 6, height: 6, decoration: BoxDecoration(color: activeColor, shape: BoxShape.circle)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_records.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_off_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('لا توجد قيود', style: GoogleFonts.tajawal(fontSize: 18, color: Colors.grey[600])),
          ],
        ),
      );
    }

    final groupedRecords = _getGroupedRecords();

    return RefreshIndicator(
      onRefresh: () => _loadData(),
      color: primaryColor,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: groupedRecords.length + (_hasMore && _records.length < _maxRecords ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == groupedRecords.length) {
            // Load more button
            return _buildLoadMoreButton();
          }
          
          final groupKey = groupedRecords.keys.elementAt(index);
          final groupRecords = groupedRecords[groupKey]!;
          
          if (_groupBy == 'none') {
            return Column(
              children: groupRecords.map((r) => _buildRecordCard(r)).toList(),
            );
          }
          
          return _buildGroupSection(groupKey, groupRecords);
        },
      ),
    );
  }

  Widget _buildLoadMoreButton() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: _isLoadingMore
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : ElevatedButton.icon(
              onPressed: _loadMore,
              icon: const Icon(Icons.expand_more),
              label: Text('تحميل المزيد (${_records.length}/$_maxRecords)', style: GoogleFonts.tajawal()),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
    );
  }

  Widget _buildGroupSection(String title, List<Map<String, dynamic>> records) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
        initiallyExpanded: true,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(_getGroupIcon(), color: primaryColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
                  Text('${records.length} قيد', style: GoogleFonts.tajawal(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
        children: records.map((r) => _buildRecordCard(r, inGroup: true)).toList(),
      ),
    );
  }

  IconData _getGroupIcon() {
    return switch (_groupBy) {
      'guardian' => Icons.person,
      'contract_type' => Icons.description,
      'book_number' => Icons.menu_book,
      _ => Icons.folder,
    };
  }

  Widget _buildRecordCard(Map<String, dynamic> record, {bool inGroup = false}) {
    final bookNumber = record['book_number'] ?? 0;
    final name = record['name'] ?? 'سجل';
    final typeName = record['record_book_type']?['name'] ?? 'غير محدد';
    final guardianName = record['legitimate_guardian']?['first_name'] != null 
        ? "${record['legitimate_guardian']['first_name']} ${record['legitimate_guardian']['family_name'] ?? ''}"
        : (record['legitimate_guardian']?['full_name'] ?? 'غير معروف');
        
    final hijriYear = record['hijri_year'] ?? '';
    final status = record['status'] ?? 'active';
    final totalPages = record['total_pages'] ?? 0;
    final entriesCount = record['guardian_entries_count'] ?? 0;

    
    // Status Logic
    Color statusColor = Colors.grey;
    String statusLabel = status;
    if (status == 'active') { statusColor = Colors.green; statusLabel = 'نشط'; }
    else if (status == 'filled') { statusColor = Colors.orange; statusLabel = 'ممتلئ'; }
    else if (status == 'archived') { statusColor = Colors.grey; statusLabel = 'مؤرشف'; }

    return Container(
      margin: EdgeInsets.only(bottom: inGroup ? 0 : 12, left: inGroup ? 16 : 0, right: inGroup ? 16 : 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: inGroup ? Colors.grey[50] : Colors.white,
        borderRadius: BorderRadius.circular(inGroup ? 0 : 16),
        border: inGroup ? Border(bottom: BorderSide(color: Colors.grey.shade200)) : null,
        boxShadow: inGroup ? null : [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('#$bookNumber', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, color: primaryColor)),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(statusLabel, style: GoogleFonts.tajawal(fontSize: 11, color: statusColor, fontWeight: FontWeight.w500)),
              ),
              const Spacer(),
              Text('$hijriYear هـ', style: GoogleFonts.tajawal(fontSize: 12, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 12),
          
          // Main Info
          Text(name, style: GoogleFonts.tajawal(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(guardianName, style: GoogleFonts.tajawal(fontSize: 12, color: Colors.grey[700])),
          
          const SizedBox(height: 12),
          
          // Details
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _buildInfoChip(Icons.category_outlined, typeName),
              _buildInfoChip(Icons.format_list_numbered, '$entriesCount قيد'),
              _buildInfoChip(Icons.description_outlined, '$totalPages صفحة'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(text, style: GoogleFonts.tajawal(fontSize: 11, color: Colors.grey[700])),
        ],
      ),
    );
  }



  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('تصفية القيود', style: GoogleFonts.tajawal(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            
            // Year Filter
            _buildDropdownFilter(
              'السنة الهجرية',
              _yearFilter,
              [null, ..._getAvailableYears()],
              (v) => setState(() {
                _yearFilter = v;
                Navigator.pop(context);
                _loadData();
              }),
              (v) => v == null ? 'جميع السنوات' : '$v هـ',
            ),
            const SizedBox(height: 16),
            
            // Contract Type Filter
            _buildDropdownFilter(
              'نوع العقد',
              _contractTypeFilter,
              [null, ..._contractTypes.map((t) => t['id'] as int)],
              (v) => setState(() {
                _contractTypeFilter = v;
                Navigator.pop(context);
                _loadData();
              }),
              (v) => v == null ? 'جميع الأنواع' : _contractTypes.firstWhere((t) => t['id'] == v, orElse: () => {'name': ''})['name'] as String,
            ),
            const SizedBox(height: 16),
            
            // Record Book Type Filter
            _buildDropdownFilter(
              'نوع السجل',
              _recordBookTypeFilter,
              [null, ..._recordBookTypes.map((t) => t['id'] as int)],
              (v) => setState(() {
                _recordBookTypeFilter = v;
                Navigator.pop(context);
                _loadData();
              }),
              (v) => v == null ? 'جميع أنواع السجلات' : _recordBookTypes.firstWhere((t) => t['id'] == v, orElse: () => {'name': ''})['name'] as String,
            ),
            const SizedBox(height: 16),
            
            // Guardian Filter
            _buildDropdownFilter(
              'الأمين',
              _guardianFilter,
              [null, ..._guardians.map((g) => g['id'] as int)],
              (v) => setState(() {
                _guardianFilter = v;
                Navigator.pop(context);
                _loadData();
              }),
              (v) => v == null ? 'جميع الأمناء' : _guardians.firstWhere((g) => g['id'] == v, orElse: () => {'name': ''})['name'] as String,
            ),
            const SizedBox(height: 24),
            
            // Clear Filters
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _yearFilter = null;
                    _contractTypeFilter = null;
                    _guardianFilter = null;
                  });
                  Navigator.pop(context);
                  _loadData();
                },
                icon: const Icon(Icons.clear_all),
                label: Text('مسح الفلاتر', style: GoogleFonts.tajawal()),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownFilter<T>(
    String label,
    T? value,
    List<T?> items,
    ValueChanged<T?> onChanged,
    String Function(T?) labelBuilder,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, color: Colors.grey[700])),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T?>(
              value: value,
              isExpanded: true,
              hint: Text(labelBuilder(null), style: GoogleFonts.tajawal()),
              items: items.map((item) => DropdownMenuItem<T?>(
                value: item,
                child: Text(labelBuilder(item), style: GoogleFonts.tajawal()),
              )).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  void _showGroupSheet() {
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
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('تجميع حسب', style: GoogleFonts.tajawal(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _buildGroupOption('بدون تجميع', 'none', Icons.list),
            _buildGroupOption('الأمين', 'guardian', Icons.person),
            _buildGroupOption('نوع العقد', 'contract_type', Icons.description),
            _buildGroupOption('رقم الدفتر', 'book_number', Icons.menu_book),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupOption(String label, String value, IconData icon) {
    final isSelected = _groupBy == value;
    return ListTile(
      leading: Icon(icon, color: isSelected ? primaryColor : Colors.grey),
      title: Text(label, style: GoogleFonts.tajawal(
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? primaryColor : Colors.black87,
      )),
      trailing: isSelected ? const Icon(Icons.check, color: primaryColor) : null,
      onTap: () {
        setState(() => _groupBy = value);
        Navigator.pop(context);
      },
    );
  }

  void _showSortSheet() {
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
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('ترتيب حسب', style: GoogleFonts.tajawal(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _buildSortOption('تاريخ التحرير', 'document_date', Icons.calendar_today),
            _buildSortOption('الرقم التسلسلي', 'serial_number', Icons.tag),
            _buildSortOption('الرسوم', 'fee_amount', Icons.attach_money),
            const Divider(),
            SwitchListTile(
              title: Text('ترتيب تصاعدي', style: GoogleFonts.tajawal()),
              value: _sortAsc,
              onChanged: (v) {
                setState(() => _sortAsc = v);
                Navigator.pop(context);
                _loadData();
              },
              activeThumbColor: primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(String label, String value, IconData icon) {
    final isSelected = _sortBy == value;
    return ListTile(
      leading: Icon(icon, color: isSelected ? primaryColor : Colors.grey),
      title: Text(label, style: GoogleFonts.tajawal(
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? primaryColor : Colors.black87,
      )),
      trailing: isSelected ? const Icon(Icons.check, color: primaryColor) : null,
      onTap: () {
        setState(() => _sortBy = value);
        Navigator.pop(context);
        _loadData();
      },
    );
  }
}
