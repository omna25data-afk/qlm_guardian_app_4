import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:guardian_app/features/admin/data/models/admin_guardian_model.dart';
import 'package:guardian_app/providers/admin_guardians_provider.dart';
import 'package:guardian_app/features/admin/presentation/screens/add_edit_guardian_screen.dart';
import 'package:guardian_app/features/admin/presentation/screens/guardian_details_screen.dart';
import 'package:guardian_app/widgets/custom_dropdown_menu.dart';

class GuardiansListTab extends StatefulWidget {
  const GuardiansListTab({super.key});

  @override
  State<GuardiansListTab> createState() => _GuardiansListTabState();
}

class _GuardiansListTabState extends State<GuardiansListTab> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  
  // State
  String _sortOption = 'date_desc'; // date_desc, date_asc, name_asc, name_desc
  String _selectedStatus = 'all'; // Replaces TabController index

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData(refresh: true);
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final provider = Provider.of<AdminGuardiansProvider>(context, listen: false);
      if (!provider.isLoading && provider.hasMore) {
        _fetchData(refresh: false);
      }
    }
  }

  Future<void> _fetchData({bool refresh = false}) async {
    await Provider.of<AdminGuardiansProvider>(context, listen: false)
        .fetchGuardians(refresh: refresh, status: _selectedStatus, search: _searchController.text);
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      Provider.of<AdminGuardiansProvider>(context, listen: false)
          .setSearchQuery(query);
      _fetchData(refresh: true);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _navigateToEdit(AdminGuardian? guardian) async {
     final result = await Navigator.push(
       context,
       MaterialPageRoute(builder: (_) => AddEditGuardianScreen(guardian: guardian)),
     );
     
     if (result == true) {
       _fetchData(refresh: true);
     }
  }

  void _navigateToDetails(AdminGuardian guardian) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GuardianDetailsScreen(guardian: guardian)),
    );
  }

  void _showSortSheet() {
    CustomBottomSheet.show(
      context: context,
      title: 'فرز القائمة',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'اختر طريقة الفرز',
            style: GoogleFonts.tajawal(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(height: 16),
          _buildSortOptionCard('الأحدث إضافة', 'date_desc', Icons.calendar_today),
          _buildSortOptionCard('الأقدم إضافة', 'date_asc', Icons.history),
          _buildSortOptionCard('الاسم (أ-ي)', 'name_asc', Icons.sort_by_alpha),
          _buildSortOptionCard('الاسم (ي-أ)', 'name_desc', Icons.sort_by_alpha),
        ],
      ),
    );
  }

  Widget _buildSortOptionCard(String label, String value, IconData icon) {
    final isSelected = _sortOption == value;
    const primaryColor = Color(0xFF006400);
    
    return GestureDetector(
      onTap: () {
        setState(() => _sortOption = value);
        Navigator.pop(context);
        _fetchData(refresh: true);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withValues(alpha: 0.08) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? primaryColor.withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: isSelected ? primaryColor : Colors.grey[600], size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.tajawal(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? primaryColor : Colors.black87,
                  fontSize: 15,
                ),
              ),
            ),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 16),
              ),
          ],
        ),
      ),
    );
  }

  void _showFilterSheet() {
    String tempStatus = _selectedStatus;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF006400).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.filter_list, color: Color(0xFF006400), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'تصفية النتائج',
                      style: GoogleFonts.tajawal(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: Colors.grey[400]),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'حالة العمل',
                      style: GoogleFonts.tajawal(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildFilterOptionRow('الكل', 'all', tempStatus, (val) {
                      setSheetState(() => tempStatus = val);
                    }),
                    _buildFilterOptionRow('على رأس العمل', 'active', tempStatus, (val) {
                      setSheetState(() => tempStatus = val);
                    }),
                    _buildFilterOptionRow('متوقف عن العمل', 'stopped', tempStatus, (val) {
                      setSheetState(() => tempStatus = val);
                    }),
                  ],
                ),
              ),
              // Apply Button
              Container(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() => _selectedStatus = tempStatus);
                      Navigator.pop(context);
                      _fetchData(refresh: true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF006400),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      'تطبيق التصفية',
                      style: GoogleFonts.tajawal(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterOptionRow(String label, String value, String currentValue, Function(String) onSelect) {
    final isSelected = currentValue == value;
    const primaryColor = Color(0xFF006400);
    
    return GestureDetector(
      onTap: () => onSelect(value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withValues(alpha: 0.08) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? primaryColor : Colors.transparent,
                border: Border.all(
                  color: isSelected ? primaryColor : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: GoogleFonts.tajawal(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? primaryColor : Colors.black87,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF006400);
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [primaryColor, Color(0xFF008000)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () => _navigateToEdit(null),
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: const Icon(Icons.person_add, color: Colors.white),
          label: Text('إضافة أمين', style: GoogleFonts.tajawal(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
      body: Column(
        children: [
          // Top Search & Toolbar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    style: GoogleFonts.tajawal(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'بحث بالاسم أو الرقم...',
                      hintStyle: GoogleFonts.tajawal(color: Colors.grey[400], fontSize: 14),
                      prefixIcon: Container(
                        padding: const EdgeInsets.all(12),
                        child: Icon(Icons.search, color: Colors.grey[500], size: 22),
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.close, color: Colors.grey[400], size: 20),
                              onPressed: () {
                                _searchController.clear();
                                _onSearchChanged('');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Filter & Sort Row
                Row(
                  children: [
                    // Filter Button
                    Expanded(
                      child: _buildActionChip(
                        icon: Icons.filter_list,
                        label: 'تصفية',
                        isActive: _selectedStatus != 'all',
                        activeColor: Colors.orange,
                        onTap: _showFilterSheet,
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Sort Button
                    Expanded(
                      child: _buildActionChip(
                        icon: Icons.sort,
                        label: 'فرز',
                        isActive: _sortOption != 'date_desc',
                        activeColor: Colors.blue,
                        onTap: _showSortSheet,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // List Content
          Expanded(
            child: Consumer<AdminGuardiansProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading && provider.guardians.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(color: primaryColor),
                        const SizedBox(height: 16),
                        Text('جاري التحميل...', style: GoogleFonts.tajawal(color: Colors.grey[600])),
                      ],
                    ),
                  );
                }

                if (provider.guardians.isEmpty) {
                  return _buildEmptyState();
                }

                return RefreshIndicator(
                  color: primaryColor,
                  onRefresh: () => _fetchData(refresh: true),
                  child: ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.guardians.length + (provider.hasMore ? 1 : 0),
                    separatorBuilder: (c, i) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      if (index == provider.guardians.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(color: primaryColor, strokeWidth: 2),
                          ),
                        );
                      }
                      return _buildGuardianCard(provider.guardians[index]);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
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
          border: Border.all(
            color: isActive ? activeColor.withValues(alpha: 0.3) : Colors.grey.shade200,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: isActive ? activeColor : Colors.grey[600]),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.tajawal(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive ? activeColor : Colors.grey[700],
              ),
            ),
            if (isActive) ...[
              const SizedBox(width: 4),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: activeColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
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
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.person_search, size: 64, color: Colors.grey[400]),
            ),
            const SizedBox(height: 24),
            Text(
              'لا يوجد أمناء',
              style: GoogleFonts.tajawal(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'لم يتم العثور على نتائج مطابقة للبحث',
              style: GoogleFonts.tajawal(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _selectedStatus = 'all';
                  _sortOption = 'date_desc';
                });
                _fetchData(refresh: true);
              },
              icon: const Icon(Icons.refresh),
              label: Text('إعادة تعيين', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF006400),
                side: const BorderSide(color: Color(0xFF006400)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildGuardianCard(AdminGuardian guardian) {
    const primaryColor = Color(0xFF006400);
    bool isActive = guardian.employmentStatus == 'على رأس العمل';
    
    return GestureDetector(
      onTap: () => _navigateToDetails(guardian),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isActive ? primaryColor.withValues(alpha: 0.03) : Colors.red.withValues(alpha: 0.03),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  // Avatar with status indicator
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: isActive 
                                ? [primaryColor, const Color(0xFF008000)]
                                : [Colors.red.shade400, Colors.red.shade600],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 26,
                          backgroundColor: Colors.white,
                          child: CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.grey[100],
                            backgroundImage: guardian.photoUrl != null 
                                ? NetworkImage(guardian.photoUrl!) 
                                : null,
                            child: guardian.photoUrl == null 
                                ? Icon(Icons.person, color: Colors.grey[400], size: 28) 
                                : null,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: isActive ? primaryColor : Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  // Name & Serial
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          guardian.shortName,
                          style: GoogleFonts.tajawal(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                guardian.serialNumber,
                                style: GoogleFonts.tajawal(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isActive ? primaryColor.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isActive ? 'نشط' : 'متوقف',
                                style: GoogleFonts.tajawal(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isActive ? primaryColor : Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Status Circles
                  Row(
                    children: [
                      _buildSmartCircle(
                        title: 'الهوية',
                        color: guardian.identityStatusColor,
                        remainingDays: guardian.identityRemainingDays,
                      ),
                      const SizedBox(width: 6),
                      _buildSmartCircle(
                        title: 'الترخيص',
                        color: guardian.licenseStatusColor,
                        remainingDays: guardian.licenseRemainingDays,
                      ),
                      const SizedBox(width: 6),
                      _buildSmartCircle(
                        title: 'البطاقة',
                        color: guardian.cardStatusColor,
                        remainingDays: guardian.cardRemainingDays,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Details Section
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                children: [
                  // Info Rows
                  _buildInfoRow(
                    Icons.credit_card,
                    'رقم الترخيص',
                    guardian.licenseNumber ?? '-',
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.event,
                    'انتهاء الترخيص',
                    guardian.licenseExpiryDate ?? '-',
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.badge_outlined,
                    'انتهاء الهوية',
                    guardian.expiryDate ?? '-',
                  ),
                ],
              ),
            ),
            
            // Actions Section
            Container(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  // View Button
                  Expanded(
                    child: _buildCardActionButton(
                      icon: Icons.visibility_outlined,
                      label: 'عرض التفاصيل',
                      color: primaryColor,
                      onTap: () => _navigateToDetails(guardian),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Edit Button
                  _buildCardActionButton(
                    icon: Icons.edit_outlined,
                    label: 'تعديل',
                    color: Colors.blue,
                    onTap: () => _navigateToEdit(guardian),
                    isOutlined: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool isOutlined = false,
  }) {
    return Material(
      color: isOutlined ? Colors.transparent : color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: isOutlined
              ? BoxDecoration(
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(10),
                )
              : null,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: isOutlined ? MainAxisSize.min : MainAxisSize.max,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.tajawal(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[400]),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.tajawal(color: Colors.grey[600], fontSize: 12),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.tajawal(
            color: Colors.black87,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildSmartCircle({required String title, required Color color, int? remainingDays}) {
     return Column(
       children: [
         Container(
           width: 36,
           height: 36,
           alignment: Alignment.center,
           decoration: BoxDecoration(
             shape: BoxShape.circle,
             color: color.withValues(alpha: 0.1),
             border: Border.all(color: color, width: 2),
           ),
           child: remainingDays != null
               ? Text(
                   '$remainingDays',
                   style: TextStyle(
                     color: color, 
                     fontWeight: FontWeight.bold, 
                     fontSize: remainingDays.abs() > 99 ? 10 : 12,
                     fontFamily: 'Tajawal'
                   ),
                 )
               : Icon(
                   color == Colors.green ? Icons.check : (color == Colors.orange ? Icons.priority_high : Icons.close),
                   color: color,
                   size: 20,
                 ),
         ),
         const SizedBox(height: 4),
         Text(title, style: const TextStyle(fontSize: 10, fontFamily: 'Tajawal', color: Colors.grey)),
       ],
     );
  }
}
