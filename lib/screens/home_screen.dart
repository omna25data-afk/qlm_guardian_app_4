import 'package:flutter/material.dart';
import 'package:guardian_app/features/records/presentation/screens/record_book_notebooks_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:guardian_app/widgets/stat_card.dart';
import 'package:provider/provider.dart';

import 'package:guardian_app/providers/dashboard_provider.dart';
import 'package:guardian_app/features/dashboard/data/models/dashboard_data.dart';
import 'package:guardian_app/providers/record_book_provider.dart';
import 'package:guardian_app/providers/registry_entry_provider.dart';
import 'package:guardian_app/features/registry/presentation/add_entry_screen.dart';
import 'package:guardian_app/core/constants/system_constants.dart';
import 'package:guardian_app/features/registry/presentation/entry_details_screen.dart'; // Add Import
import 'package:guardian_app/features/profile/presentation/profile_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:guardian_app/core/constants/api_constants.dart';
import 'package:guardian_app/features/auth/data/repositories/auth_repository.dart';
import 'package:guardian_app/features/registry/data/models/registry_entry.dart';
import 'package:guardian_app/features/records/data/models/record_book.dart';

// --- Main HomeScreen (Shell) ---
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final List<Widget> widgetOptions = <Widget>[
      const MainTab(),
      Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                RecordBooksList(),
                RegistryEntriesList(),
              ],
            ),
          ),
        ],
      ),
      const AddEntryScreen(), // Use new AddEntryScreen
      const ToolsTab(),
      const ProfileScreen(), // Use ProfileScreen instead of MoreTab
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('بوابة الأمين الشرعي'),
        titleTextStyle: GoogleFonts.tajawal(
            textStyle: textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF006400),
        iconTheme: const IconThemeData(color: Colors.white),
        automaticallyImplyLeading: false,
      ),
      body: _selectedIndex == 1
          ? Column(
              children: [
                // Custom Tab Bar Container
                Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(text: 'سجلاتي'),
                      Tab(text: 'قيودي'),
                    ],
                    indicator: BoxDecoration(
                      color: const Color(0xFF006400),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: Colors.white,
                    // unselectedLabelColor: Colors.grey[600],
                    labelStyle: GoogleFonts.tajawal(
                        fontWeight: FontWeight.bold, fontSize: 16),
                    unselectedLabelStyle: GoogleFonts.tajawal(
                        fontWeight: FontWeight.w500, fontSize: 16),
                    dividerColor: Colors.transparent,
                    padding: const EdgeInsets.all(4),
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: const [
                      RecordBooksList(),
                      RegistryEntriesList(),
                    ],
                  ),
                ),
              ],
            )
          : Center(
              child: widgetOptions.elementAt(_selectedIndex),
            ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'الرئيسية'),
          BottomNavigationBarItem(
              icon: Icon(Icons.book_online), label: 'سجلاتي'),
          BottomNavigationBarItem(
              icon: Icon(Icons.add_circle, size: 40), label: 'إضافة'),
          BottomNavigationBarItem(icon: Icon(Icons.build), label: 'الأدوات'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'حسابي'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF006400),
        //unselectedLabelColor: Colors.grey[600],
        showUnselectedLabels: true,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
        unselectedLabelStyle: GoogleFonts.tajawal(),
      ),
    );
  }
}

// --- Main Dashboard Tab ---
class MainTab extends StatefulWidget {
  const MainTab({super.key});
  @override
  State<MainTab> createState() => _MainTabState();
}

class _MainTabState extends State<MainTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DashboardProvider>(context, listen: false).fetchDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (provider.errorMessage != null || provider.dashboardData == null) {
          return Center(
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('حدث خطأ أثناء جلب البيانات',
                  style: TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              ElevatedButton(
                  onPressed: () => provider.fetchDashboard(),
                  child: const Text('إعادة المحاولة')),
            ]),
          );
        }
        final dashboard = provider.dashboardData!;
        return _buildDashboardUI(context, dashboard);
      },
    );
  }

  Widget _buildDashboardUI(BuildContext context, DashboardData dashboard) {
    return DefaultTabController(
      length: 2,
      child: RefreshIndicator(
        onRefresh: () => Provider.of<DashboardProvider>(context, listen: false)
            .fetchDashboard(),
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildWelcomeCard(context, dashboard),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "إحصائياتي",
                  style: GoogleFonts.tajawal(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Container(
                  height: 35,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TabBar(
                    isScrollable: true,
                    indicator: BoxDecoration(
                      color: const Color(0xFF006400),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.black54,
                    labelStyle: GoogleFonts.tajawal(fontSize: 12, fontWeight: FontWeight.bold),
                    tabs: const [
                       Tab(text: 'القيود'),
                       Tab(text: 'السجلات'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200, // Fixed height for stats grid area
              child: TabBarView(
                children: [
                   _buildRegistryStatsGrid(context, dashboard.stats),
                   _buildRecordBookStatsGrid(context, dashboard.stats),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildStatusCard(context, 'حالة الترخيص', dashboard.licenseStatus),
            const SizedBox(height: 12),
            _buildStatusCard(context, 'حالة البطاقة', dashboard.cardStatus),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context, DashboardData dashboard) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dashboard.welcomeMessage,
              style: GoogleFonts.tajawal(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF006400),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(dashboard.dateGregorian,
                    style: Theme.of(context).textTheme.bodyMedium),
                Text(dashboard.dateHijri,
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegistryStatsGrid(BuildContext context, DashboardStats stats) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.2,
      children: [
        StatCard(
          title: 'إجمالي القيود',
          count: stats.totalEntries.toString(),
          icon: Icons.all_inbox_outlined,
          iconColor: Colors.blue,
        ),
        StatCard(
          title: 'موثق',
          count: stats.documentedEntries.toString(),
          icon: Icons.check_circle_outline,
          iconColor: Colors.green,
        ),
        StatCard(
          title: 'بانتظار التوثيق',
          count: stats.pendingDocumentationEntries.toString(),
          icon: Icons.access_time_outlined,
          iconColor: Colors.orange,
        ),
        StatCard(
          title: 'المسودات',
          count: stats.draftEntries.toString(),
          icon: Icons.drafts_outlined,
          iconColor: Colors.grey,
        ),
      ],
    );
  }

  Widget _buildRecordBookStatsGrid(BuildContext context, DashboardStats stats) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.2,
      children: [
        StatCard(
          title: 'إجمالي السجلات',
          count: stats.totalRecordBooks.toString(),
          icon: Icons.book_outlined,
          iconColor: Colors.teal,
        ),
        StatCard(
          title: 'سجلات نشطة',
          count: stats.activeRecordBooks.toString(),
          icon: Icons.play_circle_outline,
          iconColor: Colors.green,
        ),
        StatCard(
          title: 'سجلات مغلقة',
          count: stats.closedRecordBooks.toString(),
          icon: Icons.lock_outline,
          iconColor: Colors.redAccent,
        ),
        StatCard(
          title: 'بانتظار الافتتاح',
          count: stats.pendingRecordBooks.toString(),
          icon: Icons.pending_outlined,
          iconColor: Colors.amber,
        ),
      ],
    );
  }

  Widget _buildStatusCard(
      BuildContext context, String title, RenewalStatus status) {
    return Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text(
                            'تنتهي في: ${status.expiryDate?.year}/${status.expiryDate?.month}/${status.expiryDate?.day}',
                            style: Theme.of(context).textTheme.bodySmall)
                      ]),
                  Row(children: [
                    Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                            color: status.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20)),
                        child: Text(status.label,
                            style: TextStyle(
                                color: status.color,
                                fontWeight: FontWeight.bold))),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_ios,
                        size: 14, color: Colors.grey)
                  ])
                ])));
  }
}

// --- Widget for displaying Record Books as Cards ---
class RecordBooksList extends StatefulWidget {
  const RecordBooksList({super.key});
  @override
  State<RecordBooksList> createState() => _RecordBooksListState();
}

class _RecordBooksListState extends State<RecordBooksList> {
  String? _selectedCategory;
  bool _showArchive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RecordBookProvider>(context, listen: false)
          .fetchRecordBooks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RecordBookProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.recordBooks.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (provider.errorMessage != null) {
          return Center(child: Text(provider.errorMessage!));
        }

        // Filter based on Archive Mode and Category
        final allBooks = provider.recordBooks;

        // 1. Filter by Active/Archive
        final filteredBooks = allBooks
            .where((b) => _showArchive ? !b.isActive : b.isActive)
            .toList();

        // 2. Group by Fixed 7 Categories
        // Initialize with zeros
        final categoryMaxNumbers = <String, int>{
          'سجلات المبيع': 0,
          'سجلات الزواج': 0,
          'سجلات الطلاق': 0,
          'سجلات الرجعة': 0,
          'سجلات التصرفات': 0,
          'سجلات القسمة': 0,
          'سجلات الوكالات': 0,
        };

        // Helper to map API contract types to our 7 categories using System IDs
        String getStandardCategory(RecordBook book) {
           final typeId = book.contractTypeId; 
           if (typeId == null) return 'أخرى';

           if (typeId == SystemConstants.CONTRACT_TYPE_MARRIAGE) return 'سجلات الزواج';
           if (typeId == SystemConstants.CONTRACT_TYPE_DIVORCE) return 'سجلات الطلاق';
           if (typeId == SystemConstants.CONTRACT_TYPE_RECONCILIATION) return 'سجلات الرجعة';
           if (typeId == SystemConstants.CONTRACT_TYPE_AGENCY) return 'سجلات الوكالات';
           if (typeId == SystemConstants.CONTRACT_TYPE_DISPOSITION) return 'سجلات التصرفات';
           if (typeId == SystemConstants.CONTRACT_TYPE_DIVISION) return 'سجلات القسمة';
           if (SystemConstants.SALES_TYPES.contains(typeId)) return 'سجلات المبيع';
           
           return 'أخرى';
        }

        // Process books to find Max Book Number per category
        for (var book in filteredBooks) {
          // Use contractType instead of categoryLabel because categoryLabel is generic (e.g. "Guardian Recording")
          // while contractType holds the specific type (e.g. "Marriage Contract")
          final standardCat = getStandardCategory(book);
          if (categoryMaxNumbers.containsKey(standardCat)) {
             // Sum up the number of physical notebooks reported by the AP (notebooksCount)
             // Each 'book' item from API is now a container that might represent multiple notebooks.
             categoryMaxNumbers[standardCat] = (categoryMaxNumbers[standardCat] ?? 0) + book.notebooksCount;
          }
        }

        return Column(
          children: [
            // Archive Toggle Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.grey[50],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _showArchive
                        ? '🗄️ الأرشيف (السجلات السابقة)'
                        : '📂 السجلات النشطة (الحالية)',
                    style: GoogleFonts.tajawal(
                      fontWeight: FontWeight.bold,
                      color: _showArchive
                          ? Colors.amber[900]
                          : const Color(0xFF006400),
                    ),
                  ),
                  Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value: _showArchive,
                      onChanged: (val) {
                        setState(() {
                          _showArchive = val;
                          _selectedCategory =
                              null; // Reset selection when switching modes
                        });
                      },
                      activeThumbColor: Colors.amber[900],
                      inactiveThumbColor: const Color(0xFF006400),
                      inactiveTrackColor:
                          const Color(0xFF006400).withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),

            // Breadcrumb if category selected
            if (_selectedCategory != null)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.white,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, size: 20),
                      onPressed: () => setState(() => _selectedCategory = null),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _selectedCategory!,
                      style: GoogleFonts.tajawal(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ),

            // Main Content
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => provider.fetchRecordBooks(),
                child: _selectedCategory == null
                    ? _buildCategoriesGrid(categoryMaxNumbers)
                    : _buildBooksList(filteredBooks
                        .where((b) => getStandardCategory(b) == _selectedCategory)
                        .toList()),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoriesGrid(Map<String, int> categories) {
    if (categories.values.every((v) => v == 0) && _showArchive) {
       // Only show empty state if ALL are zero in Archive mode (Active mode usually shows categories even if empty)
       // But user wanted 7 containers always potentially? Let's keep showing them.
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories.keys.elementAt(index);
        final count = categories[category]!;
        return _buildCategoryCard(category, count);
      },
    );
  }

  Widget _buildCategoryCard(String title, int count) {
    return InkWell(
      onTap: () => setState(() => _selectedCategory = title),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _showArchive
                    ? Colors.amber[50]
                    : const Color(0xFF006400).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getCategoryIcon(title),
                color:
                    _showArchive ? Colors.amber[900] : const Color(0xFF006400),
                size: 32,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.tajawal(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count دفاتر',
                style: GoogleFonts.tajawal(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBooksList(List<dynamic> books) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        return _buildRecordBookCard(book);
      },
    );
  }

  IconData _getCategoryIcon(String title) {
    if (title.contains('زواج')) return Icons.favorite;
    if (title.contains('طلاق')) return Icons.heart_broken;
    if (title.contains('وكالات')) return Icons.handshake;
    if (title.contains('مبيع')) return Icons.store;
    if (title.contains('تركة') || title.contains('قسمة')) {
      return Icons.pie_chart;
    }
    if (title.contains('تصرفات')) return Icons.gavel;
    if (title.contains('رجعة')) return Icons.replay;
    return Icons.menu_book;
  }



  Widget _buildRecordBookCard(dynamic book) {
    return InkWell(
      onTap: () {
         if (book.contractTypeId != null) {
           Navigator.push(context, MaterialPageRoute(
              builder: (_) => RecordBookNotebooksScreen(
                  contractTypeId: book.contractTypeId!, 
                  contractTypeName: book.contractType
              )
           ));
         }
      },
      child: Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              book.statusColor.withValues(alpha: 0.1),
              Colors.white,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: book.statusColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: book.statusColor.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        '📖',
                        style: TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'سجل رقم ${book.number}',
                          style: GoogleFonts.tajawal(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${book.contractType} | ${book.hijriYear}هـ',
                          style: GoogleFonts.tajawal(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: book.statusColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      book.statusLabel,
                      style: TextStyle(
                        color: book.statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Statistics Row
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMiniStat(Icons.list_alt, '${book.totalEntries}', 'إجمالي', Colors.blue),
                    _buildMiniStat(Icons.check_circle_outline, '${book.completedEntries}', 'موثق', Colors.green),
                    _buildMiniStat(Icons.history_edu, '${book.draftEntries}', 'غير موثق', Colors.orange),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Progress Section
              Row(
                children: [
                  Icon(Icons.description, size: 18, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    '${book.usedPages}/${book.totalPages} صفحة',
                    style: GoogleFonts.tajawal(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${book.usagePercentage}%',
                    style: GoogleFonts.tajawal(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: book.statusColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: book.usagePercentage / 100,
                  minHeight: 10,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(book.statusColor),
                ),
              ),
            ],
          ), // Column
        ), // Padding
      ), // Container
    ), // Card
    ); // InkWell
  }

  Widget _buildMiniStat(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 16, color: color),
            ),
          ],
        ),
        Text(
          label,
          style: GoogleFonts.tajawal(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }
}

// --- Widget for displaying Registry Entries as Table ---
class RegistryEntriesList extends StatefulWidget {
  final int? bookNumber;
  final int? recordBookId;
  final int? contractTypeId;

  const RegistryEntriesList({
    super.key, 
    this.bookNumber, 
    this.recordBookId,
    this.contractTypeId,
  });

  @override
  State<RegistryEntriesList> createState() => _RegistryEntriesListState();
}

class _RegistryEntriesListState extends State<RegistryEntriesList> {
  final String _sortBy = 'document_gregorian_date';
  bool _sortAscending = false;
  String? _filterStatus;
  int? _filterHijriYear;
  int? _filterHijriMonth;
  int? _filterContractTypeId;
  List<Map<String, dynamic>> _contractTypes = [];
  
  String _groupBy = 'none'; // 'none', 'month', 'status', 'contract_type'

  void _fetchData() {
    Provider.of<RegistryEntryProvider>(context, listen: false).fetchEntries(
      bookNumber: widget.bookNumber,
      recordBookId: widget.recordBookId,
      contractTypeId: _filterContractTypeId ?? widget.contractTypeId,
      status: _filterStatus,
      hijriYear: _filterHijriYear,
      hijriMonth: _filterHijriMonth,
      sortBy: _sortBy,
      sortOrder: _sortAscending ? 'asc' : 'desc',
    );
  }

  Future<void> _loadContractTypes() async {
    try {
      final authRepo = Provider.of<AuthRepository>(context, listen: false);
      final token = await authRepo.getToken();
      final response = await http.get(
        Uri.parse(ApiConstants.contractTypes),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'X-Auth-Token': token ?? '',
        },
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (mounted) setState(() => _contractTypes = data.cast<Map<String, dynamic>>());
      }
    } catch (e) {
      debugPrint('Error loading contract types: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
      _loadContractTypes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RegistryEntryProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.entries.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (provider.errorMessage != null) {
          return Center(child: Text(provider.errorMessage!));
        }

        final entries = provider.entries;
        
        // Logical Grouping
        Map<String, List<RegistryEntry>> groupedEntries = {};
        if (_groupBy == 'none') {
           groupedEntries['الكل'] = entries;
        } else {
           for (var entry in entries) {
              String key = 'أخرى';
              if (_groupBy == 'month') {
                 final parts = entry.dateHijri.split('-');
                 if (parts.length >= 2) {
                    final year = parts[0];
                    final month = int.tryParse(parts[1]) ?? 1;
                    final monthNames = [
                      '', 'محرم', 'صفر', 'ربيع الأول', 'ربيع الآخر', 'جمادى الأولى', 'جمادى الآخرة',
                      'رجب', 'شعبان', 'رمضان', 'شوال', 'ذو القعدة', 'ذو الحجة'
                    ];
                    key = '${monthNames[month]} $year هـ';
                 }
              } else if (_groupBy == 'status') {
                 key = entry.statusLabel;
              } else if (_groupBy == 'contract_type') {
                 key = entry.contractType;
              }
              groupedEntries.putIfAbsent(key, () => []).add(entry);
           }
        }

        return Column(
          children: [
            // Advanced Filter & Grouping Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))
                ]
              ),
              child: Row(
                children: [
                  // Grouping Selector
                  DropdownButton<String>(
                    value: _groupBy,
                    icon: const Icon(Icons.layers, size: 20),
                    underline: const SizedBox(),
                    items: const [
                       DropdownMenuItem(value: 'none', child: Text('بدون تجميع')),
                       DropdownMenuItem(value: 'month', child: Text('بالشهر')),
                       DropdownMenuItem(value: 'status', child: Text('بالحالة')),
                       DropdownMenuItem(value: 'contract_type', child: Text('بنوع العقد')),
                    ],
                    onChanged: (v) => setState(() => _groupBy = v!),
                    style: GoogleFonts.tajawal(color: Colors.black87, fontSize: 13),
                  ),
                  const Spacer(),
                  // Sort Icon
                  IconButton(
                    icon: Icon(_sortAscending ? Icons.sort_by_alpha : Icons.sort, size: 22, color: const Color(0xFF006400)),
                    onPressed: () {
                       setState(() => _sortAscending = !_sortAscending);
                       _fetchData();
                    },
                    tooltip: 'ترتيب',
                  ),
                  // Filter Button
                  IconButton(
                    icon: Icon(
                      Icons.filter_list, 
                      color: (_filterStatus != null || _filterHijriYear != null || _filterContractTypeId != null) 
                        ? Colors.blue 
                        : const Color(0xFF006400)
                    ),
                    onPressed: _showFilterSheet,
                    tooltip: 'فلترة متقدمة',
                  ),
                ],
              ),
            ),

            // Entries List with Group Headers
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => _fetchData(),
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: groupedEntries.length,
                  itemBuilder: (context, groupIndex) {
                    final groupKey = groupedEntries.keys.elementAt(groupIndex);
                    final groupItems = groupedEntries[groupKey]!;
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_groupBy != 'none')
                          Padding(
                            padding: const EdgeInsets.only(top: 16, bottom: 8, right: 8),
                            child: Text(
                              groupKey,
                              style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, color: const Color(0xFF006400), fontSize: 15),
                            ),
                          ),
                        ...groupItems.map((entry) => _buildEntryCard(entry)),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showFilterSheet() {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 20, right: 20, top: 20
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                         Text('فلترة متقدمة', style: GoogleFonts.tajawal(fontSize: 18, fontWeight: FontWeight.bold)),
                         IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                      ],
                   ),
                   const Divider(),
                   
                   // Status Filter
                   Text('حالة القيد', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 14)),
                   const SizedBox(height: 8),
                   Wrap(
                      spacing: 8,
                      children: [
                         {'label': 'الكل', 'value': null},
                         {'label': 'مسودة', 'value': 'draft'},
                         {'label': 'مسجل', 'value': 'registered_guardian'},
                         {'label': 'بانتظار التوثيق', 'value': 'pending_documentation'},
                         {'label': 'موثق', 'value': 'documented'},
                      ].map((s) {
                         bool isSelected = _filterStatus == s['value'];
                         return FilterChip(
                            label: Text(s['label'] as String, style: TextStyle(
                              fontSize: 12, 
                              color: isSelected ? Colors.white : Colors.black87
                            )),
                            selected: isSelected,
                            selectedColor: const Color(0xFF006400),
                            checkmarkColor: Colors.white,
                            onSelected: (sel) => setModalState(() => _filterStatus = sel ? s['value'] : null),
                         );
                      }).toList(),
                   ),
                   const SizedBox(height: 16),

                   // Hijri Year Filter
                   Row(
                     children: [
                       Expanded(
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             Text('السنة الهجرية', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 14)),
                             DropdownButton<int?>(
                                isExpanded: true,
                                value: _filterHijriYear,
                                items: [null, 1443, 1444, 1445, 1446, 1447].map((y) => DropdownMenuItem(
                                  value: y, 
                                  child: Text(y == null ? 'الكل' : '$y هـ')
                                )).toList(),
                                onChanged: (v) => setModalState(() => _filterHijriYear = v),
                             ),
                           ],
                         ),
                       ),
                       const SizedBox(width: 16),
                       Expanded(
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             Text('الشهر الهجري', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 14)),
                             DropdownButton<int?>(
                                isExpanded: true,
                                value: _filterHijriMonth,
                                items: [null, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12].map((m) => DropdownMenuItem(
                                  value: m, 
                                  child: Text(m == null ? 'الكل' : 'شهر $m')
                                )).toList(),
                                onChanged: (v) => setModalState(() => _filterHijriMonth = v),
                             ),
                           ],
                         ),
                       ),
                     ],
                   ),
                   const SizedBox(height: 16),

                   // Contract Type Filter
                   Text('نوع العقد', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 14)),
                   DropdownButton<int?>(
                      isExpanded: true,
                      value: _filterContractTypeId,
                      items: [
                         const DropdownMenuItem<int?>(value: null, child: Text('الكل')),
                         ..._contractTypes.map((t) => DropdownMenuItem<int?>(
                            value: t['id'] as int,
                            child: Text(t['name'] as String),
                         )),
                      ],
                      onChanged: (v) => setModalState(() => _filterContractTypeId = v),
                   ),
                   
                   const SizedBox(height: 24),
                   Row(
                     children: [
                       Expanded(
                         child: OutlinedButton(
                           onPressed: () {
                              setModalState(() {
                                 _filterStatus = null;
                                 _filterHijriYear = null;
                                 _filterHijriMonth = null;
                                 _filterContractTypeId = null;
                              });
                           },
                           child: const Text('مسح الكل'),
                         ),
                       ),
                       const SizedBox(width: 12),
                       Expanded(
                         flex: 2,
                         child: ElevatedButton(
                            onPressed: () {
                               Navigator.pop(context);
                               _fetchData();
                            },
                            style: ElevatedButton.styleFrom(
                               backgroundColor: const Color(0xFF006400),
                               padding: const EdgeInsets.symmetric(vertical: 15),
                               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                            ),
                            child: Text('تطبيق الفلترة', style: GoogleFonts.tajawal(color: Colors.white, fontWeight: FontWeight.bold)),
                         ),
                       ),
                     ],
                   ),
                ],
              ),
          ),
        ),
      );
  }

  Widget _buildEntryCard(RegistryEntry entry) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Contract Info
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${entry.firstParty} ضد ${entry.secondParty}',
                        style: GoogleFonts.tajawal(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${entry.contractType} | ${entry.dateHijri}هـ',
                        style: GoogleFonts.tajawal(
                            color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
                // Serial Number Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '#${entry.serialNumber ?? "-"}',
                    style: GoogleFonts.tajawal(
                        fontWeight: FontWeight.bold, color: Colors.grey[800]),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Statuses Row
            Row(
              children: [
                // Documentation Status
                _buildStatusBadge(
                  label: entry.statusLabel,
                  color: entry.statusColor,
                  icon: Icons.assignment_turned_in,
                ),
                const SizedBox(width: 12),
                // Delivery Status
                if (entry.deliveryStatusLabel != null)
                  _buildStatusBadge(
                    label: entry.deliveryStatusLabel!,
                    color: entry.deliveryStatusColor,
                    icon: Icons.local_shipping,
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Footer: View Details Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showEntryDetails(entry),
                icon: const Icon(Icons.visibility, size: 18),
                label: Text('عرض التفاصيل',
                    style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: Color(0xFF006400)),
                  foregroundColor: const Color(0xFF006400),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(
      {required String label, required Color color, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.tajawal(
                color: color, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _showEntryDetails(RegistryEntry entry) {
    if (entry.id == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EntryDetailsScreen(
          entryId: entry.id!, // Make sure your Entry model has 'id'
          entrySummary: entry, // Pass specific fields if needed
        ),
      ),
    ).then((_) {
        // Refresh list when coming back
        if (mounted) {
           Provider.of<RegistryEntryProvider>(context, listen: false).fetchEntries();
        }
    });
  }


}

// --- Tools Tab ---
class ToolsTab extends StatelessWidget {
  const ToolsTab({super.key});
  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('الأدوات - قريباً'));
}
