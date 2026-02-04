import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:guardian_app/providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.currentUser;
        
        return Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                // Header with gradient and avatar
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF006400), Color(0xFF228B22)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          // Avatar
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.white,
                            backgroundImage: user?.avatarUrl != null 
                                ? NetworkImage(user!.avatarUrl!)
                                : null,
                            child: user?.avatarUrl == null 
                                ? const Icon(Icons.person, size: 50, color: Color(0xFF006400))
                                : null,
                          ),
                          const SizedBox(height: 16),
                          // Name
                          Text(
                            user?.guardianFullName ?? user?.name ?? 'الأمين الشرعي',
                            style: GoogleFonts.tajawal(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Register Number
                          if (user?.registerNumber != null)
                            Text(
                              'رقم السجل: ${user!.registerNumber}',
                              style: GoogleFonts.tajawal(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Status Cards
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // License Status Card
                      _buildStatusCard(
                        context,
                        icon: Icons.verified_user,
                        title: 'حالة الترخيص',
                        status: user?.licenseStatus ?? 'غير محدد',
                        color: _getStatusColor(user?.licenseStatus),
                      ),
                      const SizedBox(height: 12),
                      // Card Status
                      _buildStatusCard(
                        context,
                        icon: Icons.credit_card,
                        title: 'حالة البطاقة',
                        status: user?.cardStatus ?? 'غير محدد',
                        color: _getStatusColor(user?.cardStatus),
                      ),
                      const SizedBox(height: 24),
                      
                      // Info Section
                      _buildInfoSection(context, user),
                      
                      const SizedBox(height: 24),
                      
                      // Logout Button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await authProvider.logout();
                            if (context.mounted) {
                              Navigator.of(context).pushReplacementNamed('/login');
                            }
                          },
                          icon: const Icon(Icons.logout, color: Colors.red),
                          label: Text(
                            'تسجيل الخروج',
                            style: GoogleFonts.tajawal(color: Colors.red),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusCard(BuildContext context, {
    required IconData icon,
    required String title,
    required String status,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color.fromRGBO(color.r.toInt(), color.g.toInt(), color.b.toInt(), 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.tajawal(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    status,
                    style: GoogleFonts.tajawal(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context, dynamic user) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'معلومات الحساب',
              style: GoogleFonts.tajawal(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            _buildInfoRow(Icons.phone, 'رقم الجوال', user?.phoneNumber ?? '-'),
            _buildInfoRow(Icons.badge, 'رقم السجل', user?.registerNumber ?? '-'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.tajawal(color: Colors.grey[600]),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.tajawal(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    if (status == null) return Colors.grey;
    if (status.contains('ساري') || status.contains('نشط')) return Colors.green;
    if (status.contains('قريب')) return Colors.orange;
    if (status.contains('منتهي')) return Colors.red;
    return Colors.grey;
  }
}
