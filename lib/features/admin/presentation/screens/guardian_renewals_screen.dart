import 'package:flutter/material.dart';
import 'package:guardian_app/features/admin/data/models/admin_guardian_model.dart';
import 'package:provider/provider.dart';
import 'package:guardian_app/providers/admin_renewals_provider.dart';

class GuardianRenewalsScreen extends StatefulWidget {
  final AdminGuardian guardian;

  const GuardianRenewalsScreen({super.key, required this.guardian});

  @override
  State<GuardianRenewalsScreen> createState() => _GuardianRenewalsScreenState();
}

class _GuardianRenewalsScreenState extends State<GuardianRenewalsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Re-fetch guardian to ensure we have latest renewals if needed, 
    // but typically we pass the latest guardian.
    // Ideally, we might want to listen to provider here if guardian updates.
    // We use the passed guardian for now as AdminGuardianProvider is not available/renamed.
    // If live updates are needed, we should listen to AdminRenewalsProvider if it holds the guardian state.
    // For now, simple fallback.
    final currentGuardian = widget.guardian;

    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل التجديدات', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'تجديد الترخيص'),
            Tab(text: 'تجديد البطاقة'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRenewalsList(currentGuardian.licenseRenewals, isLicense: true),
          _buildRenewalsList(currentGuardian.cardRenewals, isLicense: false),
        ],
      ),
    );
  }

  Widget _buildRenewalsList(List<Map<String, dynamic>>? renewals, {required bool isLicense}) {
    if (renewals == null || renewals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isLicense ? Icons.verified_user_outlined : Icons.badge_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text('No records found', style: TextStyle(fontFamily: 'Tajawal', color: Colors.grey)),
          ],
        ),
      );
    }

    // Sort by renewal date desc
    final sortedRenewals = List<Map<String, dynamic>>.from(renewals);
    sortedRenewals.sort((a, b) {
      final dateA = a['renewal_date'] ?? '';
      final dateB = b['renewal_date'] ?? '';
      return dateB.compareTo(dateA); 
    });

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: sortedRenewals.length,
      separatorBuilder: (ctx, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = sortedRenewals[index];
        return _buildRenewalItem(item, isLicense);
      },
    );
  }

  Widget _buildRenewalItem(Map<String, dynamic> item, bool isLicense) {
    // Assuming backend returns these fields. Adjust based on exact API response.
    final renewalNumber = item['renewal_number'] ?? '-';
    final renewalDate = item['renewal_date'] ?? '-';
    final expiryDate = item['expiry_date'] ?? '-';
    final receiptNumber = item['receipt_number'];
    final notes = item['notes'];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isLicense ? Colors.blue.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isLicense ? Icons.verified_user : Icons.badge,
                        color: isLicense ? Colors.blue : Colors.orange,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('التجديد رقم $renewalNumber', 
                             style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(renewalDate, 
                             style: TextStyle(fontFamily: 'Tajawal', color: Colors.grey[600], fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('مكتمل', style: TextStyle(fontFamily: 'Tajawal', color: Colors.green, fontSize: 12)),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                _buildInfoColumn('تاريخ الانتهاء', expiryDate),
                if (receiptNumber != null) ...[
                   const SizedBox(width: 24),
                   _buildInfoColumn('رقم الإيصال', receiptNumber.toString()),
                ]
              ],
            ),
             if (notes != null && notes.toString().isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('ملاحظات: $notes', style: TextStyle(fontFamily: 'Tajawal', color: Colors.grey[600], fontSize: 13)),
             ]
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontFamily: 'Tajawal', color: Colors.grey[500], fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w600, fontSize: 14)),
      ],
    );
  }
}
