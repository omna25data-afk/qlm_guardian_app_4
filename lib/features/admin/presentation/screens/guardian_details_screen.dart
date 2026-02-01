import 'package:flutter/material.dart';
import 'package:guardian_app/features/admin/data/models/admin_guardian_model.dart';
import 'package:url_launcher/url_launcher.dart';

class GuardianDetailsScreen extends StatelessWidget {
  final AdminGuardian guardian;

  const GuardianDetailsScreen({super.key, required this.guardian});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ملف الأمين', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(context),
            _buildStatusSummary(context),
            const Divider(),
            _buildTabs(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Row(
        children: [
          Hero(
            tag: 'guardian_${guardian.id}',
            child: CircleAvatar(
              radius: 40,
              backgroundColor: Colors.grey[200],
              backgroundImage: guardian.photoUrl != null ? NetworkImage(guardian.photoUrl!) : null,
              child: guardian.photoUrl == null ? const Icon(Icons.person, size: 40, color: Colors.grey) : null,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(guardian.name, style: const TextStyle(fontFamily: 'Tajawal', fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('الرقم التسلسلي: ${guardian.serialNumber}', style: TextStyle(fontFamily: 'Tajawal', color: Colors.grey[600])),
                const SizedBox(height: 4),
                 if (guardian.phone != null)
                  InkWell(
                    onTap: () => launchUrl(Uri.parse('tel:${guardian.phone}')),
                    child: Row(
                      children: [
                         const Icon(Icons.phone, size: 16, color: Colors.blue),
                         const SizedBox(width: 4),
                         Text(guardian.phone!, style: const TextStyle(fontFamily: 'Tajawal', color: Colors.blue)),
                      ],
                    ),
                  )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSummary(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatusChip('الهوية', guardian.identityStatusColor),
          _buildStatusChip('الترخيص', guardian.licenseStatusColor),
          _buildStatusChip('البطاقة', guardian.cardStatusColor),
          _buildStatusChip('الحالة', _parseStatusColor(guardian.employmentStatusColor)),
        ],
      ),
    );
  }
  
  Color _parseStatusColor(String? colorName) {
    if (colorName == null) return Colors.grey;
    switch (colorName.toLowerCase()) {
      case 'danger':
      case 'red': return Colors.red;
      case 'warning':
      case 'orange': return Colors.orange;
      case 'success':
      case 'green': return Colors.green;
      case 'primary':
      case 'blue': return Colors.blue;
      default: return Colors.grey;
    }
  }

  Widget _buildStatusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontFamily: 'Tajawal', fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildTabs(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          const TabBar(
            labelFamily: 'Tajawal',
            isScrollable: true,
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: 'المعلومات الشخصية'),
              Tab(text: 'الهوية والسكن'),
              Tab(text: 'المهنة والترخيص'),
              Tab(text: 'المناطق والملاحظات'),
            ],
          ),
          SizedBox(
            height: 500, // Fixed height for tab view
            child: TabBarView(
              children: [
                _buildPersonalInfoTab(),
                _buildIdentityTab(),
                _buildProfessionalTab(),
                _buildAreasTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildInfoTile('الاسم الكامل', guardian.name),
        _buildInfoTile('اسم الأب', guardian.fatherName),
        _buildInfoTile('اسم الجد', guardian.grandfatherName),
        _buildInfoTile('اللقب', guardian.familyName),
        if (guardian.greatGrandfatherName != null) _buildInfoTile('الجد الكبير', guardian.greatGrandfatherName),
        const Divider(),
        _buildInfoTile('تاريخ الميلاد', guardian.birthDate),
        _buildInfoTile('مكان الميلاد', guardian.birthPlace),
        _buildInfoTile('هاتف المنزل', guardian.homePhone),
      ],
    );
  }

  Widget _buildIdentityTab() {
     return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildInfoTile('نوع الإثبات', guardian.proofType),
        _buildInfoTile('رقم الإثبات', guardian.proofNumber, isCopyable: true),
        _buildInfoTile('جهة الإصدار', guardian.issuingAuthority),
        _buildInfoTile('تاريخ الإصدار', guardian.issueDate),
        _buildInfoTile('تاريخ الانتهاء', guardian.expiryDate, color: guardian.identityStatusColor),
      ],
    );
  }

  Widget _buildProfessionalTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildInfoTile('المؤهل العلمي', guardian.qualification),
        _buildInfoTile('الوظيفة', guardian.job),
        _buildInfoTile('جهة العمل', guardian.workplace),
        if (guardian.experienceNotes?.isNotEmpty == true) _buildInfoTile('ملاحظات الخبرة', guardian.experienceNotes),
        const Divider(),
        const Text('الترخيص', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 16)),
        _buildInfoTile('رقم القرار الوزاري', guardian.ministerialDecisionNumber),
        _buildInfoTile('تاريخ القرار', guardian.ministerialDecisionDate),
        _buildInfoTile('رقم الترخيص', guardian.licenseNumber, isCopyable: true),
        _buildInfoTile('تاريخ إصدار الترخيص', guardian.licenseIssueDate),
        _buildInfoTile('تاريخ انتهاء الترخيص', guardian.licenseExpiryDate, color: guardian.licenseStatusColor),
        const Divider(),
        const Text('بطاقة المهنة', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 16)),
        _buildInfoTile('رقم البطاقة', guardian.professionCardNumber, isCopyable: true),
        _buildInfoTile('تاريخ الإصدار', guardian.professionCardIssueDate),
        _buildInfoTile('تاريخ الانتهاء', guardian.professionCardExpiryDate, color: guardian.cardStatusColor),
      ],
    );
  }

  Widget _buildAreasTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (guardian.mainDistrictName != null)
           _buildInfoTile('عزلة الاختصاص', guardian.mainDistrictName),
        
        if (guardian.villages != null && guardian.villages!.isNotEmpty)
           _buildInfoTile('القرى', guardian.villages!.map((e) => e['name']).join('، ')),

        if (guardian.localities != null && guardian.localities!.isNotEmpty)
           _buildInfoTile('المحلات', guardian.localities!.map((e) => e['name']).join('، ')),

        const Divider(),
        _buildInfoTile('الحالة الوظيفية', guardian.employmentStatus, color: _parseStatusColor(guardian.employmentStatusColor)),
        if (guardian.stopDate != null) ...[
           _buildInfoTile('تاريخ التوقف', guardian.stopDate, color: Colors.red),
           _buildInfoTile('سبب التوقف', guardian.stopReason),
        ],
        const Divider(),
        _buildInfoTile('ملاحظات', guardian.notes),
      ],
    );
  }

  Widget _buildInfoTile(String label, String? value, {bool isCopyable = false, Color? color}) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label, 
              style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, color: Colors.grey[700])
            )
          ),
          Expanded(
            child: SelectableText(
              value, 
              style: TextStyle(fontFamily: 'Tajawal', color: color ?? Colors.black87, fontWeight: color != null ? FontWeight.bold : FontWeight.normal)
            ),
          ),
        ],
      ),
    );
  }
}
