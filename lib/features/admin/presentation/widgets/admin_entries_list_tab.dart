import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:guardian_app/core/constants/api_constants.dart';
import 'package:guardian_app/features/auth/data/repositories/auth_repository.dart';
import 'package:guardian_app/features/registry/data/models/registry_entry.dart';
import 'package:guardian_app/features/registry/presentation/entry_details_screen.dart';

class AdminEntriesListTab extends StatefulWidget {
  const AdminEntriesListTab({super.key});

  @override
  State<AdminEntriesListTab> createState() => _AdminEntriesListTabState();
}

class _AdminEntriesListTabState extends State<AdminEntriesListTab> {
  static const primaryColor = Color(0xFF006400);

  bool _isLoading = true;
  bool _isLoadingMore = false;
  final List<RegistryEntry> _entries = [];
  List<RegistryEntry> _filteredEntries = [];

  // Pagination
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  // Filters
  String _searchQuery = '';
  String _statusFilter = 'all';
  int? _hijriYearFilter;
  int? _contractTypeFilter;
  String _sortBy = 'document_gregorian_date';
  bool _sortAsc = false;
  String _groupBy = 'none'; // 'none', 'month', 'status', 'contract_type'

  // Data
  List<Map<String, dynamic>> _contractTypes = [];
  List<int> _availableYears = [];

  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMore) {
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
        _entries.clear();
      });
    }

    try {
      final authRepo = Provider.of<AuthRepository>(context, listen: false);
      final token = await authRepo.getToken();

      // Build query params
      final params = <String, String>{
        'page': '$_currentPage',
        'per_page': '20',
        'sort_by': _sortBy,
        'sort_order': _sortAsc ? 'asc' : 'desc',
      };
      if (_statusFilter != 'all') params['status'] = _statusFilter;
      if (_hijriYearFilter != null) params['hijri_year'] = '$_hijriYearFilter';
      if (_contractTypeFilter != null) params['contract_type_id'] = '$_contractTypeFilter';
      if (_searchQuery.isNotEmpty) params['search'] = _searchQuery;

      final uri = Uri.parse('${ApiConstants.baseUrl}/admin/registry-entries').replace(queryParameters: params);

      final entriesResponse = await http.get(
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

      if (entriesResponse.statusCode == 200) {
        final data = jsonDecode(utf8.decode(entriesResponse.bodyBytes));
        final entriesList = data['data'] as List? ?? [];
        final newEntries = entriesList.map((x) => RegistryEntry.fromJson(x)).toList();

        // Pagination info
        final meta = data['meta'];
        if (meta != null) {
          _currentPage = meta['current_page'] ?? 1;
          _totalPages = meta['last_page'] ?? 1;
          _hasMore = _currentPage < _totalPages;
        } else {
          _hasMore = newEntries.length >= 20;
        }

        // Available years
        if (_availableYears.isEmpty) {
          _availableYears = newEntries
              .where((e) => e.hijriYear != null && e.hijriYear! > 0)
              .map((e) => e.hijriYear!)
              .toSet()
              .toList()
            ..sort((a, b) => b.compareTo(a));
        }

        setState(() {
          _entries.addAll(newEntries);
          _applyLocalFilters();
          _isLoading = false;
          _isLoadingMore = false;
        });
      } else {
        throw Exception('فشل تحميل البيانات');
      }
    } catch (e) {
      debugPrint('Error loading entries: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في تحميل البيانات: $e')),
        );
      }
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    _currentPage++;
    await _loadData(reset: false);
  }

  void _applyLocalFilters() {
    var filtered = List<RegistryEntry>.from(_entries);

    // Local search filter (in addition to server search)
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((e) =>
          e.firstParty.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.secondParty.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.contractType.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (e.serialNumber?.toString() ?? '').contains(_searchQuery)
      ).toList();
    }

    // Grouping
    if (_groupBy != 'none') {
      // Sort by group key first
      filtered.sort((a, b) {
        String keyA = _getGroupKey(a);
        String keyB = _getGroupKey(b);
        return keyA.compareTo(keyB);
      });
    }

    setState(() => _filteredEntries = filtered);
  }

  String _getGroupKey(RegistryEntry entry) {
    switch (_groupBy) {
      case 'month':
        final parts = entry.dateHijri.split('-');
        if (parts.length >= 2) {
          final year = parts[0];
          final month = int.tryParse(parts[1]) ?? 1;
          final monthNames = [
            '', 'محرم', 'صفر', 'ربيع الأول', 'ربيع الآخر', 'جمادى الأولى', 'جمادى الآخرة',
            'رجب', 'شعبان', 'رمضان', 'شوال', 'ذو القعدة', 'ذو الحجة'
          ];
          return '${monthNames[month]} $year هـ';
        }
        return 'أخرى';
      case 'status':
        return entry.statusLabel;
      case 'contract_type':
        return entry.contractType;
      default:
        return 'الكل';
    }
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
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
              Text('تصفية القيود', style: GoogleFonts.tajawal(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),

              // Status Filter
              Text('الحالة', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, color: Colors.grey[700])),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildFilterChip('الكل', 'all', _statusFilter == 'all', setModalState),
                  _buildFilterChip('مسودة', 'draft', _statusFilter == 'draft', setModalState),
                  _buildFilterChip('معتمد', 'approved', _statusFilter == 'approved', setModalState),
                  _buildFilterChip('مؤرشف', 'archived', _statusFilter == 'archived', setModalState),
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
                    value: _hijriYearFilter,
                    isExpanded: true,
                    hint: Text('جميع السنوات', style: GoogleFonts.tajawal()),
                    items: [
                      DropdownMenuItem<int?>(value: null, child: Text('جميع السنوات', style: GoogleFonts.tajawal())),
                      ..._availableYears.map((y) => DropdownMenuItem(value: y, child: Text('$y هـ', style: GoogleFonts.tajawal()))),
                    ],
                    onChanged: (v) => setModalState(() => _hijriYearFilter = v),
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
                        child: Text(t['name'] as String, style: GoogleFonts.tajawal(), overflow: TextOverflow.ellipsis),
                      )),
                    ],
                    onChanged: (v) => setModalState(() => _contractTypeFilter = v),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Apply & Reset
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setModalState(() {
                          _statusFilter = 'all';
                          _hijriYearFilter = null;
                          _contractTypeFilter = null;
                        });
                        Navigator.pop(context);
                        _loadData();
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
                      onPressed: () {
                        Navigator.pop(context);
                        _loadData();
                      },
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
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, bool selected, StateSetter setModalState) {
    return FilterChip(
      label: Text(label, style: GoogleFonts.tajawal(
        color: selected ? Colors.white : Colors.black87,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      )),
      selected: selected,
      selectedColor: primaryColor,
      backgroundColor: Colors.grey[100],
      onSelected: (s) => setModalState(() => _statusFilter = value),
    );
  }

  void _showGroupingSheet() {
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
            Text('تجميع حسب', style: GoogleFonts.tajawal(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildGroupOption('بدون تجميع', 'none', Icons.list),
            _buildGroupOption('الشهر', 'month', Icons.calendar_today),
            _buildGroupOption('الحالة', 'status', Icons.flag),
            _buildGroupOption('نوع العقد', 'contract_type', Icons.category),
            const SizedBox(height: 16),
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
        _applyLocalFilters();
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
            _buildSortOption('التاريخ', 'document_gregorian_date', Icons.calendar_today),
            _buildSortOption('الرقم التسلسلي', 'serial_number', Icons.tag),
            _buildSortOption('الرسوم', 'fee_amount', Icons.attach_money),
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
                    _loadData();
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
                    _loadData();
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
        _loadData();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: primaryColor),
            const SizedBox(height: 16),
            Text('جاري تحميل القيود...', style: GoogleFonts.tajawal(color: Colors.grey[600])),
          ],
        ),
      );
    }

    // Group entries if needed
    Map<String, List<RegistryEntry>> groupedEntries = {};
    if (_groupBy == 'none') {
      groupedEntries[''] = _filteredEntries;
    } else {
      for (var entry in _filteredEntries) {
        final key = _getGroupKey(entry);
        groupedEntries.putIfAbsent(key, () => []).add(entry);
      }
    }

    return Column(
      children: [
        // Search & Filter Bar
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 2))],
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
                  onSubmitted: (v) {
                    _searchQuery = v;
                    _loadData();
                  },
                  style: GoogleFonts.tajawal(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'بحث في القيود (الأطراف، نوع العقد، الرقم)...',
                    hintStyle: GoogleFonts.tajawal(color: Colors.grey[400], fontSize: 13),
                    prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.close, color: Colors.grey[400], size: 20),
                            onPressed: () {
                              _searchController.clear();
                              _searchQuery = '';
                              _loadData();
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Action buttons
              Row(
                children: [
                  Expanded(child: _buildActionChip(icon: Icons.filter_list, label: 'تصفية', isActive: _hasActiveFilters, activeColor: Colors.orange, onTap: _showFilterSheet)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildActionChip(icon: Icons.layers, label: 'تجميع', isActive: _groupBy != 'none', activeColor: Colors.purple, onTap: _showGroupingSheet)),
                  const SizedBox(width: 8),
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
              _buildStatChip(Icons.list_alt, '${_filteredEntries.length}', 'قيد'),
              const SizedBox(width: 8),
              _buildStatChip(Icons.check_circle, '${_filteredEntries.where((e) => e.statusLabel.contains('معتمد')).length}', 'معتمد'),
              const SizedBox(width: 8),
              _buildStatChip(Icons.attach_money, _formatAmount(_filteredEntries.fold(0.0, (sum, e) => sum + e.totalFees)), 'ر.س'),
            ],
          ),
        ),

        // Entries List
        Expanded(
          child: _filteredEntries.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  color: primaryColor,
                  onRefresh: () => _loadData(),
                  child: _groupBy == 'none'
                      ? _buildEntriesList(_filteredEntries)
                      : _buildGroupedList(groupedEntries),
                ),
        ),
      ],
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }

  bool get _hasActiveFilters => _statusFilter != 'all' || _hijriYearFilter != null || _contractTypeFilter != null;

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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withValues(alpha: 0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isActive ? activeColor.withValues(alpha: 0.3) : Colors.grey.shade200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isActive ? activeColor : Colors.grey[600]),
            const SizedBox(width: 4),
            Flexible(
              child: Text(label, style: GoogleFonts.tajawal(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive ? activeColor : Colors.grey[700],
              ), overflow: TextOverflow.ellipsis),
            ),
            if (isActive) ...[
              const SizedBox(width: 3),
              Container(width: 5, height: 5, decoration: BoxDecoration(color: activeColor, shape: BoxShape.circle)),
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
            Icon(icon, size: 16, color: primaryColor),
            const SizedBox(width: 4),
            Text(value, style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 13, color: primaryColor)),
            const SizedBox(width: 3),
            Text(label, style: GoogleFonts.tajawal(fontSize: 10, color: Colors.grey[600])),
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
              child: Icon(Icons.list_alt_outlined, size: 64, color: Colors.grey[400]),
            ),
            const SizedBox(height: 24),
            Text('لا توجد قيود', style: GoogleFonts.tajawal(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[700])),
            const SizedBox(height: 8),
            Text('لم يتم العثور على قيود مطابقة', style: GoogleFonts.tajawal(fontSize: 14, color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }

  Widget _buildEntriesList(List<RegistryEntry> entries) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: entries.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == entries.length) {
          return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(color: primaryColor)));
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildEntryCard(entries[index]),
        );
      },
    );
  }

  Widget _buildGroupedList(Map<String, List<RegistryEntry>> groups) {
    final keys = groups.keys.toList();
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: keys.length,
      itemBuilder: (context, groupIndex) {
        final key = keys[groupIndex];
        final groupEntries = groups[key]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (key.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                margin: EdgeInsets.only(bottom: 12, top: groupIndex > 0 ? 16 : 0),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(_groupBy == 'month' ? Icons.calendar_today : _groupBy == 'status' ? Icons.flag : Icons.category, size: 16, color: primaryColor),
                    const SizedBox(width: 8),
                    Text(key, style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, color: primaryColor)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(10)),
                      child: Text('${groupEntries.length}', style: GoogleFonts.tajawal(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],
            ...groupEntries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildEntryCard(e),
            )),
          ],
        );
      },
    );
  }

  Widget _buildEntryCard(RegistryEntry entry) {
    return GestureDetector(
      onTap: () => _navigateToDetails(entry),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            // Header with status
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: entry.statusColor.withValues(alpha: 0.05),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  // Serial Number
                  Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        '${entry.serialNumber ?? '-'}',
                        style: GoogleFonts.tajawal(fontSize: 14, fontWeight: FontWeight.bold, color: primaryColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                entry.firstParty,
                                style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.swap_horiz, size: 12, color: Colors.grey[400]),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                entry.secondParty,
                                style: GoogleFonts.tajawal(fontSize: 12, color: Colors.grey[600]),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: entry.statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(entry.statusLabel, style: GoogleFonts.tajawal(fontSize: 10, fontWeight: FontWeight.bold, color: entry.statusColor)),
                  ),
                ],
              ),
            ),

            // Details
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildDetailItem(Icons.category, entry.contractType),
                      const SizedBox(width: 16),
                      _buildDetailItem(Icons.calendar_today, entry.dateHijri),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildDetailItem(Icons.attach_money, '${entry.totalFees.toStringAsFixed(0)} ر.س'),
                      const Spacer(),
                      // Quick action
                      InkWell(
                        onTap: () => _navigateToDetails(entry),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.visibility_outlined, size: 14, color: primaryColor),
                              const SizedBox(width: 4),
                              Text('عرض', style: GoogleFonts.tajawal(fontSize: 11, fontWeight: FontWeight.bold, color: primaryColor)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey[400]),
        const SizedBox(width: 4),
        Text(text, style: GoogleFonts.tajawal(fontSize: 12, color: Colors.grey[700])),
      ],
    );
  }

  void _navigateToDetails(RegistryEntry entry) {
    if (entry.id != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => EntryDetailsScreen(entryId: entry.id!)),
      );
    }
  }
}
