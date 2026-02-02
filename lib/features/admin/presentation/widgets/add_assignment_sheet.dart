import 'package:flutter/material.dart';
import 'package:guardian_app/features/admin/data/models/admin_area_model.dart';
import 'package:guardian_app/features/admin/data/models/admin_guardian_model.dart';
import 'package:guardian_app/features/admin/data/repositories/admin_areas_repository.dart';
import 'package:guardian_app/features/admin/data/repositories/admin_assignments_repository.dart';
import 'package:guardian_app/features/admin/data/repositories/admin_guardian_repository.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class AddAssignmentSheet extends StatefulWidget {
  final VoidCallback onSuccess;

  const AddAssignmentSheet({super.key, required this.onSuccess});

  @override
  State<AddAssignmentSheet> createState() => _AddAssignmentSheetState();
}

class _AddAssignmentSheetState extends State<AddAssignmentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  final _notesController = TextEditingController();

  
  String _assignmentType = 'temporary_delegation';
  AdminGuardian? _selectedGuardian;
  AdminArea? _selectedArea;
  
  List<AdminGuardian> _guardianOptions = [];
  List<AdminArea> _areaOptions = [];
  
  bool _isLoadingGuardians = false;
  bool _isLoadingAreas = false;
  bool _isSubmitting = false;

  late AdminGuardianRepository _guardianRepo;
  late AdminAreasRepository _areasRepo;
  late AdminAssignmentsRepository _assignmentsRepo;

  @override
  void initState() {
    super.initState();
    _startDateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _guardianRepo = Provider.of<AdminGuardianRepository>(context);
    // Assuming these are provided, if not we will safeguard or get from similar place
    // But typically repositories are provided at root.
    _areasRepo = Provider.of<AdminAreasRepository>(context);
    _assignmentsRepo = Provider.of<AdminAssignmentsRepository>(context);
  }

  Future<void> _searchGuardians(String query) async {
    if (query.length < 2) return;
    setState(() => _isLoadingGuardians = true);
    try {
      final results = await _guardianRepo.getGuardians(page: 1, searchQuery: query);
      setState(() => _guardianOptions = results);
    } catch (e) {
      // ignore error
    } finally {
      setState(() => _isLoadingGuardians = false);
    }
  }

  Future<void> _searchAreas(String query) async {
    if (query.length < 2) return;
    setState(() => _isLoadingAreas = true);
    try {
      final results = await _areasRepo.getAreas(page: 1, searchQuery: query);
      setState(() => _areaOptions = results);
    } catch (e) {
      // ignore error
    } finally {
      setState(() => _isLoadingAreas = false);
    }
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2030),
      locale: const Locale('ar', 'SA'),
    );
    if (date != null) {
      controller.text = DateFormat('yyyy-MM-dd').format(date);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Check selections
    if (_selectedGuardian == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى اختيار الأمين')));
      return;
    }
    if (_selectedArea == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى اختيار المنطقة')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final data = {
        'assigned_guardian_id': _selectedGuardian!.id,
        'geographic_area_id': _selectedArea!.id,
        'assignment_type': _assignmentType,
        'start_date': _startDateController.text,
        'end_date': _endDateController.text.isNotEmpty ? _endDateController.text : null,
        'notes': _notesController.text,
      };

      await _assignmentsRepo.createAssignment(data);
      
      if (mounted) {
        widget.onSuccess();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إنشاء التكليف بنجاح')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16, 
        right: 16,
        top: 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'إضافة تكليف جديد',
                style: TextStyle(fontFamily: 'Tajawal', fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // Assignment Type
              DropdownButtonFormField<String>(
                 initialValue: _assignmentType,
                decoration: const InputDecoration(labelText: 'نوع التكليف'),
                items: const [
                    DropdownMenuItem(value: 'temporary_delegation', child: Text('تكليف مؤقت')),
                    DropdownMenuItem(value: 'permanent_transfer', child: Text('نقل دائم')),
                ],
                onChanged: (val) => setState(() => _assignmentType = val!),
              ),
              const SizedBox(height: 16),

              // Guardian Search Autocomplete
              Autocomplete<AdminGuardian>(
                 optionsBuilder: (textEditingValue) {
                   _searchGuardians(textEditingValue.text);
                   // Return cached options or wait for future builder?
                   // Autocomplete expects synchronous return or simple iterable. 
                   // Better to use a simpler approach or custom typeahead.
                   // For now, let's use the options populated by state.
                   if (textEditingValue.text.isEmpty) return const Iterable<AdminGuardian>.empty();
                   return _guardianOptions.where((option) => option.name.contains(textEditingValue.text));
                 },
                 displayStringForOption: (option) => option.name,
                 onSelected: (selection) => setState(() => _selectedGuardian = selection),
                 fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                   return TextField(
                     controller: controller,
                     focusNode: focusNode,
                     onEditingComplete: onEditingComplete,
                     decoration: InputDecoration(
                        labelText: 'الأمين',
                        suffixIcon: _isLoadingGuardians ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : null,
                        hintText: 'ابحث بالاسم...'
                     ),
                     onChanged: _searchGuardians,
                   );
                 },
                 optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4,
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width - 32,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(8),
                            shrinkWrap: true,
                            itemCount: options.length,
                            itemBuilder: (context, index) {
                               final option = options.elementAt(index);
                               return ListTile(
                                 title: Text(option.name),
                                 subtitle: Text('رقم: ${option.serialNumber}'),
                                 onTap: () => onSelected(option),
                               );
                            }
                          ),
                        ),
                      ),
                    );
                 },
              ),
              if (_selectedGuardian != null)
                 Padding(
                   padding: const EdgeInsets.symmetric(vertical: 4),
                   child: Text('تم اختيار: ${_selectedGuardian!.name}', style: const TextStyle(color: Colors.green, fontSize: 12)),
                 ),
              
              const SizedBox(height: 16),

              // Area Search Autocomplete
               Autocomplete<AdminArea>(
                 optionsBuilder: (textEditingValue) {
                   _searchAreas(textEditingValue.text);
                   if (textEditingValue.text.isEmpty) return const Iterable<AdminArea>.empty();
                   return _areaOptions.where((option) => option.name.contains(textEditingValue.text));
                 },
                 displayStringForOption: (option) => option.name,
                 onSelected: (selection) => setState(() => _selectedArea = selection),
                 fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                   return TextField(
                     controller: controller,
                     focusNode: focusNode,
                     onEditingComplete: onEditingComplete,
                     decoration: InputDecoration(
                        labelText: 'المنطقة (محل العمل)',
                        suffixIcon: _isLoadingAreas ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : null,
                         hintText: 'ابحث باسم المنطقة...'
                     ),
                     onChanged: _searchAreas,
                   );
                 },
                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4,
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width - 32,
                           child: ListView.builder(
                            padding: const EdgeInsets.all(8),
                            shrinkWrap: true,
                            itemCount: options.length,
                            itemBuilder: (context, index) {
                               final option = options.elementAt(index);
                               return ListTile(
                                 title: Text(option.name),
                                 subtitle: Text(option.type),
                                 onTap: () => onSelected(option),
                               );
                            }
                          ),
                        ),
                      ),
                    );
                 },
              ),
              if (_selectedArea != null)
                 Padding(
                   padding: const EdgeInsets.symmetric(vertical: 4),
                   child: Text('تم اختيار: ${_selectedArea!.name}', style: const TextStyle(color: Colors.green, fontSize: 12)),
                 ),

              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _startDateController,
                      decoration: const InputDecoration(labelText: 'تاريخ البدء', suffixIcon: Icon(Icons.calendar_today)),
                      readOnly: true,
                      onTap: () => _pickDate(_startDateController),
                      validator: (val) => val == null || val.isEmpty ? 'مطلوب' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _endDateController,
                      decoration: const InputDecoration(labelText: 'تاريخ الانتهاء (اختياري)', suffixIcon: Icon(Icons.calendar_today)),
                      readOnly: true,
                      onTap: () => _pickDate(_endDateController),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'ملاحظات'),
                maxLines: 2,
              ),
              const SizedBox(height: 30),
              
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: Theme.of(context).primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isSubmitting
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('حفظ التكليف', style: TextStyle(fontFamily: 'Tajawal', fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
