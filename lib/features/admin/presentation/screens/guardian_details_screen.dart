import 'package:flutter/material.dart';
import 'package:guardian_app/features/admin/data/models/admin_guardian_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:guardian_app/features/admin/presentation/widgets/renewal_forms.dart';
import 'package:guardian_app/features/admin/presentation/screens/guardian_renewals_screen.dart';

class GuardianDetailsScreen extends StatelessWidget {
  final AdminGuardian guardian;

  const GuardianDetailsScreen({super.key, required this.guardian});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Soft background
      appBar: AppBar(
        title: const Text('ملف الأمين', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'سجل التجديدات',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GuardianRenewalsScreen(guardian: guardian))),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildHeaderCard(context),
            const SizedBox(height: 16),
            _buildSection(
              context,
              title: 'المعلومات الشخصية',
              icon: Icons.person_outline,
              children: [
                _buildGridItem(context, 'الاسم الكامل', guardian.name, isFullWidth: true),
                _buildGridItem(context, 'اسم الأب', guardian.fatherName),
                _buildGridItem(context, 'اسم الجد', guardian.grandfatherName),
                _buildGridItem(context, 'اللقب', guardian.familyName),
                if (guardian.greatGrandfatherName != null) _buildGridItem(context, 'الجد الكبير', guardian.greatGrandfatherName),
                _buildGridItem(context, 'تاريخ الميلاد', guardian.birthDate),
                _buildGridItem(context, 'مكان الميلاد', guardian.birthPlace),
                _buildGridItem(context, 'هاتف المنزل', guardian.homePhone),
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
               context,
               title: 'الهوية والسكن',
               icon: Icons.badge_outlined,
               children: [
                 _buildGridItem(context, 'نوع الإثبات', guardian.proofType),
                 _buildGridItem(context, 'رقم الإثبات', guardian.proofNumber, isCopyable: true),
                 _buildGridItem(context, 'جهة الإصدار', guardian.issuingAuthority),
                 _buildGridItem(context, 'تاريخ الإصدار', guardian.issueDate),
                 _buildGridItem(context, 'تاريخ الانتهاء', guardian.expiryDate, color: guardian.identityStatusColor, makeBold: true),
               ]
            ),
            const SizedBox(height: 16),
             _buildSection(
               context,
               title: 'المهنة والترخيص',
               icon: Icons.work_outline,
               children: [
                 _buildGridItem(context, 'المؤهل العلمي', guardian.qualification),
                 _buildGridItem(context, 'الوظيفة', guardian.job),
                 _buildGridItem(context, 'جهة العمل', guardian.workplace),
                 if (guardian.experienceNotes?.isNotEmpty == true) _buildGridItem(context, 'ملاحظات الخبرة', guardian.experienceNotes, isFullWidth: true),
                 
                 _buildSectionDivider(context, 'الترخيص', onRenew: () {
                    showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => RenewLicenseSheet(guardian: guardian));
                 }),
                 _buildGridItem(context, 'رقم القرار', guardian.ministerialDecisionNumber),
                 _buildGridItem(context, 'تاريخ القرار', guardian.ministerialDecisionDate),
                 _buildGridItem(context, 'رقم الترخيص', guardian.licenseNumber, isCopyable: true),
                 _buildGridItem(context, 'تاريخ انتهائه', guardian.licenseExpiryDate, color: guardian.licenseStatusColor, makeBold: true),
                 
                 _buildSectionDivider(context, 'بطاقة المهنة', onRenew: () {
                    showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => RenewCardSheet(guardian: guardian));
                 }),
                 _buildGridItem(context, 'رقم البطاقة', guardian.professionCardNumber, isCopyable: true),
                 _buildGridItem(context, 'تاريخ انتهائها', guardian.professionCardExpiryDate, color: guardian.cardStatusColor, makeBold: true),
               ]
            ),
             const SizedBox(height: 16),
             _buildSection(
               context,
               title: 'المواقع والملاحظات',
               icon: Icons.map_outlined,
               children: [
                  if (guardian.mainDistrictName != null) _buildGridItem(context, 'عزلة الاختصاص', guardian.mainDistrictName, isFullWidth: true),
                  if (guardian.villages != null && guardian.villages!.isNotEmpty)
                     _buildListChips(context, 'القرى', guardian.villages!.map((e) => e['name'] as String).toList()),
                   if (guardian.localities != null && guardian.localities!.isNotEmpty)
                     _buildListChips(context, 'المحلات', guardian.localities!.map((e) => e['name'] as String).toList()),
                   
                   _buildSectionDivider(context, 'الحالة'),
                   _buildGridItem(context, 'الحالة الوظيفية', guardian.employmentStatus, color: _parseStatusColor(guardian.employmentStatusColor), makeBold: true),
                    if (guardian.stopDate != null) ...[
                       _buildGridItem(context, 'تاريخ التوقف', guardian.stopDate, color: Colors.red),
                       _buildGridItem(context, 'سبب التوقف', guardian.stopReason, isFullWidth: true),
                    ],
                    if (guardian.notes?.isNotEmpty == true)
                      _buildGridItem(context, 'ملاحظات', guardian.notes, isFullWidth: true),
               ]
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24), // Soft edges
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
            Row(
              children: [
                Hero(
                  tag: 'guardian_${guardian.id}',
                  child: Container(
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.grey[200]!, width: 2)),
                    child: CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.grey[100],
                      backgroundImage: guardian.photoUrl != null ? NetworkImage(guardian.photoUrl!) : null,
                      child: guardian.photoUrl == null ? const Icon(Icons.person, size: 35, color: Colors.grey) : null,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(guardian.name, style: const TextStyle(fontFamily: 'Tajawal', fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8)),
                        child: Text('الرقم: ${guardian.serialNumber}', style: const TextStyle(fontFamily: 'Tajawal', color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
                 if (guardian.phone != null)
                  IconButton(
                    onPressed: () => launchUrl(Uri.parse('tel:${guardian.phone}')),
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.phone, color: Colors.green, size: 20),
                    ),
                  )
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatusItem('الهوية', guardian.identityStatusColor),
                _buildStatusItem('الترخيص', guardian.licenseStatusColor),
                _buildStatusItem('البطاقة', guardian.cardStatusColor),
              ],
            ),
        ],
      )
    );
  }

  Widget _buildStatusItem(String label, Color color) {
    return Column(
      children: [
        Container(
          width: 12, height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2), boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 6)]),
        ),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(fontFamily: 'Tajawal', color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }

  Widget _buildSection(BuildContext context, {required String title, required IconData icon, required List<Widget> children}) {
     return Container(
       decoration: BoxDecoration(
         color: Colors.white,
         borderRadius: BorderRadius.circular(20),
         border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
         boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
       ),
       padding: const EdgeInsets.all(20),
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).primaryColor),
                const SizedBox(width: 10),
                Text(title, style: TextStyle(fontFamily: 'Tajawal', fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
              ],
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: children,
            )
         ],
       ),
     );
  }

  Widget _buildSectionDivider(BuildContext context, String label, {VoidCallback? onRenew}) {
     return Container(
       width: double.infinity,
       padding: const EdgeInsets.symmetric(vertical: 8),
       child: Row(
         mainAxisAlignment: MainAxisAlignment.spaceBetween,
         children: [
           Text(label, style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 14, color: Theme.of(context).primaryColor)),
           if (onRenew != null)
             TextButton.icon(
              onPressed: onRenew,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('تجديد', style: TextStyle(fontFamily: 'Tajawal', fontSize: 12)),
             )
         ],
       ),
     );
  }

  Widget _buildGridItem(BuildContext context, String label, String? value, {bool isFullWidth = false, bool isCopyable = false, Color? color, bool makeBold = false}) {
     if (value == null || value.isEmpty) return const SizedBox.shrink();
     
     
     return SizedBox(
       width: isFullWidth ? double.infinity : 140, // Fixed width for 2 columns on most phones
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
           Text(label, style: TextStyle(fontFamily: 'Tajawal', color: Colors.grey[500], fontSize: 11)),
           const SizedBox(height: 4),
           SelectableText(
             value, 
             style: TextStyle(
               fontFamily: 'Tajawal', 
               color: color ?? Colors.black87, 
               fontSize: 13, 
               fontWeight: makeBold ? FontWeight.bold : FontWeight.w500,
               height: 1.4
             )
           )
         ],
       ),
     );
  }
  
  // Need to fix context access in _buildGridItem above or pass it. 
  // Refactoring to helper function usage correctly.
}

  Widget _buildListChips(BuildContext context, String title, List<String> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontFamily: 'Tajawal', color: Colors.grey[500], fontSize: 11)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((tag) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.blue.withValues(alpha: 0.1))),
            child: Text(tag, style: TextStyle(color: Colors.blue[800], fontSize: 12, fontFamily: 'Tajawal')),
          )).toList(),
        ),
      ],
    );
  }

  Color _parseStatusColor(Color color) => color;
}

