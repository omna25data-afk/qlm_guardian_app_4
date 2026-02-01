import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:guardian_app/features/admin/data/models/admin_guardian_model.dart';
import 'package:guardian_app/providers/admin_guardians_provider.dart';
import 'package:guardian_app/features/admin/presentation/screens/add_edit_guardian_screen.dart';

class GuardiansListTab extends StatefulWidget {
  const GuardiansListTab({super.key});

  @override
  State<GuardiansListTab> createState() => _GuardiansListTabState();
}

class _GuardiansListTabState extends State<GuardiansListTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  
  // Sort/Filter State (Local for UI demo, can be hooked to API later)
  String _sortOption = 'date_desc'; // date_desc, date_asc, name_asc, name_desc

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabSelection);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      _fetchData();
    }
  }

  void _fetchData() {
    final status = switch (_tabController.index) {
      0 => 'all',
      1 => 'active',
      2 => 'stopped',
      _ => 'all',
    };
    
    Provider.of<AdminGuardiansProvider>(context, listen: false)
        .fetchGuardians(refresh: true, status: status, search: _searchController.text);
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      Provider.of<AdminGuardiansProvider>(context, listen: false)
          .setSearchQuery(query);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
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
       _fetchData();
     }
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
                _buildIconButton(Icons.filter_list, Colors.orange, () {}), // Advanced Filter
                const SizedBox(width: 8),
                _buildIconButton(Icons.sort, Colors.blue, _showSortSheet), // Sort
              ],
            ),
          ),

          // Custom Tabs
          Container(
            height: 50,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 5)],
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey[600],
              indicator: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(25),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Tajawal'),
              tabs: const [
                Tab(text: 'الكل'),
                Tab(text: 'على رأس العمل'),
                Tab(text: 'متوقف'),
              ],
            ),
          ),

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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
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
                      Text(guardian.name, style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('#م ${guardian.serialNumber}', style: const TextStyle(fontFamily: 'Tajawal', color: Colors.blue, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                // Smart Circles
                _buildSmartCircle(
                    title: 'الترخيص', 
                    expiryDateStr: guardian.licenseExpiryDate, 
                    totalDays: 1095, // 3 years
                    color: Colors.purple
                ),
                const SizedBox(width: 12),
                _buildSmartCircle(
                    title: 'البطاقة', 
                    expiryDateStr: guardian.professionCardExpiryDate, 
                    totalDays: 365, // 1 year
                    color: Colors.teal
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // Bottom Section: Details Grid & Actions
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50], 
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16))
            ),
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
                             color: Colors.blue.withValues(alpha: 0.1),
                             borderRadius: BorderRadius.circular(8)
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.edit, size: 16, color: Colors.blue),
                              SizedBox(width: 4),
                              Text('تعديل', style: TextStyle(fontFamily: 'Tajawal', color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold))
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // View Button (Placeholder)
                      InkWell(
                        onTap: () {},
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                             color: Colors.green.withValues(alpha: 0.1),
                             borderRadius: BorderRadius.circular(8)
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.visibility, size: 16, color: Colors.green),
                              SizedBox(width: 4),
                              Text('عرض', style: TextStyle(fontFamily: 'Tajawal', color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold))
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

  Widget _buildSmartCircle({required String title, required String? expiryDateStr, required int totalDays, required Color color}) {
     // Prepare data
     final now = DateTime.now();
     DateTime? expiry;
     int remainingDays = 0;
     double percent = 0.0;
     Color statusColor = Colors.grey;

     if (expiryDateStr != null) {
       expiry = DateTime.tryParse(expiryDateStr);
       if (expiry != null) {
         remainingDays = expiry.difference(now).inDays;
         if (remainingDays < 0) remainingDays = 0;
         percent = (remainingDays / totalDays).clamp(0.0, 1.0);
         
         if (remainingDays > 30) {
           statusColor = Colors.green;
         } else if (remainingDays > 0) {
           statusColor = Colors.orange;
         } else {
           statusColor = Colors.red;
         }
       }
     }

     return Column(
       children: [
         Stack(
           alignment: Alignment.center,
           children: [
             SizedBox(
               width: 40,
               height: 40,
               child: CircularProgressIndicator(
                 value: percent,
                 backgroundColor: Colors.grey[200],
                 color: statusColor,
                 strokeWidth: 4,
               ),
             ),
             Text(
               remainingDays > 999 ? '+999' : remainingDays.toString(),
               style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
             ),
           ],
         ),
         const SizedBox(height: 4),
         Text(title, style: const TextStyle(fontSize: 10, fontFamily: 'Tajawal', color: Colors.grey)),
       ],
     );
  }
}
