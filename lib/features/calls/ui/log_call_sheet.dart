import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/api/api_failure.dart';
import '../../../core/app_theme.dart';
import '../../../core/widgets/app_feedback.dart';
import '../../messages/ui/send_message_sheet.dart';
import '../../persons/domain/person.dart';
import '../domain/call_status.dart';
import '../state/calls_controller.dart';

/// Logs the outcome of a call, from wherever the telecaller is.
Future<void> showLogCallSheet(BuildContext context, {required Person person}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => _LogCallSheet(person: person),
  );
}

class _LogCallSheet extends ConsumerStatefulWidget {
  const _LogCallSheet({required this.person});

  final Person person;

  @override
  ConsumerState<_LogCallSheet> createState() => _LogCallSheetState();
}

class _LogCallSheetState extends ConsumerState<_LogCallSheet> {
  final _notes = TextEditingController();

  CallStatus? _status;
  DateTime? _followUpAt;
  bool _busy = false;
  Map<String, List<String>> _serverErrors = const {};

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickFollowUp() async {
    final now = DateTime.now();

    final date = await showDatePicker(
      context: context,
      // The server requires a future date, so there is no point offering
      // yesterday and letting it come back a 422.
      firstDate: now.add(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
      initialDate: now.add(const Duration(days: 1)),
    );

    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
    );

    if (!mounted) return;

    setState(() {
      _followUpAt = DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? 10,
        time?.minute ?? 0,
      );
    });
  }

  Future<void> _save() async {
    final status = _status;

    if (status == null) {
      showNotice(context, 'Pick what happened on the call.', isError: true);

      return;
    }

    // The server requires a date on `callback` and refuses one otherwise.
    // Catching it here saves a round trip and explains it in place.
    if (status.needsFollowUp && _followUpAt == null) {
      setState(() => _serverErrors = {
            'follow_up_at': ['Pick when to call back.'],
          });

      return;
    }

    setState(() {
      _busy = true;
      _serverErrors = const {};
    });

    try {
      final call = await ref.read(callActionsProvider).log(
            personId: widget.person.id,
            status: status,
            notes: _notes.text,
            followUpAt: _followUpAt,
          );

      if (!mounted) return;
      Navigator.of(context).pop();
      showNotice(context, 'Call logged.');

      // An interested or converted call is usually worth telling the rep
      // about, so offer it rather than making them find the other screen.
      if (status == CallStatus.interested || status == CallStatus.converted) {
        await showSendMessageSheet(
          context,
          person: widget.person,
          callLogId: call.id,
          prefillSubject: '${widget.person.name}: ${status.label}',
        );
      }
    } on ApiFailure catch (failure) {
      setState(() => _serverErrors = failure.fieldErrors);
      if (mounted) showNotice(context, failure.message, isError: true);
    } on Object catch (error) {
      if (mounted) showNotice(context, describeError(error), isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final needsDate = _status?.needsFollowUp ?? false;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Log a call', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 2),
            Text(
              widget.person.name,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final status in CallStatus.values)
                  ChoiceChip(
                    label: Text(status.label),
                    selected: _status == status,
                    onSelected: (_) => setState(() {
                      _status = status;
                      // Dropping out of `callback` retires the promise with
                      // it, exactly as the server does.
                      if (!status.needsFollowUp) _followUpAt = null;
                    }),
                  ),
              ],
            ),
            if (_serverErrors['status'] != null) ...[
              const SizedBox(height: 6),
              Text(_serverErrors['status']!.first,
                  style: const TextStyle(color: AppTheme.danger, fontSize: 12)),
            ],
            if (needsDate) ...[
              const SizedBox(height: 14),
              InkWell(
                onTap: _pickFollowUp,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Call back on',
                    prefixIcon: const Icon(Icons.event_repeat),
                    errorText: _serverErrors['follow_up_at']?.first,
                  ),
                  child: Text(
                    _followUpAt == null
                        ? 'Pick a date and time'
                        : DateFormat('EEE d MMM, h:mm a').format(_followUpAt!),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),
            TextField(
              controller: _notes,
              maxLines: 4,
              maxLength: 2000,
              decoration: InputDecoration(
                labelText: 'Notes (optional)',
                alignLabelWithHint: true,
                errorText: _serverErrors['notes']?.first,
              ),
            ),
            const SizedBox(height: 4),
            FilledButton(
              onPressed: _busy ? null : _save,
              child: _busy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Save call'),
            ),
          ],
        ),
      ),
    );
  }
}
