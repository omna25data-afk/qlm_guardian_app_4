import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:guardian_app/features/admin/data/models/admin_dashboard_data.dart';
import 'package:guardian_app/providers/admin_dashboard_provider.dart';
import 'package:provider/provider.dart';

class AdminDashboardTab extends StatefulWidget {
  const AdminDashboardTab({super.key});

  @override
  State<AdminDashboardTab> createState() => _AdminDashboardTabState();
}

class _AdminDashboardTabState extends State<AdminDashboardTab> with SingleTickerProviderStateMixin {
  late TabController _guardianStatsController;

  @override
  void initState() {
    super.initState();
    _guardianStatsController = TabController(length: 3, vsync: this);
    
    // Fetch data on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminDashboardProvider>(context, listen: false).fetchDashboard();
    });
  }

  @override
  void dispose() {
    _guardianStatsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminDashboardProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('حدث خطأ أثناء تحميل البيانات', style: GoogleFonts.tajawal()),
                Text(provider.error!, style: GoogleFonts.tajawal(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => provider.fetchDashboard(),
                  child: Text('إعادة المحاولة', style: GoogleFonts.tajawal()),
                )
              ],
            ),
          );
        }

        final data = provider.data;
        if (data == null) {
          return const Center(child: Text('لا توجد بيانات'));
        }

        return RefreshIndicator(
          onRefresh: () => provider.fetchDashboard(),
          child: Container(
            color: Colors.grey[50],
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 1. Welcome
                _buildSectionHeader('ملخص النظام', Icons.analytics),
                const SizedBox(height: 12),
                _buildSummaryCards(),
                
                const SizedBox(height: 24),
                
                // 2. Urgent Actions
                _buildSectionHeader('الإجراءات العاجلة ⚠️', Icons.notification_important, color: Colors.red),
                _buildUrgentActionsList(data.urgentActions),

                const SizedBox(height: 24),

                // 3. Guardians Data
                _buildSectionHeader('بيانات الأمناء والتراخيص', Icons.people),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      TabBar(
                        controller: _guardianStatsController,
                        labelColor: const Color(0xFF006400),
                        unselectedLabelColor: Colors.grey,
                        labelStyle: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
                        indicatorColor: const Color(0xFF006400),
                        tabs: const [
                          Tab(text: 'الأمناء'),
                          Tab(text: 'التراخيص'),
                          Tab(text: 'البطائق'),
                        ],
                      ),
                      SizedBox(
                        height: 280,
                        child: TabBarView(
                          controller: _guardianStatsController,
                          children: [
                            // A. Guardians
                            _buildGridStats([
                              _StatItem('إجمالي الأمناء', data.stats.guardians.total.toString(), Colors.blue, Icons.group),
                              _StatItem('على رأس العمل', data.stats.guardians.active.toString(), Colors.green, Icons.work),
                              _StatItem('متوقف عن العمل', data.stats.guardians.inactive.toString(), Colors.red, Icons.cancel),
                              _StatItem('غير ذلك', '0', Colors.orange, Icons.help_outline),
                            ]),
                            // B. Licenses
                            _buildGridStats([
                              _StatItem('إجمالي التراخيص', data.stats.licenses.total.toString(), Colors.indigo, Icons.card_membership),
                              _StatItem('سارية', data.stats.licenses.active.toString(), Colors.green, Icons.check_circle),
                              _StatItem('تنتهي قريباً', data.stats.licenses.warning.toString(), Colors.amber, Icons.warning),
                              _StatItem('منتهية', data.stats.licenses.inactive.toString(), Colors.red, Icons.error),
                            ]),
                            // C. Cards
                            _buildGridStats([
                              _StatItem('إجمالي البطائق', data.stats.cards.total.toString(), Colors.teal, Icons.badge),
                              _StatItem('سارية', data.stats.cards.active.toString(), Colors.green, Icons.check_circle),
                              _StatItem('تنتهي قريباً', data.stats.cards.warning.toString(), Colors.amber, Icons.warning),
                              _StatItem('منتهية', data.stats.cards.inactive.toString(), Colors.red, Icons.error),
                            ]),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 4. Logs
                _buildSectionHeader('آخر العمليات (Logs)', Icons.history),
                const SizedBox(height: 8),
                _buildLogsTab(), // Placeholder for now
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, {Color color = const Color(0xFF006400)}) {
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.tajawal(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
      ],
    );
  }

  Widget _buildSummaryCards() {
    return SizedBox(
      height: 140, // Height for chart placeholder
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.white,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.pie_chart, size: 40, color: Colors.grey),
              Text('مساحة للرسوم البيانية التاعلية', style: GoogleFonts.tajawal(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUrgentActionsList(List<UrgentAction> actions) {
    if (actions.isEmpty) {
      return Card(
        elevation: 0,
        color: Colors.green.withAlpha(20),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 8),
              Text('لا توجد إجراءات عاجلة', style: GoogleFonts.tajawal(color: Colors.green[800])),
            ],
          ),
        ),
      );
    }

    return Column(
      children: actions.map((action) => Card(
        elevation: 0,
        color: action.color.withAlpha(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side:BorderSide(color: action.color.withAlpha(50))),
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: Icon(Icons.warning_amber, color: action.color),
          title: Text(action.title, style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 14)),
          subtitle: Text(action.subtitle, style: GoogleFonts.tajawal(color: action.color)),
          trailing: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: action.color,
              elevation: 0,
              side: BorderSide(color: action.color),
              padding: const EdgeInsets.symmetric(horizontal: 12)
            ),
            child: Text(action.actionLabel, style: GoogleFonts.tajawal()),
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildGridStats(List<_StatItem> items) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // 2 cards per row
        childAspectRatio: 1.4, // Card ratio
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          decoration: BoxDecoration(
            color: item.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: item.color.withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item.icon, size: 32, color: item.color),
              const SizedBox(height: 8),
              Text(
                item.value,
                style: GoogleFonts.tajawal(fontSize: 24, fontWeight: FontWeight.bold, color: item.color),
              ),
              Text(
                item.title,
                textAlign: TextAlign.center,
                style: GoogleFonts.tajawal(fontSize: 14, color: Colors.grey[700]),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLogsTab() {
     return DefaultTabController(
       length: 2,
       child: Column(
         children: [
           TabBar(
             labelColor: Colors.black87,
             unselectedLabelColor: Colors.grey,
             labelStyle: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
             indicatorColor: Colors.blue,
             tabs: const [
               Tab(text: 'عملياتي (Admin)'),
               Tab(text: 'عمليات الأمناء'),
             ],
           ),
           SizedBox(
             height: 200,
             child: TabBarView(
               children: [
                 ListView(children: const [ListTile(title: Text('بيانات تجريبية'), leading: Icon(Icons.info))]),
                 ListView(children: const [ListTile(title: Text('لا توجد سجلات حالياً'), leading: Icon(Icons.history))]),
               ],
             ),
           )
         ],
       ),
     );
  }
}

class _StatItem {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  _StatItem(this.title, this.value, this.color, this.icon);
}
