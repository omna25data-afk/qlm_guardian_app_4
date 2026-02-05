import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'admin_records_list_tab.dart';
import 'admin_entries_list_tab.dart';

class RecordsTab extends StatelessWidget {
  const RecordsTab({super.key});

  static const primaryColor = Color(0xFF006400);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          // Custom Tab Bar
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
            ),
            child: TabBar(
              labelColor: Colors.white,
              unselectedLabelColor: primaryColor,
              labelStyle: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 15),
              unselectedLabelStyle: GoogleFonts.tajawal(fontSize: 14),
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(
                  colors: [primaryColor, Color(0xFF008000)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorPadding: const EdgeInsets.all(4),
              dividerColor: Colors.transparent,
              splashBorderRadius: BorderRadius.circular(14),
              tabs: [
                Tab(
                  height: 46,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.book_outlined, size: 20),
                      const SizedBox(width: 8),
                      Text('السجلات', style: GoogleFonts.tajawal()),
                    ],
                  ),
                ),
                Tab(
                  height: 46,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.list_alt_outlined, size: 20),
                      const SizedBox(width: 8),
                      Text('القيود', style: GoogleFonts.tajawal()),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Tab Content
          const Expanded(
            child: TabBarView(
              children: [
                AdminRecordsListTab(),
                AdminEntriesListTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
