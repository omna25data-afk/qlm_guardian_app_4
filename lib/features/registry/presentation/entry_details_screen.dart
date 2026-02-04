import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/constants/api_constants.dart';
import 'package:guardian_app/features/registry/presentation/add_entry_screen.dart'; // Correct import path

class EntryDetailsScreen extends StatefulWidget {
  final int entryId;
  final dynamic entrySummary; // Optional: Initial basic data

  const EntryDetailsScreen({
    super.key,
    required this.entryId,
    this.entrySummary,
  });

  @override
  State<EntryDetailsScreen> createState() => _EntryDetailsScreenState();
}

class _EntryDetailsScreenState extends State<EntryDetailsScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _entryDetails;
  String? _errorMessage;
  bool _isRequestingDoc = false;

  @override
  void initState() {
    super.initState();
    _fetchEntryDetails();
  }

  Future<void> _fetchEntryDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Access provider just to ensure it's loaded if needed, though we seem to fetch API directly below.
      // If using provider method:
      // final provider = Provider.of<RegistryEntryProvider>(context, listen: false);
      // We need a method to get single entry. If not available in repo, we can call API directly here for now or add to repo.
      // Let's assume we call GET /registry-entries/{id}
      
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'auth_token');
      
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/registry-entries/${widget.entryId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest', // Important for Laravel
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _entryDetails = data['data'];
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to load entry details: ${response.statusCode}');
      }

    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _requestDocumentation() async {
    setState(() => _isRequestingDoc = true);
    
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'auth_token');

      final response = await http.put(
        Uri.parse('${ApiConstants.baseUrl}/registry-entries/${widget.entryId}/request-documentation'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم إرسال طلب التوثيق بنجاح ✅'), backgroundColor: Colors.green),
            );
            _fetchEntryDetails(); // Refresh to show new status
        }
      } else {
        if (mounted) {
            final error = json.decode(response.body);
            ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error['message'] ?? 'فشل الطلب'), backgroundColor: Colors.red),
            );
        }
      }
    } catch (e) {
      if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('خطأ في الاتصال: $e'), backgroundColor: Colors.red),
          );
      }
    } finally {
      if (mounted) setState(() => _isRequestingDoc = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('تفاصيل القيد')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('تفاصيل القيد')),
        body: Center(child: Text('خطأ: $_errorMessage')),
      );
    }

    final entry = _entryDetails!;
    final statusLabel = entry['status_label'] ?? '';
    final statusColorHex = entry['status_color']; // Usually coming as 'success', 'warning' etc string from Filament Resource if not mapped properly, but we modified backend enum to match Filament. Let's handle color.
    
    // Helper to parse color
    Color getStatusColor(dynamic colorData) {
        if (colorData == 'success') return Colors.green;
        if (colorData == 'warning') return Colors.orange;
        if (colorData == 'info') return Colors.blue;
        if (colorData == 'danger') return Colors.red;
        if (colorData == 'gray') return Colors.grey;
        // If it's an array RGB...
        return Colors.blueGrey;
    }

    final statusColor = getStatusColor(statusColorHex);
    final canEdit = entry['status'] == 'draft' || entry['status'] == 'registered_guardian';
    final canRequestDoc = canEdit && entry['status'] != 'pending_documentation';

    return Scaffold(
      appBar: AppBar(
        title: Text('القيد رقم #${entry['serial_number']}', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF006400),
        foregroundColor: Colors.white,
        actions: [
            if (canEdit)
                IconButton(
                    icon: const Icon(Icons.edit),
                    tooltip: 'تعديل',
                    onPressed: () {
                         // Navigate to edit
                         Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => AddEntryScreen(editEntryId: entry['id'])),
                         ).then((_) => _fetchEntryDetails());
                    },
                )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: statusColor),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('حالة القيد', style: GoogleFonts.tajawal(fontSize: 12, color: Colors.grey[700])),
                      Text(statusLabel, style: GoogleFonts.tajawal(fontSize: 18, fontWeight: FontWeight.bold, color: statusColor)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Basic Info
            _buildSectionHeader('البيانات الأساسية'),
            _buildInfoCard([
                _detailRow('نوع العقد', entry['contract_type']?['name'] ?? '-'),
                _detailRow('التاريخ الهجري', entry['document_date']?['hijri'] ?? '-'),
                _detailRow('التاريخ الميلادي', entry['document_date']?['gregorian'] ?? '-'),
                _detailRow('الطرف الأول', entry['first_party_name'] ?? '-'),
                _detailRow('الطرف الثاني', entry['second_party_name'] ?? '-'),
            ]),
            
            // Dynamic Details (Contract Data)
            if (entry['contract_details'] != null) ...[
                const SizedBox(height: 24),
                _buildSectionHeader('تفاصيل العقد'),
                _buildDynamicInfoCard(entry['contract_details']),
            ],
            
            // Record Info
             const SizedBox(height: 24),
            _buildSectionHeader('بيانات السجل'),
            _buildInfoCard([
                 _detailRow('دفتر السجل', entry['record_book']?['name'] ?? '-'),
                 _detailRow('رقم السجل', '${entry['record_book']?['number'] ?? '-'}'),
                 _detailRow('رقم الصفحة', '${entry['record_book']?['page_number'] ?? '-'}'),
                 _detailRow('رقم القيد', '${entry['record_book']?['entry_number'] ?? '-'}'),

            ]),

            const SizedBox(height: 32),
            
            // Actions
            if (canRequestDoc)
                SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber[800],
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isRequestingDoc ? null : _requestDocumentation,
                        icon: _isRequestingDoc ? const SizedBox(width:20, height:20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.verified_user, color: Colors.white),
                        label: Text(
                             _isRequestingDoc ? 'جاري الإرسال...' : 'طلب توثيق العقد',
                             style: GoogleFonts.tajawal(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                    ),
                ),
            
            if (!canEdit)
                Center(
                    child: Text(
                        'لا يمكن تعديل هذا القيد في الوقت الحالي',
                        style: GoogleFonts.tajawal(color: Colors.grey),
                    ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
      return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(title, style: GoogleFonts.tajawal(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
      );
  }

  Widget _buildInfoCard(List<Widget> children) {
      return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: children),
          ),
      );
  }

  Widget _buildDynamicInfoCard(Map<String, dynamic> data) {
      // Filter out ID fields and timestamps
      final keys = data.keys.where((k) => 
          !k.endsWith('_id') && 
          k != 'id' && 
          k != 'created_at' && 
          k != 'updated_at' && 
          k != 'deleted_at' &&
          k != 'registry_entry_id' &&
          data[k] != null
      ).toList();

      return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                  children: keys.map((key) {
                      // Format key to readable label (simple approach)
                      String label = key.replaceAll('_', ' '); // We rely on backend labels ideally, but this works for now
                      return _detailRow(label, '${data[key]}');
                  }).toList(),
              ),
          ),
      );
  }

  Widget _detailRow(String label, String value) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120, // Fixed width for labels
              child: Text(label,
                  style: GoogleFonts.tajawal(
                      color: Colors.grey[600], fontWeight: FontWeight.w500)),
            ),
            Expanded(
              child: Text(
                value,
                style: GoogleFonts.tajawal(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      );
  }
}
