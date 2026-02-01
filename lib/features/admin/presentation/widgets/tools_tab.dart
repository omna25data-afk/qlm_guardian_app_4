import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ToolsTab extends StatelessWidget {
  const ToolsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.build, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('الأدوات المساعدة', style: GoogleFonts.tajawal(fontSize: 18, color: Colors.grey)),
          Text('(قيد التطوير)', style: GoogleFonts.tajawal(fontSize: 14, color: Colors.grey[400])),
        ],
      ),
    );
  }
}
