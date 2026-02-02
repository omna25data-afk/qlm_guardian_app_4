import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
// import 'package:guardian_app/core/utils/validators.dart';
import 'package:guardian_app/features/admin/data/models/admin_guardian_model.dart';
import 'package:guardian_app/providers/admin_renewals_provider.dart';



class RenewLicenseSheet extends StatefulWidget {
  final AdminGuardian guardian;

  const RenewLicenseSheet({super.key, required this.guardian});

  @override
  State<RenewLicenseSheet> createState() => _RenewLicenseSheetState();
}

class _RenewLicenseSheetState extends State<RenewLicenseSheet> {
  final _formKey = GlobalKey<FormState>();
  final _renewalDateController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _receiptNumberController = TextEditingController();
  final _receiptAmountController = TextEditingController();
  final _receiptDateController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _renewalDateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  @override
  void dispose() {
    _renewalDateController.dispose();
    _expiryDateController.dispose();
    _receiptNumberController.dispose();
    _receiptAmountController.dispose();
    _receiptDateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        controller.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final data = {
        'guardian_id': widget.guardian.id,
        'renewal_date': _renewalDateController.text,
        'expiry_date': _expiryDateController.text,
        'receipt_number': _receiptNumberController.text,
        'receipt_amount': _receiptAmountController.text,
        'receipt_date': _receiptDateController.text,
        'notes': _notesController.text,
      };

      await Provider.of<AdminRenewalsProvider>(context, listen: false)
          .submitLicenseRenewal(widget.guardian.id, data);

      // Refresh Guardian Details to show updated info
       if (mounted) {
         // await Provider.of<AdminGuardianProvider>(context, listen: false)
         //  .fetchGuardianDetails(widget.guardian.id);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تجديد الترخيص بنجاح', style: TextStyle(fontFamily: 'Tajawal'))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e', style: const TextStyle(fontFamily: 'Tajawal'))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('تجديد الترخيص', style: TextStyle(fontFamily: 'Tajawal', fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                   Expanded(
                    child: TextFormField(
                      controller: _renewalDateController,
                      decoration: const InputDecoration(labelText: 'تاريخ التجديد', prefixIcon: Icon(Icons.calendar_today)),
                      readOnly: true,
                      onTap: () => _selectDate(_renewalDateController),
                      validator: (value) => value!.isEmpty ? 'مطلوب' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _expiryDateController,
                      decoration: const InputDecoration(labelText: 'تاريخ الانتهاء', prefixIcon: Icon(Icons.event_busy)),
                      readOnly: true,
                      onTap: () => _selectDate(_expiryDateController),
                      validator: (value) => value!.isEmpty ? 'مطلوب' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _receiptNumberController,
                      decoration: const InputDecoration(labelText: 'رقم الإيصال'),
                    ),
                  ),
                  const SizedBox(width: 12),
                   Expanded(
                    child: TextFormField(
                      controller: _receiptDateController,
                      decoration: const InputDecoration(labelText: 'تاريخ الإيصال', prefixIcon: Icon(Icons.calendar_today)),
                      readOnly: true,
                      onTap: () => _selectDate(_receiptDateController),
                    ),
                  ),
                ],
              ),
               const SizedBox(height: 12),
              TextFormField(
                controller: _receiptAmountController,
                decoration: const InputDecoration(labelText: 'المبلغ', suffixText: 'ر.ي'),
                keyboardType: TextInputType.number,
              ),
               const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'ملاحظات'),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('حفظ التجديد', style: TextStyle(fontFamily: 'Tajawal', fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class RenewCardSheet extends StatefulWidget {
  final AdminGuardian guardian;

  const RenewCardSheet({super.key, required this.guardian});

  @override
  State<RenewCardSheet> createState() => _RenewCardSheetState();
}

class _RenewCardSheetState extends State<RenewCardSheet> {
  final _formKey = GlobalKey<FormState>();
  final _renewalDateController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _receiptNumberController = TextEditingController();
  final _receiptAmountController = TextEditingController();
  final _receiptDateController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _renewalDateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  @override
  void dispose() {
    _renewalDateController.dispose();
    _expiryDateController.dispose();
    _receiptNumberController.dispose();
    _receiptAmountController.dispose();
    _receiptDateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        controller.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final data = {
        'guardian_id': widget.guardian.id,
        'renewal_date': _renewalDateController.text,
        'expiry_date': _expiryDateController.text,
        'receipt_number': _receiptNumberController.text,
        'receipt_amount': _receiptAmountController.text,
        'receipt_date': _receiptDateController.text,
        'notes': _notesController.text,
      };

      await Provider.of<AdminRenewalsProvider>(context, listen: false)
          .submitCardRenewal(widget.guardian.id, data);

      // Refresh Guardian Details
      if (mounted) {
         // await Provider.of<AdminGuardianProvider>(context, listen: false)
         //  .fetchGuardianDetails(widget.guardian.id);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تجديد البطاقة بنجاح', style: TextStyle(fontFamily: 'Tajawal'))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e', style: const TextStyle(fontFamily: 'Tajawal'))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('تجديد البطاقة', style: TextStyle(fontFamily: 'Tajawal', fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                   Expanded(
                    child: TextFormField(
                      controller: _renewalDateController,
                      decoration: const InputDecoration(labelText: 'تاريخ التجديد', prefixIcon: Icon(Icons.calendar_today)),
                      readOnly: true,
                      onTap: () => _selectDate(_renewalDateController),
                      validator: (value) => value!.isEmpty ? 'مطلوب' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _expiryDateController,
                      decoration: const InputDecoration(labelText: 'تاريخ الانتهاء', prefixIcon: Icon(Icons.event_busy)),
                      readOnly: true,
                      onTap: () => _selectDate(_expiryDateController),
                      validator: (value) => value!.isEmpty ? 'مطلوب' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _receiptNumberController,
                      decoration: const InputDecoration(labelText: 'رقم الإيصال'),
                    ),
                  ),
                  const SizedBox(width: 12),
                   Expanded(
                    child: TextFormField(
                      controller: _receiptDateController,
                      decoration: const InputDecoration(labelText: 'تاريخ الإيصال', prefixIcon: Icon(Icons.calendar_today)),
                      readOnly: true,
                      onTap: () => _selectDate(_receiptDateController),
                    ),
                  ),
                ],
              ),
               const SizedBox(height: 12),
              TextFormField(
                controller: _receiptAmountController,
                decoration: const InputDecoration(labelText: 'المبلغ', suffixText: 'ر.ي'),
                keyboardType: TextInputType.number,
              ),
               const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'ملاحظات'),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('حفظ التجديد', style: TextStyle(fontFamily: 'Tajawal', fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
