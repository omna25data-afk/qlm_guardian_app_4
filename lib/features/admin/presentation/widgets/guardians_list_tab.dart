import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:guardian_app/features/admin/data/models/admin_guardian_model.dart';
import 'package:guardian_app/providers/admin_guardians_provider.dart';
import 'package:guardian_app/features/admin/presentation/screens/add_edit_guardian_screen.dart';
import 'package:guardian_app/features/admin/presentation/screens/guardian_details_screen.dart';

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

  void _fetchData({bool refresh = false}) {
    Provider.of<AdminGuardiansProvider>(context, listen: false)
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
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
           const Padding(
             padding: EdgeInsets.all(16.0),
             child: Text('فرز القائمة', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 18)),
           ),
           _buildSortOption(ctx, 'الأحدث إضافة', 'date_desc', Icons.calendar_today),
           _buildSortOption(ctx, 'الأقدم إضافة', 'date_asc', Icons.history),
           _buildSortOption(ctx, 'الاسم (أ-ي)', 'name_asc', Icons.sort_by_alpha),
        ],
      ),
    );
  }

  Widget _buildSortOption(BuildContext ctx, String label, String value, IconData icon) {
    bool isSelected = _sortOption == value;
    return ListTile(
      title: Text(label, style: TextStyle(fontFamily: 'Tajawal', fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Theme.of(context).primaryColor : Colors.black87)),
      leading: Icon(icon, color: isSelected ? Theme.of(context).primaryColor : Colors.grey),
      trailing: isSelected ? Icon(Icons.check, color: Theme.of(context).primaryColor) : null,
      onTap: () {
        setState(() => _sortOption = value);
        // Here you would typically call _fetchData() with the new sort option
        Navigator.pop(ctx);
      },
    );

  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder( // Use StatefulBuilder to update sheet state
        builder: (ctx, setSheetState) => Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               const Text('تصفية النتائج', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 18)),
               const SizedBox(height: 20),
               const Text('حالة العمل', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
               const SizedBox(height: 10),
               Wrap(
                 spacing: 10,
                 children: [
                   _buildFilterChip('الكل', 'all', setSheetState),
                   _buildFilterChip('على رأس العمل', 'active', setSheetState),
                   _buildFilterChip('متوقف', 'stopped', setSheetState),
                 ],
               ),
               const SizedBox(height: 20),
               SizedBox(
                 width: double.infinity,
                 child: ElevatedButton(
                   onPressed: () {
                     Navigator.pop(context);
                     _fetchData(refresh: true);
                   },
                   style: ElevatedButton.styleFrom(
                     backgroundColor: Theme.of(context).primaryColor,
                     foregroundColor: Colors.white,
                     padding: const EdgeInsets.symmetric(vertical: 12),
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                   ),
                   child: const Text('تطبيق', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
                 ),
               )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, StateSetter setSheetState) {
    bool isSelected = _selectedStatus == value;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontFamily: 'Tajawal', color: isSelected ? Colors.white : Colors.black)),
      selected: isSelected,
      selectedColor: Theme.of(context).primaryColor,
      backgroundColor: Colors.grey[200],
      onSelected: (bool selected) {
        if (selected) {
           setSheetState(() => _selectedStatus = value);
           setState(() => _selectedStatus = value); // Sync with parent
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToEdit(null),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          // Top Search & Toolbar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'بحث فوري (الاسم، الرقم...)',
                        hintStyle: TextStyle(fontFamily: 'Tajawal', color: Colors.grey[400]),
                        prefixIcon: const Icon(Icons.search, color: Colors.blueGrey),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _buildIconButton(Icons.filter_list, _selectedStatus != 'all' ? Colors.orange : Colors.grey, _showFilterSheet), // Advanced Filter
                const SizedBox(width: 8),
                _buildIconButton(Icons.sort, Colors.blue, _showSortSheet), // Sort
              ],
            ),
          ),

          // Removed TabBar Container

          // List Content
          Expanded(
            child: Consumer<AdminGuardiansProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading && provider.guardians.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.guardians.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.separated(
                  controller: _scrollController, // Added Controller
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.guardians.length + (provider.hasMore ? 1 : 0),
                  separatorBuilder: (c, i) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    if (index == provider.guardians.length) {
                      return const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()));
                    }
                    return _buildGuardianCard(provider.guardians[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, Color color, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5)],
      ),
      child: IconButton(
        icon: Icon(icon, color: color),
        onPressed: onTap,
        constraints: const BoxConstraints(minWidth: 45, minHeight: 45),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'لا يوجد أمناء مطابقين للبحث',
            style: TextStyle(fontFamily: 'Tajawal', color: Colors.grey[600], fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildGuardianCard(AdminGuardian guardian) {
    bool isActive = guardian.employmentStatus == 'على رأس العمل';
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, // Cleaner white background
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          // Top Section: Avatar, Name, Status Chart
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 50, // Chart size
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isActive ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2), 
                          width: 3
                        ),
                      ),
                    ),
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.grey[100],
                      backgroundImage: guardian.photoUrl != null ? NetworkImage(guardian.photoUrl!) : null,
                      child: guardian.photoUrl == null ? Icon(Icons.person, color: Colors.grey[400]) : null,
                    ),
                    Positioned(
                       right: 0, 
                       bottom: 0,
                       child: Container(
                         padding: const EdgeInsets.all(4),
                         decoration: BoxDecoration(color: isActive ? Colors.green : Colors.red, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                       )
                    )
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(guardian.shortName, style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        // Removed '#م' prefix as requested
                        child: Text(guardian.serialNumber, style: const TextStyle(fontFamily: 'Tajawal', color: Colors.black87, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),

                // Smart Circles
                _buildSmartCircle(
                    title: 'الهوية', 
                    color: guardian.identityStatusColor,
                    remainingDays: guardian.identityRemainingDays
                ),
                const SizedBox(width: 8),
                _buildSmartCircle(
                    title: 'الترخيص', 
                    color: guardian.licenseStatusColor,
                    remainingDays: guardian.licenseRemainingDays
                ),
                const SizedBox(width: 8),
                _buildSmartCircle(
                    title: 'البطاقة', 
                    color: guardian.cardStatusColor,
                    remainingDays: guardian.cardRemainingDays
                ),
              ],
            ),
          ),
          
          const Divider(height: 1, indent: 16, endIndent: 16),
          
          // Bottom Section: Details Grid & Actions
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _buildInfoRow('حالة العمل', guardian.employmentStatus ?? '-', isActive ? Colors.green : Colors.red),
                const SizedBox(height: 6),
                _buildInfoRow('رقم الترخيص', guardian.licenseNumber ?? '-', Colors.black87),
                const SizedBox(height: 6),
                 _buildInfoRow('تاريخ الترخيص', guardian.licenseExpiryDate ?? '-', Colors.black54),
                 const SizedBox(height: 6),
                 _buildInfoRow('البطاقة الشخصية', guardian.expiryDate ?? '-', Colors.black54),
                
                const SizedBox(height: 12),
                Row(
                   mainAxisAlignment: MainAxisAlignment.end,
                   children: [
                      // Edit Button
                      InkWell(
                        onTap: () => _navigateToEdit(guardian),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                             color: Colors.blue.withValues(alpha: 0.05),
                             borderRadius: BorderRadius.circular(6)
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.edit, size: 14, color: Colors.blue),
                              SizedBox(width: 4),
                              Text('تعديل', style: TextStyle(fontFamily: 'Tajawal', color: Colors.blue, fontSize: 11, fontWeight: FontWeight.bold))
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // View Button
                      InkWell(
                        onTap: () => _navigateToDetails(guardian),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                             color: Colors.green.withValues(alpha: 0.05),
                             borderRadius: BorderRadius.circular(6)
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.visibility, size: 14, color: Colors.green),
                              SizedBox(width: 4),
                              Text('عرض', style: TextStyle(fontFamily: 'Tajawal', color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold))
                            ],
                          ),
                        ),
                      ),
                   ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color valueColor) {
     return Row(
       mainAxisAlignment: MainAxisAlignment.spaceBetween,
       children: [
         Text(label, style: TextStyle(fontFamily: 'Tajawal', color: Colors.grey[600], fontSize: 12)),
         Text(value, style: TextStyle(fontFamily: 'Tajawal', color: valueColor, fontSize: 12, fontWeight: FontWeight.bold)),
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
