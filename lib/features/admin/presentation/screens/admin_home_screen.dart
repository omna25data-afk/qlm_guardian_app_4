import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:guardian_app/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:guardian_app/features/admin/presentation/widgets/admin_dashboard_tab.dart';
import 'package:guardian_app/features/admin/presentation/screens/admin_guardians_management_screen.dart';
import 'package:guardian_app/features/admin/presentation/widgets/records_tab.dart';
import 'package:guardian_app/features/admin/presentation/widgets/reports_tab.dart';
import 'package:guardian_app/features/admin/presentation/widgets/tools_tab.dart';
import 'package:guardian_app/widgets/custom_dropdown_menu.dart';

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
    final isWideScreen = MediaQuery.of(context).size.width > 400;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF006400),
        automaticallyImplyLeading: false, 
        toolbarHeight: MediaQuery.of(context).size.height > 600 ? 80 : 60,
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
                    fontSize: isWideScreen ? 20 : 16,
                    height: 1.2
                  )
                ),
              ),
              Text(
                'رئيس قلم التوثيق',
                style: GoogleFonts.tajawal(
                  textStyle: textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                    fontSize: isWideScreen ? 12 : 10
                  )
                ),
              ),
            ],
          ),
        ),
        actions: [
          // Notifications Button
          _buildAppBarIconButton(
            icon: Icons.notifications_outlined,
            onPressed: () {},
            badge: 3,
          ),
          const SizedBox(width: 8),
          // Profile Menu
          Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: CustomDropdownMenuWithHeader(
              offset: const Offset(0, 60),
              menuWidth: 260,
              trigger: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  backgroundImage: user?.avatarUrl != null 
                      ? NetworkImage(user!.avatarUrl!) 
                      : const AssetImage('assets/images/placeholder_avatar.png') as ImageProvider,
                  radius: isWideScreen ? 20 : 16,
                  backgroundColor: Colors.grey[200],
                ),
              ),
              header: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: user?.avatarUrl != null 
                        ? NetworkImage(user!.avatarUrl!) 
                        : const AssetImage('assets/images/placeholder_avatar.png') as ImageProvider,
                    backgroundColor: Colors.grey[200],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'الرئيس',
                          style: GoogleFonts.tajawal(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF006400),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'رئيس القلم',
                            style: GoogleFonts.tajawal(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              items: [
                CustomMenuItem(
                  label: 'الملف الشخصي',
                  icon: Icons.person_outline,
                  onTap: () {
                    // Navigate to profile
                  },
                ),
                CustomMenuItem(
                  label: 'الإعدادات',
                  icon: Icons.settings_outlined,
                  onTap: () {
                    // Navigate to settings
                  },
                ),
                CustomMenuItem(
                  label: 'الوضع الليلي',
                  icon: Icons.dark_mode_outlined,
                  onTap: () {
                    // Toggle dark mode
                  },
                ),
                CustomMenuItem.divider(),
                CustomMenuItem(
                  label: 'تسجيل الخروج',
                  icon: Icons.logout,
                  isDestructive: true,
                  onTap: () {
                    Provider.of<AuthProvider>(context, listen: false).logout();
                    Navigator.of(context).pushReplacementNamed('/login');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: _buildBottomNavBar(isWideScreen),
    );
  }

  Widget _buildAppBarIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    int? badge,
  }) {
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(icon, color: Colors.white, size: 24),
            onPressed: onPressed,
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          ),
        ),
        if (badge != null && badge > 0)
          Positioned(
            right: 4,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF006400), width: 2),
              ),
              constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
              child: Text(
                badge > 9 ? '9+' : badge.toString(),
                style: GoogleFonts.tajawal(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBottomNavBar(bool isWideScreen) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.dashboard_outlined, Icons.dashboard, 'الرئيسية', isWideScreen),
              _buildNavItem(1, Icons.group_outlined, Icons.group, 'الأمناء', isWideScreen),
              _buildNavItem(2, Icons.source_outlined, Icons.source, 'السجلات', isWideScreen),
              _buildNavItem(3, Icons.analytics_outlined, Icons.analytics, 'التقارير', isWideScreen),
              _buildNavItem(4, Icons.build_outlined, Icons.build, 'الأدوات', isWideScreen),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label, bool isWideScreen) {
    final isSelected = _selectedIndex == index;
    
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected 
              ? const Color(0xFF006400).withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? const Color(0xFF006400) : Colors.grey,
              size: isWideScreen ? 26 : 22,
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.tajawal(
                  color: const Color(0xFF006400),
                  fontWeight: FontWeight.bold,
                  fontSize: isWideScreen ? 13 : 11,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
