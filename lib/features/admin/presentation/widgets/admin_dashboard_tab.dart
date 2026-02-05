import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:guardian_app/features/admin/data/models/admin_dashboard_data.dart';
import 'package:guardian_app/providers/admin_dashboard_provider.dart';
import 'package:provider/provider.dart';
import 'package:guardian_app/widgets/custom_tab_bar.dart';

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
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.error_outline, size: 48, color: Colors.red),
                ),
                const SizedBox(height: 16),
                Text('حدث خطأ أثناء تحميل البيانات', style: GoogleFonts.tajawal(fontSize: 16, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Text(provider.error!, style: GoogleFonts.tajawal(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => provider.fetchDashboard(),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: Text('إعادة المحاولة', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006400),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                )
              ],
            ),
          );
        }

        final data = provider.data;
        if (data == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text('لا توجد بيانات', style: GoogleFonts.tajawal(color: Colors.grey[600])),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.fetchDashboard(),
          color: const Color(0xFF006400),
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
                const SizedBox(height: 12),
                _buildUrgentActionsList(data.urgentActions),

                const SizedBox(height: 24),

                // 3. Guardians Data with Custom Tab Bar
                _buildSectionHeader('بيانات الأمناء والتراخيص', Icons.people),
                const SizedBox(height: 12),
                _buildGuardiansStatsSection(),

                const SizedBox(height: 24),

                // 4. Logs
                _buildSectionHeader('آخر العمليات', Icons.history),
                const SizedBox(height: 12),
                _buildLogsSection(),
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
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.tajawal(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
      ],
    );
  }

  Widget _buildSummaryCards() {
    return SizedBox(
      height: 140,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        color: Colors.white,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF006400).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.pie_chart, size: 32, color: Color(0xFF006400)),
              ),
              const SizedBox(height: 12),
              Text('مساحة للرسوم البيانية التفاعلية', style: GoogleFonts.tajawal(color: Colors.grey[600])),
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
        color: Colors.green.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: Colors.green.withValues(alpha: 0.2)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle, color: Colors.green, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('لا توجد إجراءات عاجلة', style: GoogleFonts.tajawal(color: Colors.green[800], fontWeight: FontWeight.bold)),
                    Text('جميع الأمور تسير بشكل جيد', style: GoogleFonts.tajawal(color: Colors.green[600], fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: actions.map((action) => Card(
        elevation: 0,
        color: action.color.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: action.color.withValues(alpha: 0.2)),
        ),
        margin: const EdgeInsets.only(bottom: 10),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: action.color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.warning_amber_rounded, color: action.color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(action.title, style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(action.subtitle, style: GoogleFonts.tajawal(color: action.color, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: action.color,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: action.color.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {},
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      child: Text(
                        action.actionLabel,
                        style: GoogleFonts.tajawal(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildGuardiansStatsSection() {
    final data = Provider.of<AdminDashboardProvider>(context).data!;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Custom Segmented Tab Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: CustomSegmentedTabBar(
              controller: _guardianStatsController,
              tabs: const ['الأمناء', 'التراخيص', 'البطائق'],
            ),
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
    );
  }

  Widget _buildGridStats(List<_StatItem> items) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.35,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                item.color.withValues(alpha: 0.08),
                item.color.withValues(alpha: 0.03),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: item.color.withValues(alpha: 0.15)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(item.icon, size: 24, color: item.color),
              ),
              const SizedBox(height: 10),
              Text(
                item.value,
                style: GoogleFonts.tajawal(fontSize: 26, fontWeight: FontWeight.bold, color: item.color),
              ),
              Text(
                item.title,
                textAlign: TextAlign.center,
                style: GoogleFonts.tajawal(fontSize: 12, color: Colors.grey[700]),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLogsSection() {
    return DefaultTabController(
      length: 2,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            // Use Custom Inline Tab Bar
            Builder(
              builder: (context) {
                return CustomInlineTabBar(
                  controller: DefaultTabController.of(context),
                  tabs: const ['عملياتي (Admin)', 'عمليات الأمناء'],
                  indicatorColor: Colors.blue,
                );
              },
            ),
            SizedBox(
              height: 200,
              child: TabBarView(
                children: [
                  _buildLogPlaceholder('لا توجد عمليات مسجلة حالياً', Icons.admin_panel_settings),
                  _buildLogPlaceholder('لا توجد سجلات حالياً', Icons.history),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildLogPlaceholder(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(message, style: GoogleFonts.tajawal(color: Colors.grey[500])),
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

