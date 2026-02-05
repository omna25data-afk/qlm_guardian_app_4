import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:guardian_app/core/constants/api_constants.dart';
import 'package:guardian_app/features/auth/data/repositories/auth_repository.dart';
import 'package:guardian_app/features/records/data/models/record_book.dart';

class AdminRecordsListTab extends StatefulWidget {
  const AdminRecordsListTab({super.key});

  @override
  State<AdminRecordsListTab> createState() => _AdminRecordsListTabState();
}

class _AdminRecordsListTabState extends State<AdminRecordsListTab> {
  static const primaryColor = Color(0xFF006400);
  
  bool _isLoading = true;
  List<RecordBook> _records = [];
  List<RecordBook> _filteredRecords = [];
  
  // Filters
  String _searchQuery = '';
  String _statusFilter = 'all';
  int? _yearFilter;
  int? _contractTypeFilter;
  String _sortBy = 'hijri_year';
  bool _sortAsc = false;
  
  // Data
  List<Map<String, dynamic>> _contractTypes = [];
  List<int> _availableYears = [];
  
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final authRepo = Provider.of<AuthRepository>(context, listen: false);
      final token = await authRepo.getToken();
      
      // Load records (all guardians for admin)
      final recordsResponse = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/admin/record-books'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      // Load contract types
      final typesResponse = await http.get(
        Uri.parse(ApiConstants.contractTypes),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (recordsResponse.statusCode == 200) {
        final data = jsonDecode(utf8.decode(recordsResponse.bodyBytes));
        final recordsList = data['data'] as List? ?? data as List? ?? [];
        _records = recordsList.map((x) => RecordBook.fromJson(x)).toList();
        
        // Extract available years
        _availableYears = _records
            .map((r) => r.hijriYear)
            .where((y) => y > 0)
            .toSet()
            .toList()
          ..sort((a, b) => b.compareTo(a));
      }
      
      if (typesResponse.statusCode == 200) {
        final data = jsonDecode(utf8.decode(typesResponse.bodyBytes));
        _contractTypes = (data as List).cast<Map<String, dynamic>>();
      }
      
      _applyFilters();
    } catch (e) {
      debugPrint('Error loading records: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في تحميل البيانات: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    var filtered = List<RecordBook>.from(_records);
    
    // Search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((r) =>
          r.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.contractType.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.number.toString().contains(_searchQuery)
      ).toList();
    }
    
    // Status filter
    if (_statusFilter != 'all') {
      filtered = filtered.where((r) => 
          r.statusLabel.toLowerCase().contains(_statusFilter.toLowerCase())
      ).toList();
    }
    
    // Year filter
    if (_yearFilter != null) {
      filtered = filtered.where((r) => r.hijriYear == _yearFilter).toList();
    }
    
    // Contract type filter
    if (_contractTypeFilter != null) {
      filtered = filtered.where((r) => r.contractTypeId == _contractTypeFilter).toList();
    }
    
    // Sort
    filtered.sort((a, b) {
      int result;
      switch (_sortBy) {
        case 'number':
          result = a.number.compareTo(b.number);
        case 'contract_type':
          result = a.contractType.compareTo(b.contractType);
        case 'usage':
          result = a.usagePercentage.compareTo(b.usagePercentage);
        default:
          result = a.hijriYear.compareTo(b.hijriYear);
      }
      return _sortAsc ? result : -result;
    });
    
    setState(() => _filteredRecords = filtered);
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
            Text('تصفية السجلات', style: GoogleFonts.tajawal(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            
            // Status Filter
            Text('الحالة', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, color: Colors.grey[700])),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _buildFilterChip('الكل', 'all', _statusFilter == 'all'),
                _buildFilterChip('نشط', 'نشط', _statusFilter == 'نشط'),
                _buildFilterChip('مكتمل', 'مكتمل', _statusFilter == 'مكتمل'),
                _buildFilterChip('ملغى', 'ملغى', _statusFilter == 'ملغى'),
              ],
            ),
            const SizedBox(height: 16),
            
            // Year Filter
            Text('السنة الهجرية', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, color: Colors.grey[700])),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int?>(
                  value: _yearFilter,
                  isExpanded: true,
                  hint: Text('جميع السنوات', style: GoogleFonts.tajawal()),
                  items: [
                    DropdownMenuItem<int?>(value: null, child: Text('جميع السنوات', style: GoogleFonts.tajawal())),
                    ..._availableYears.map((y) => DropdownMenuItem(
                      value: y,
                      child: Text('$y هـ', style: GoogleFonts.tajawal()),
                    )),
                  ],
                  onChanged: (v) => setState(() {
                    _yearFilter = v;
                    Navigator.pop(context);
                    _applyFilters();
                  }),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Contract Type Filter
            Text('نوع العقد', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, color: Colors.grey[700])),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int?>(
                  value: _contractTypeFilter,
                  isExpanded: true,
                  hint: Text('جميع الأنواع', style: GoogleFonts.tajawal()),
                  items: [
                    DropdownMenuItem<int?>(value: null, child: Text('جميع الأنواع', style: GoogleFonts.tajawal())),
                    ..._contractTypes.map((t) => DropdownMenuItem(
                      value: t['id'] as int,
                      child: Text(t['name'] as String, style: GoogleFonts.tajawal()),
                    )),
                  ],
                  onChanged: (v) => setState(() {
                    _contractTypeFilter = v;
                    Navigator.pop(context);
                    _applyFilters();
                  }),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _statusFilter = 'all';
                        _yearFilter = null;
                        _contractTypeFilter = null;
                      });
                      Navigator.pop(context);
                      _applyFilters();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('إعادة تعيين', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('تطبيق', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, bool selected) {
    return FilterChip(
      label: Text(label, style: GoogleFonts.tajawal(
        color: selected ? Colors.white : Colors.black87,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      )),
      selected: selected,
      selectedColor: primaryColor,
      backgroundColor: Colors.grey[100],
      onSelected: (s) {
        setState(() => _statusFilter = value);
        Navigator.pop(context);
        _applyFilters();
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
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Text('ترتيب حسب', style: GoogleFonts.tajawal(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildSortOption('السنة الهجرية', 'hijri_year', Icons.calendar_today),
            _buildSortOption('رقم السجل', 'number', Icons.tag),
            _buildSortOption('نوع العقد', 'contract_type', Icons.category),
            _buildSortOption('نسبة الاستخدام', 'usage', Icons.pie_chart),
            const Divider(height: 24),
            Row(
              children: [
                Text('الترتيب:', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
                const Spacer(),
                ChoiceChip(
                  label: Text('تصاعدي', style: GoogleFonts.tajawal()),
                  selected: _sortAsc,
                  selectedColor: primaryColor.withValues(alpha: 0.2),
                  onSelected: (s) => setState(() {
                    _sortAsc = true;
                    Navigator.pop(context);
                    _applyFilters();
                  }),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text('تنازلي', style: GoogleFonts.tajawal()),
                  selected: !_sortAsc,
                  selectedColor: primaryColor.withValues(alpha: 0.2),
                  onSelected: (s) => setState(() {
                    _sortAsc = false;
                    Navigator.pop(context);
                    _applyFilters();
                  }),
                ),
              ],
            ),
            const SizedBox(height: 16),
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
        _applyFilters();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: primaryColor),
            const SizedBox(height: 16),
            Text('جاري تحميل السجلات...', style: GoogleFonts.tajawal(color: Colors.grey[600])),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Search & Filter Bar
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            children: [
              // Search
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) {
                    _searchQuery = v;
                    _applyFilters();
                  },
                  style: GoogleFonts.tajawal(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'بحث في السجلات...',
                    hintStyle: GoogleFonts.tajawal(color: Colors.grey[400]),
                    prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.close, color: Colors.grey[400], size: 20),
                            onPressed: () {
                              _searchController.clear();
                              _searchQuery = '';
                              _applyFilters();
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Filter & Sort
              Row(
                children: [
                  Expanded(child: _buildActionChip(icon: Icons.filter_list, label: 'تصفية', isActive: _hasActiveFilters, activeColor: Colors.orange, onTap: _showFilterSheet)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildActionChip(icon: Icons.sort, label: 'ترتيب', isActive: false, activeColor: Colors.blue, onTap: _showSortSheet)),
                ],
              ),
            ],
          ),
        ),
        
        // Stats Row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              _buildStatChip(Icons.book, '${_filteredRecords.length}', 'سجل'),
              const SizedBox(width: 12),
              _buildStatChip(Icons.check_circle, '${_filteredRecords.where((r) => r.isActive).length}', 'نشط'),
              const SizedBox(width: 12),
              _buildStatChip(Icons.layers, '${_filteredRecords.fold<int>(0, (sum, r) => sum + r.notebooksCount)}', 'دفتر'),
            ],
          ),
        ),
        
        // Records List
        Expanded(
          child: _filteredRecords.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  color: primaryColor,
                  onRefresh: _loadData,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredRecords.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) => _buildRecordCard(_filteredRecords[index]),
                  ),
                ),
        ),
      ],
    );
  }

  bool get _hasActiveFilters => _statusFilter != 'all' || _yearFilter != null || _contractTypeFilter != null;

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
          mainAxisAlignment: MainAxisAlignment.center,
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

  Widget _buildStatChip(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: primaryColor),
            const SizedBox(width: 6),
            Text(value, style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 14, color: primaryColor)),
            const SizedBox(width: 4),
            Text(label, style: GoogleFonts.tajawal(fontSize: 11, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
              child: Icon(Icons.book_outlined, size: 64, color: Colors.grey[400]),
            ),
            const SizedBox(height: 24),
            Text('لا توجد سجلات', style: GoogleFonts.tajawal(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[700])),
            const SizedBox(height: 8),
            Text('لم يتم العثور على سجلات مطابقة', style: GoogleFonts.tajawal(fontSize: 14, color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordCard(RecordBook record) {
    return GestureDetector(
      onTap: () => _showRecordDetails(record),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: record.statusColor.withValues(alpha: 0.05),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        '${record.number}',
                        style: GoogleFonts.tajawal(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.title.isNotEmpty ? record.title : 'سجل رقم ${record.number}',
                          style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(record.contractType, style: GoogleFonts.tajawal(fontSize: 11, color: Colors.grey[700])),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: record.statusColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(record.statusLabel, style: GoogleFonts.tajawal(fontSize: 10, fontWeight: FontWeight.bold, color: record.statusColor)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Usage Progress
                  _buildUsageIndicator(record.usagePercentage),
                ],
              ),
            ),
            
            // Details
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                children: [
                  _buildInfoRow(Icons.calendar_today, 'السنة الهجرية', '${record.hijriYear} هـ'),
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.layers, 'عدد الدفاتر', '${record.notebooksCount}'),
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.list_alt, 'إجمالي القيود', '${record.totalEntries}'),
                ],
              ),
            ),
            
            // Actions
            Container(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: _buildCardAction(Icons.visibility_outlined, 'عرض الدفاتر', primaryColor, () => _showRecordDetails(record)),
                  ),
                  const SizedBox(width: 8),
                  _buildCardAction(Icons.info_outline, 'معلومات', Colors.blue, () => _showRecordInfo(record), isOutlined: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageIndicator(int percentage) {
    Color color;
    if (percentage >= 90) {
      color = Colors.red;
    } else if (percentage >= 70) {
      color = Colors.orange;
    } else {
      color = Colors.green;
    }
    
    return SizedBox(
      width: 50,
      height: 50,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: percentage / 100,
            strokeWidth: 4,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
          Text('$percentage%', style: GoogleFonts.tajawal(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[400]),
        const SizedBox(width: 8),
        Text(label, style: GoogleFonts.tajawal(color: Colors.grey[600], fontSize: 12)),
        const Spacer(),
        Text(value, style: GoogleFonts.tajawal(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildCardAction(IconData icon, String label, Color color, VoidCallback onTap, {bool isOutlined = false}) {
    return Material(
      color: isOutlined ? Colors.transparent : color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: isOutlined
              ? BoxDecoration(border: Border.all(color: color.withValues(alpha: 0.3)), borderRadius: BorderRadius.circular(10))
              : null,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: isOutlined ? MainAxisSize.min : MainAxisSize.max,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(label, style: GoogleFonts.tajawal(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ),
      ),
    );
  }

  void _showRecordDetails(RecordBook record) {
    // Navigate to notebooks screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('عرض دفاتر السجل: ${record.title}')),
    );
  }

  void _showRecordInfo(RecordBook record) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('معلومات السجل', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDialogInfo('رقم السجل', '${record.number}'),
            _buildDialogInfo('العنوان', record.title),
            _buildDialogInfo('نوع العقد', record.contractType),
            _buildDialogInfo('السنة', '${record.hijriYear} هـ'),
            _buildDialogInfo('الحالة', record.statusLabel),
            _buildDialogInfo('عدد الدفاتر', '${record.notebooksCount}'),
            _buildDialogInfo('إجمالي القيود', '${record.totalEntries}'),
            _buildDialogInfo('نسبة الاستخدام', '${record.usagePercentage}%'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إغلاق', style: GoogleFonts.tajawal()),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: GoogleFonts.tajawal(color: Colors.grey[600], fontSize: 13)),
          Expanded(child: Text(value, style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 13))),
        ],
      ),
    );
  }
}
