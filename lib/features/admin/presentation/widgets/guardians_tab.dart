import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GuardiansTab extends StatelessWidget {
  const GuardiansTab({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start, // Align tabs to start (Right)
              labelColor: Colors.white,
              unselectedLabelColor: const Color(0xFF006400),
              labelStyle: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 16), // Bigger font
              unselectedLabelStyle: GoogleFonts.tajawal(fontSize: 15, fontWeight: FontWeight.w500),
              indicatorSize: TabBarIndicatorSize.label,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                color: const Color(0xFF006400),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              labelPadding: const EdgeInsets.symmetric(horizontal: 16), // Bigger touch area
              tabs: const [
                Tab(text: 'الأمناء', height: 40),
                Tab(text: 'التراخيص', height: 40),
                Tab(text: 'البطائق', height: 40),
                Tab(text: 'مناطق الإختصاص', height: 40),
                Tab(text: 'التكليفات', height: 40),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildPlaceholder('قائمة الأمناء'),
                _buildPlaceholder('إدارة التراخيص'),
                _buildPlaceholder('إدارة البطائق'),
                _buildPlaceholder('مناطق الإختصاص'),
                _buildPlaceholder('التكليفات والمهام'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(String title) {
    return Center(
      child: Text(title, style: GoogleFonts.tajawal(fontSize: 18, color: Colors.grey)),
    );
  }
}
