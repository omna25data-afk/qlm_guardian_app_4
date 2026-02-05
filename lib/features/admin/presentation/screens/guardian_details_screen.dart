import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:guardian_app/features/admin/data/models/admin_guardian_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:guardian_app/features/admin/presentation/widgets/renew_card_sheet.dart';
import 'package:guardian_app/features/admin/presentation/widgets/renew_license_sheet.dart';
import 'package:guardian_app/features/admin/presentation/screens/guardian_renewals_screen.dart';

class GuardianDetailsScreen extends StatelessWidget {
  final AdminGuardian guardian;
  static const primaryColor = Color(0xFF006400);

  const GuardianDetailsScreen({super.key, required this.guardian});

  @override
  Widget build(BuildContext context) {
    final bool isActive = guardian.employmentStatus == 'على رأس العمل';
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // Custom App Bar with gradient
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor, Color(0xFF008000)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      // Avatar
                      Hero(
                        tag: 'guardian_${guardian.id}',
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.white,
                            backgroundImage: guardian.photoUrl != null 
                                ? NetworkImage(guardian.photoUrl!) 
                                : null,
                            child: guardian.photoUrl == null 
                                ? const Icon(Icons.person, size: 40, color: Colors.grey) 
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Name
                      Text(
                        guardian.name,
                        style: GoogleFonts.tajawal(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      // Serial & Status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              guardian.serialNumber,
                              style: GoogleFonts.tajawal(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: isActive ? Colors.green.shade300 : Colors.red.shade300,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isActive ? 'نشط' : 'متوقف',
                              style: GoogleFonts.tajawal(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.history),
                tooltip: 'سجل التجديدات',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => GuardianRenewalsScreen(guardian: guardian)),
                ),
              ),
            ],
          ),
          
          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Status Cards
                  _buildStatusCardsRow(),
                  const SizedBox(height: 16),
                  
                  // Quick Actions
                  _buildQuickActionsRow(context),
                  const SizedBox(height: 16),
                  
                  // Info Sections
                  _buildSection(
                    context,
                    title: 'المعلومات الشخصية',
                    icon: Icons.person_outline,
                    children: [
                      _buildGridItem('الاسم الكامل', guardian.name, isFullWidth: true),
                      _buildGridItem('اسم الأب', guardian.fatherName),
                      _buildGridItem('اسم الجد', guardian.grandfatherName),
                      _buildGridItem('اللقب', guardian.familyName),
                      if (guardian.greatGrandfatherName != null) 
                        _buildGridItem('الجد الكبير', guardian.greatGrandfatherName),
                      _buildGridItem('تاريخ الميلاد', guardian.birthDate),
                      _buildGridItem('مكان الميلاد', guardian.birthPlace),
                      _buildGridItem('هاتف المنزل', guardian.homePhone),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  _buildSection(
                    context,
                    title: 'الهوية والسكن',
                    icon: Icons.badge_outlined,
                    children: [
                      _buildGridItem('نوع الإثبات', guardian.proofType),
                      _buildGridItem('رقم الإثبات', guardian.proofNumber, isCopyable: true),
                      _buildGridItem('جهة الإصدار', guardian.issuingAuthority),
                      _buildGridItem('تاريخ الإصدار', guardian.issueDate),
                      _buildGridItem('تاريخ الانتهاء', guardian.expiryDate, color: guardian.identityStatusColor, makeBold: true),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  _buildSection(
                    context,
                    title: 'المهنة والترخيص',
                    icon: Icons.work_outline,
                    children: [
                      _buildGridItem('المؤهل العلمي', guardian.qualification),
                      _buildGridItem('الوظيفة', guardian.job),
                      _buildGridItem('جهة العمل', guardian.workplace),
                      if (guardian.experienceNotes?.isNotEmpty == true) 
                        _buildGridItem('ملاحظات الخبرة', guardian.experienceNotes, isFullWidth: true),
                      
                      _buildSectionDivider(context, 'الترخيص', onRenew: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => RenewLicenseSheet(guardian: guardian),
                        );
                      }),
                      _buildGridItem('رقم القرار', guardian.ministerialDecisionNumber),
                      _buildGridItem('تاريخ القرار', guardian.ministerialDecisionDate),
                      _buildGridItem('رقم الترخيص', guardian.licenseNumber, isCopyable: true),
                      _buildGridItem('تاريخ انتهائه', guardian.licenseExpiryDate, color: guardian.licenseStatusColor, makeBold: true),
                      
                      _buildSectionDivider(context, 'بطاقة المهنة', onRenew: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => RenewCardSheet(guardian: guardian),
                        );
                      }),
                      _buildGridItem('رقم البطاقة', guardian.professionCardNumber, isCopyable: true),
                      _buildGridItem('تاريخ انتهائها', guardian.professionCardExpiryDate, color: guardian.cardStatusColor, makeBold: true),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  _buildSection(
                    context,
                    title: 'المواقع والملاحظات',
                    icon: Icons.map_outlined,
                    children: [
                      if (guardian.mainDistrictName != null) 
                        _buildGridItem('عزلة الاختصاص', guardian.mainDistrictName, isFullWidth: true),
                      if (guardian.villages != null && guardian.villages!.isNotEmpty)
                        _buildListChips('القرى', guardian.villages!.map((e) => e['name'] as String).toList()),
                      if (guardian.localities != null && guardian.localities!.isNotEmpty)
                        _buildListChips('المحلات', guardian.localities!.map((e) => e['name'] as String).toList()),
                      
                      _buildSectionDivider(context, 'الحالة'),
                      _buildGridItem('الحالة الوظيفية', guardian.employmentStatus, color: _parseStatusColor(guardian.employmentStatusColor), makeBold: true),
                      if (guardian.stopDate != null) ...[
                        _buildGridItem('تاريخ التوقف', guardian.stopDate, color: Colors.red),
                        _buildGridItem('سبب التوقف', guardian.stopReason, isFullWidth: true),
                      ],
                      if (guardian.notes?.isNotEmpty == true)
                        _buildGridItem('ملاحظات', guardian.notes, isFullWidth: true),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCardsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatusCard(
            'الهوية',
            guardian.identityStatusColor,
            guardian.identityRemainingDays,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatusCard(
            'الترخيص',
            guardian.licenseStatusColor,
            guardian.licenseRemainingDays,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatusCard(
            'البطاقة',
            guardian.cardStatusColor,
            guardian.cardRemainingDays,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard(String title, Color color, int? remainingDays) {
    String statusText = 'سارية';
    if (remainingDays != null) {
      if (remainingDays < 0) {
        statusText = 'منتهية';
      } else if (remainingDays <= 30) {
        statusText = '$remainingDays يوم';
      } else if (remainingDays <= 90) {
        statusText = 'قريباً';
      }
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
            child: Center(
              child: remainingDays != null && remainingDays <= 90
                  ? Text(
                      remainingDays < 0 ? '!' : '$remainingDays',
                      style: GoogleFonts.tajawal(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: remainingDays.abs() > 99 ? 11 : 13,
                      ),
                    )
                  : Icon(Icons.check, color: color, size: 20),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.tajawal(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            statusText,
            style: GoogleFonts.tajawal(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsRow(BuildContext context) {
    return Row(
      children: [
        if (guardian.phone != null)
          Expanded(
            child: _buildQuickActionButton(
              context,
              icon: Icons.phone,
              label: 'اتصال',
              color: Colors.green,
              onTap: () => launchUrl(Uri.parse('tel:${guardian.phone}')),
            ),
          ),
        if (guardian.phone != null) const SizedBox(width: 10),
        Expanded(
          child: _buildQuickActionButton(
            context,
            icon: Icons.refresh,
            label: 'تجديد',
            color: Colors.orange,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => GuardianRenewalsScreen(guardian: guardian)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.tajawal(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, {required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: primaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.tajawal(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: children,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionDivider(BuildContext context, String label, {VoidCallback? onRenew}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.tajawal(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: primaryColor,
            ),
          ),
          const Spacer(),
          if (onRenew != null)
            TextButton.icon(
              onPressed: onRenew,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                backgroundColor: Colors.orange.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.refresh, size: 16, color: Colors.orange),
              label: Text(
                'تجديد',
                style: GoogleFonts.tajawal(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGridItem(String label, String? value, {bool isFullWidth = false, bool isCopyable = false, Color? color, bool makeBold = false}) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    
    return SizedBox(
      width: isFullWidth ? double.infinity : 140,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.tajawal(
              color: Colors.grey[500],
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          SelectableText(
            value,
            style: GoogleFonts.tajawal(
              color: color ?? Colors.black87,
              fontSize: 13,
              fontWeight: makeBold ? FontWeight.bold : FontWeight.w500,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListChips(String title, List<String> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.tajawal(color: Colors.grey[500], fontSize: 11),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items.map((tag) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
              ),
              child: Text(
                tag,
                style: GoogleFonts.tajawal(
                  color: primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Color _parseStatusColor(dynamic color) {
    if (color is Color) return color;
    if (color is String) {
      if (color.startsWith('#')) {
        return Color(int.parse(color.substring(1), radix: 16) + 0xFF000000);
      }
      switch (color.toLowerCase()) {
        case 'green': return Colors.green;
        case 'red': return Colors.red;
        case 'orange': return Colors.orange;
        case 'blue': return Colors.blue;
        case 'grey': return Colors.grey;
        default: return Colors.black;
      }
    }
    return Colors.black;
  }
}
