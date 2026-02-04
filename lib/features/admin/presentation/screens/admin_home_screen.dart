import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:guardian_app/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:guardian_app/features/admin/presentation/widgets/admin_dashboard_tab.dart';
import 'package:guardian_app/features/admin/presentation/screens/admin_guardians_management_screen.dart';
import 'package:guardian_app/features/admin/presentation/widgets/records_tab.dart';
import 'package:guardian_app/features/admin/presentation/widgets/reports_tab.dart';
import 'package:guardian_app/features/admin/presentation/widgets/tools_tab.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const AdminDashboardTab(),
    const AdminGuardiansManagementScreen(),
    const RecordsTab(),
    const ReportsTab(),
    const ToolsTab(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF006400),
        automaticallyImplyLeading: false, 
        toolbarHeight: MediaQuery.of(context).size.height > 600 ? 80 : 60, // Responsive height
        centerTitle: false,
        title: Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'مرحباً، ${user?.name ?? "الرئيس"}',
                style: GoogleFonts.tajawal(
                  textStyle: textTheme.titleLarge?.copyWith(
                    color: Colors.white, 
                    fontWeight: FontWeight.bold,
                    fontSize: MediaQuery.of(context).size.width > 400 ? 20 : 16, // Responsive font
                    height: 1.2
                  )
                ),
              ),
              Text(
                'رئيس قلم التوثيق',
                style: GoogleFonts.tajawal(
                  textStyle: textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                    fontSize: MediaQuery.of(context).size.width > 400 ? 12 : 10
                  )
                ),
              ),
            ],
          ),
        ),
        actions: [
           IconButton(
            icon: Icon(Icons.notifications, color: Colors.white, size: MediaQuery.of(context).size.width > 400 ? 28 : 24),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: PopupMenuButton<String>(
              offset: const Offset(0, 50),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: CircleAvatar(
                  backgroundImage: user?.avatarUrl != null 
                      ? NetworkImage(user!.avatarUrl!) 
                      : const AssetImage('assets/images/placeholder_avatar.png') as ImageProvider,
                  radius: MediaQuery.of(context).size.width > 400 ? 20 : 16,
                ),
              ),
              onSelected: (value) {
                if (value == 'logout') {
                  Provider.of<AuthProvider>(context, listen: false).logout();
                  Navigator.of(context).pushReplacementNamed('/login');
                }
              },
              itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'profile',
                    child: Row(
                      children: [
                        Icon(Icons.person, color: Colors.grey[700]), 
                        const SizedBox(width: 8), 
                        Text('الملف الشخصي', style: GoogleFonts.tajawal(fontSize: 16))
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'settings',
                    child: Row(
                      children: [
                        Icon(Icons.settings, color: Colors.grey[700]), 
                        const SizedBox(width: 8), 
                        Text('الإعدادات', style: GoogleFonts.tajawal(fontSize: 16))
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'dark_mode',
                    child: Row(
                      children: [
                        Icon(Icons.nightlight_round, color: Colors.grey[700]), 
                        const SizedBox(width: 8), 
                        Text('الوضع الليلي', style: GoogleFonts.tajawal(fontSize: 16))
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        const Icon(Icons.logout, color: Colors.red), 
                        const SizedBox(width: 8), 
                        Text('تسجيل الخروج', style: GoogleFonts.tajawal(color: Colors.red, fontSize: 16))
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: SafeArea(
          child: BottomNavigationBar(
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'الرئيسية'),
              BottomNavigationBarItem(icon: Icon(Icons.group), label: 'الأمناء'),
              BottomNavigationBarItem(icon: Icon(Icons.source), label: 'السجلات'),
              BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'التقارير'),
              BottomNavigationBarItem(icon: Icon(Icons.build), label: 'الأدوات'),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: const Color(0xFF006400),
            unselectedItemColor: Colors.grey,
            showUnselectedLabels: true,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent, 
            elevation: 0,
            iconSize: MediaQuery.of(context).size.width > 400 ? 28 : 24, // Responsive icons
            onTap: _onItemTapped,
            selectedLabelStyle: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: MediaQuery.of(context).size.width > 400 ? 12 : 10),
            unselectedLabelStyle: GoogleFonts.tajawal(fontSize: MediaQuery.of(context).size.width > 400 ? 10 : 9),
          ),
        ),
        ),
    );
  }
}
