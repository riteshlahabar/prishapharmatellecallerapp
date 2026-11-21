import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/app_theme.dart';
import '../../core/providers.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../providers/call_schedule_provider.dart';

class CallScheduleCreateScreen extends ConsumerStatefulWidget {
  const CallScheduleCreateScreen({super.key});

  @override
  ConsumerState<CallScheduleCreateScreen> createState() =>
      _CallScheduleCreateScreenState();
}

class _CallScheduleCreateScreenState
    extends ConsumerState<CallScheduleCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customerController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _loading = false;

  @override
  void dispose() {
    _customerController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) setState(() => _selectedTime = time);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select date and time')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final api = await ref.read(apiServiceProvider.future);
      final notifier = ref.read(callScheduleProvider(api).notifier);
      final data = {
        'customer_name': _customerController.text.trim(),
        'scheduled_date': DateFormat('yyyy-MM-dd').format(_selectedDate!),
        'scheduled_time': _selectedTime!.format(context),
        'notes': _notesController.text.trim(),
      };
      final success = await notifier.createSchedule(data);
      if (success && mounted) {
        context.pop();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create schedule')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Schedule Call')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomTextField(
                controller: _customerController,
                labelText: 'Customer Name',
                hintText: 'Enter customer name',
                prefixIcon: Icons.person_outline,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text('Date'),
                subtitle: Text(
                  _selectedDate != null
                      ? DateFormat('EEE, d MMM yyyy').format(_selectedDate!)
                      : 'Select date',
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _pickDate,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.access_time),
                title: Text('Time'),
                subtitle: Text(
                  _selectedTime != null
                      ? _selectedTime!.format(context)
                      : 'Select time',
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _pickTime,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _notesController,
                labelText: 'Notes (optional)',
                hintText: 'Add notes for this call',
                prefixIcon: Icons.note_outlined,
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: _loading ? 'Scheduling...' : 'Schedule Call',
                isLoading: _loading,
                onPressed: _loading ? () {} : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
