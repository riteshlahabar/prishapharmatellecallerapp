import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../providers/call_log_provider.dart';

class CallLogCreateScreen extends ConsumerStatefulWidget {
  const CallLogCreateScreen({super.key});

  @override
  ConsumerState<CallLogCreateScreen> createState() => _CallLogCreateScreenState();
}

class _CallLogCreateScreenState extends ConsumerState<CallLogCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customerController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedResult = 'completed';
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _submitting = false;

  final _results = [
    {'value': 'completed', 'label': 'Completed'},
    {'value': 'not_reachable', 'label': 'Not Reachable'},
    {'value': 'refused', 'label': 'Refused'},
    {'value': 'callback_requested', 'label': 'Callback Requested'},
  ];

  @override
  void dispose() {
    _customerController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (time != null) setState(() => _selectedTime = time);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select call date')));
      return;
    }
    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select call time')));
      return;
    }

    setState(() => _submitting = true);
    try {
      final apiService = await ref.read(apiServiceProvider.future);
      final data = {
        'customer_name': _customerController.text.trim(),
        'call_date': _selectedDate!.toIso8601Date(),
        'call_time': _selectedTime!.format(context),
        'result': _selectedResult,
        'notes': _notesController.text.trim(),
      };
      final success = await ref.read(callLogProvider(apiService).notifier).createCallLog(data);
      if (success && mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Call log saved successfully')));
      } else if (mounted) {
        final state = ref.read(callLogProvider(apiService));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error ?? 'Failed to save call log')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log Call')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomTextField(controller: _customerController, label: 'Customer', icon: Icons.person, validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter customer name' : null),
              const SizedBox(height: 16),
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: _selectedDate != null ? 'Call Date: ${_selectedDate!.toLocal().toString().split(' ')[0]}' : 'Call Date',
                    prefixIcon: const Icon(Icons.calendar_today),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                    filled: true, fillColor: Colors.white,
                  ),
                  child: const Text('Tap to select'),
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _pickTime,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: _selectedTime != null ? 'Call Time: ${_selectedTime!.format(context)}' : 'Call Time',
                    prefixIcon: const Icon(Icons.access_time),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                    filled: true, fillColor: Colors.white,
                  ),
                  child: const Text('Tap to select'),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedResult,
                decoration: InputDecoration(
                  labelText: 'Result',
                  prefixIcon: const Icon(Icons.flag),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                  filled: true, fillColor: Colors.white,
                ),
                items: _results.map((r) => DropdownMenuItem(value: r['value'], child: Text(r['label'] as String))).toList(),
                onChanged: (v) => setState(() => _selectedResult = v!),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _notesController,
                label: 'Notes',
                icon: Icons.note,
                maxLines: 4,
              ),
              const SizedBox(height: 24),
              CustomButton(text: 'Save Call Log', icon: Icons.save, isLoading: _submitting, onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }
}
