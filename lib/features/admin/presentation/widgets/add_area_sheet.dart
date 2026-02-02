import 'package:flutter/material.dart';
import 'package:guardian_app/features/admin/data/models/admin_area_model.dart';
import 'package:guardian_app/features/admin/data/repositories/admin_areas_repository.dart';
import 'package:provider/provider.dart';

class AddAreaSheet extends StatefulWidget {
  final AdminAreasRepository repository;
  final VoidCallback onSuccess;

  const AddAreaSheet({super.key, required this.repository, required this.onSuccess});

  @override
  State<AddAreaSheet> createState() => _AddAreaSheetState();
}

class _AddAreaSheetState extends State<AddAreaSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  
  String _selectedType = 'عزلة'; // Default to Azla (District)
  AdminArea? _selectedParent;
  List<AdminArea> _parentOptions = [];
  bool _isLoadingParents = false;
  bool _isSubmitting = false;

  final List<String> _types = ['عزلة', 'قرية', 'محل'];

  @override
  void initState() {
    super.initState();
  }

  void _onTypeChanged(String? newValue) {
    if (newValue == null) return;
    setState(() {
      _selectedType = newValue;
      _selectedParent = null;
      _parentOptions = [];
    });

    if (_selectedType != 'عزلة') {
      _fetchParents();
    }
  }

  Future<void> _fetchParents() async {
    setState(() => _isLoadingParents = true);
    try {
      String parentType = _selectedType == 'قرية' ? 'عزلة' : 'قرية';
      
      // Fetch all potential parents (using pagination workaround or search)
      // Ideally we should have a non-paginated endpoint or search.
      // For now, we fetch 'search' with empty query which usually returns 1st page. 
      // User might need to search if list is long.
      // We will fetch specifically by type.
      final parents = await widget.repository.getAreas(type: parentType);
      
      setState(() {
        _parentOptions = parents;
      });
    } catch (e) {
      // Handle error
    } finally {
      setState(() => _isLoadingParents = false);
    }
  }
  
  // Implement search for parents if list is long, using Autocomplete or similar?
  // stick to simple dropdown for now as per "simple add form" request, 
  // but if list is huge, I might need SearchDelegate.

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedType != 'عزلة' && _selectedParent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار الأب (المنطقة التابع لها)')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final data = {
        'name': _nameController.text,
        'type': _selectedType,
        'parent_id': _selectedParent?.id,
        'is_active': true,
      };

      await widget.repository.createArea(data);
      
      if (mounted) {
        widget.onSuccess();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تمت الإضافة بنجاح')),
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
                'إضافة منطقة جغرافية',
                style: TextStyle(fontFamily: 'Tajawal', fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(labelText: 'نوع المنطقة'),
                items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: _onTypeChanged,
              ),
              const SizedBox(height: 16),

              if (_selectedType != 'عزلة') ...[
                 DropdownButtonFormField<AdminArea>(
                  value: _selectedParent,
                  decoration: InputDecoration(
                    labelText: _selectedType == 'قرية' ? 'تابع للعزلة' : 'تابع للقرية',
                    suffixIcon: _isLoadingParents ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : null,
                  ),
                  items: _parentOptions.map((area) => DropdownMenuItem(value: area, child: Text(area.name))).toList(),
                  onChanged: (val) => setState(() => _selectedParent = val),
                  hint: const Text('اختر...'),
                 ),
                 const SizedBox(height: 16),
              ],
              
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'اسم المنطقة'),
                validator: (val) => val == null || val.isEmpty ? 'مطلوب' : null,
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
                    : const Text('إضافة', style: TextStyle(fontFamily: 'Tajawal', fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
