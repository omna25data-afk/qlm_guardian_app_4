import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:guardian_app/core/constants/api_constants.dart';

import 'package:guardian_app/features/auth/data/repositories/auth_repository.dart';
import 'package:guardian_app/features/records/data/models/record_book.dart'; // Updated import
import 'package:guardian_app/features/records/data/models/record_book_template.dart';
import 'package:guardian_app/features/registry/presentation/registry_entries_screen.dart';

class RecordBookNotebooksScreen extends StatefulWidget {
  final int contractTypeId;
  final String contractTypeName;

  const RecordBookNotebooksScreen({
    super.key,
    required this.contractTypeId,
    required this.contractTypeName,
  });

  @override
  State<RecordBookNotebooksScreen> createState() => _RecordBookNotebooksScreenState();
}

class _RecordBookNotebooksScreenState extends State<RecordBookNotebooksScreen> {
  bool _isLoading = true;
  List<RecordBook> _notebooks = []; // Updated type

  @override
  void initState() {
    super.initState();
    _fetchNotebooks();
  }

  Future<void> _fetchNotebooks() async {
    setState(() => _isLoading = true);
    try {
      final authRepo = Provider.of<AuthRepository>(context, listen: false);
      final token = await authRepo.getToken();
      
      final response = await http.get(
        Uri.parse(ApiConstants.notebooks(widget.contractTypeId)),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          _notebooks = List<RecordBook>.from(
              data['data'].map((x) => RecordBook.fromJson(x)));
          _isLoading = false;
        });
      } else {
         _showError('فشل تحميل الدفاتر');
      }
    } catch (e) {
      _showError('حدث خطأ: $e');
    }
  }

  void _showInfoDialog(RecordBook notebook) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('معلومات السجل', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoItem(Icons.book, 'رقم الدفتر المرجعي', '${notebook.bookNumber}'),
            _buildInfoItem(Icons.list_alt, 'إجمالي عدد القيود', '${notebook.entriesCount}'),
            _buildInfoItem(Icons.account_balance, 'رقم سجل وزارة العدل', notebook.ministryRecordNumber ?? 'غير محدد'),
            _buildInfoItem(Icons.description, 'قالب السجل المعتمد', notebook.templateName ?? 'غير محدد'),
            _buildInfoItem(Icons.calendar_today, 'سنة الصرف للهيئة', notebook.issuanceYear != null ? '${notebook.issuanceYear} هـ' : 'غير محدد'),
            _buildInfoItem(Icons.history, 'سنوات العمل والقيود', notebook.years.join('، ')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إغلاق', style: GoogleFonts.tajawal()),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF006400)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.tajawal(fontSize: 12, color: Colors.grey[600])),
                Text(value, style: GoogleFonts.tajawal(fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showError(String msg) {
    if (mounted) {
       setState(() => _isLoading = false);
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  void _openEditDialog(RecordBook notebook) {
    showDialog(
      context: context,
      builder: (ctx) => EditNotebookDialog(
        notebook: notebook,
        contractTypeId: widget.contractTypeId,
        onSave: () {
           Navigator.pop(ctx);
           _fetchNotebooks(); // Refresh
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.contractTypeName, style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF006400),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: _isLoading 
         ? const Center(child: CircularProgressIndicator())
         : _notebooks.isEmpty
             ? Center(child: Text('لا توجد دفاتر لهذا السجل', style: GoogleFonts.tajawal(fontSize: 16)))
             : RefreshIndicator(
                 onRefresh: _fetchNotebooks,
                 child: ListView.builder(
                   padding: const EdgeInsets.all(16),
                   itemCount: _notebooks.length,
                   itemBuilder: (context, index) {
                     final book = _notebooks[index];
                     return _buildNotebookCard(book);
                   },
                 ),
               ),
    );
  }

  Widget _buildNotebookCard(RecordBook book) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${book.bookNumber}',
                    style: GoogleFonts.tajawal(
                        fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF006400)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الدفتر رقم ${book.bookNumber}',
                        style: GoogleFonts.tajawal(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'عدد القيود والمحررات: ${book.entriesCount}',
                        style: GoogleFonts.tajawal(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                   onSelected: (v) {
                      if (v == 'edit') {
                         _openEditDialog(book);
                      } else if (v == 'info') {
                         _showInfoDialog(book);
                      } else if (v == 'view') {
                         Navigator.push(context, MaterialPageRoute(
                            builder: (context) => RegistryEntriesScreen(
                               bookNumber: book.bookNumber,
                               recordBookId: book.id,
                               contractTypeId: widget.contractTypeId,
                               title: 'قيود الدفتر رقم ${book.bookNumber}',
                            ),
                         ));
                      }
                   },
                   itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'view',
                        child: Row(children: [Icon(Icons.visibility, size: 18), SizedBox(width: 8), Text('عرض القيود')]),
                      ),
                      const PopupMenuItem(
                         value: 'info',
                         child: Row(children: [Icon(Icons.info_outline, size: 18), SizedBox(width: 8), Text('معلومات السجل')]),
                      ),
                      const PopupMenuItem(
                         value: 'edit',
                         child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('تعديل البيانات')]),
                      ),
                   ],
                ),
              ],
            ),
            const Divider(height: 24),
            _buildDetailRow(Icons.account_balance, 'رقم السجل بالوزارة', book.ministryRecordNumber ?? 'غير محدد'),
            const SizedBox(height: 8),
            _buildDetailRow(Icons.description, 'القالب المستخدم', book.templateName ?? 'غير محدد'),
            const SizedBox(height: 8),
            _buildDetailRow(Icons.calendar_today, 'سنة الصرف', book.issuanceYear != null ? '${book.issuanceYear} هـ' : 'غير محدد'),
             const SizedBox(height: 8),
            _buildDetailRow(Icons.history, 'السنوات', book.years.join('، ')),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Text('$label: ', style: GoogleFonts.tajawal(fontSize: 13, color: Colors.grey[700])),
        Expanded(
           child: Text(value, style: GoogleFonts.tajawal(fontSize: 13, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

class EditNotebookDialog extends StatefulWidget {
  final RecordBook notebook;
  final int contractTypeId;
  final VoidCallback onSave;

  const EditNotebookDialog({
    super.key, 
    required this.notebook, 
    required this.contractTypeId, 
    required this.onSave
  });

  @override
  State<EditNotebookDialog> createState() => _EditNotebookDialogState();
}

class _EditNotebookDialogState extends State<EditNotebookDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _ministryNumController;
  late TextEditingController _issuanceYearController;
  int? _selectedTemplateId;
  List<RecordBookTemplate> _templates = [];
  bool _isLoadingTemplates = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _ministryNumController = TextEditingController(text: widget.notebook.ministryRecordNumber);
    _issuanceYearController = TextEditingController(
       text: widget.notebook.issuanceYear?.toString() ?? ''
    );
    _selectedTemplateId = widget.notebook.templateId;
    _fetchTemplates();
  }
  
  @override 
  void dispose() {
    _ministryNumController.dispose();
    _issuanceYearController.dispose();
    super.dispose();
  }

  Future<void> _fetchTemplates() async {
    try {
      final authRepo = Provider.of<AuthRepository>(context, listen: false);
      final token = await authRepo.getToken();
      
      final response = await http.get(
        Uri.parse(ApiConstants.templates),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (mounted) {
           setState(() {
             _templates = List<RecordBookTemplate>.from(
                data['data'].map((x) => RecordBookTemplate.fromJson(x)));
             _isLoadingTemplates = false;
           });
        }
      }
    } catch (e) {
       if (mounted) setState(() => _isLoadingTemplates = false);
    }
  }

  Future<void> _save() async {
     if (!_formKey.currentState!.validate()) return;
     
     setState(() => _isSaving = true);
     try {
       final authRepo = Provider.of<AuthRepository>(context, listen: false);
       final token = await authRepo.getToken();
       
       final body = {
          'contract_type_id': widget.contractTypeId,
          'book_number': widget.notebook.bookNumber,
          'ministry_record_number': _ministryNumController.text,
          'template_id': _selectedTemplateId,
          'issuance_year': int.tryParse(_issuanceYearController.text),
       };
       
       final response = await http.post(
          Uri.parse(ApiConstants.updateNotebook),
          headers: {
             'Authorization': 'Bearer $token',
             'Content-Type': 'application/json',
             'Accept': 'application/json'
          },
          body: jsonEncode(body),
       );
       
       if (response.statusCode == 200) {
          widget.onSave();
       } else {
          if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فشل التحديث')));
          }
       }
     } catch (e) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
        }
     } finally {
        if (mounted) setState(() => _isSaving = false);
     }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('تعديل بيانات الدفتر', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold), textAlign: TextAlign.right),
      content: SingleChildScrollView(
         child: Form(
           key: _formKey,
           child: Column(
             mainAxisSize: MainAxisSize.min,
             children: [
                TextFormField(
                   controller: _ministryNumController,
                   decoration: const InputDecoration(
                      labelText: 'رقم السجل بالوزارة',
                      border: OutlineInputBorder(),
                   ),
                ),
                const SizedBox(height: 12),
                
                TextFormField(
                   controller: _issuanceYearController,
                   keyboardType: TextInputType.number,
                   decoration: const InputDecoration(
                      labelText: 'سنة الصرف (هجري)',
                      border: OutlineInputBorder(),
                      helperText: 'السنة التي تم فيها صرف السجل',
                   ),
                ),
                const SizedBox(height: 12),

                _isLoadingTemplates 
                   ? const Center(child: CircularProgressIndicator())
                   : DropdownButtonFormField<int>(
                       initialValue: _selectedTemplateId,
                       decoration: const InputDecoration(
                          labelText: 'القالب',
                          border: OutlineInputBorder(),
                       ),
                       items: _templates.map((t) => DropdownMenuItem(
                          value: t.id,
                          child: Text(t.name, overflow: TextOverflow.ellipsis),
                       )).toList(),
                       onChanged: (v) => setState(() => _selectedTemplateId = v),
                       isExpanded: true,
                   ),
             ],
           ),
         ),
      ),
      actions: [
         TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: GoogleFonts.tajawal(color: Colors.grey)),
         ),
         ElevatedButton(
            onPressed: _isSaving ? null : _save,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF006400)),
            child: _isSaving 
               ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
               : Text('حفظ', style: GoogleFonts.tajawal(color: Colors.white)),
         ),
      ],
    );
  }
}
