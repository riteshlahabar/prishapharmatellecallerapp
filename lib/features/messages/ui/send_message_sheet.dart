import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/api/api_failure.dart';
import '../../../core/app_theme.dart';
import '../../../core/state/providers.dart';
import '../../../core/widgets/app_feedback.dart';
import '../../persons/domain/person.dart';
import '../domain/recipient.dart';
import '../state/messages_controller.dart';

/// Writes to an MR about a person.
Future<void> showSendMessageSheet(
  BuildContext context, {
  Person? person,
  int? callLogId,
  String? prefillSubject,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => _SendMessageSheet(
      person: person,
      callLogId: callLogId,
      prefillSubject: prefillSubject,
    ),
  );
}

class _SendMessageSheet extends ConsumerStatefulWidget {
  const _SendMessageSheet({this.person, this.callLogId, this.prefillSubject});

  final Person? person;
  final int? callLogId;
  final String? prefillSubject;

  @override
  ConsumerState<_SendMessageSheet> createState() => _SendMessageSheetState();
}

class _SendMessageSheetState extends ConsumerState<_SendMessageSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _subject =
      TextEditingController(text: widget.prefillSubject ?? '');
  final _body = TextEditingController();

  Recipient? _to;
  bool _busy = false;
  Map<String, List<String>> _serverErrors = const {};

  @override
  void dispose() {
    _subject.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final to = _to;
    if (to == null) {
      showNotice(context, 'Pick who to tell.', isError: true);

      return;
    }

    setState(() {
      _busy = true;
      _serverErrors = const {};
    });

    try {
      await ref.read(messagesRepositoryProvider).send(
            toUserId: to.id,
            subject: _subject.text.trim(),
            body: _body.text.trim(),
            personId: widget.person?.id,
            callLogId: widget.callLogId,
          );

      await ref.read(sentMessagesProvider.notifier).reload();

      if (mounted) {
        Navigator.of(context).pop();
        showNotice(context, 'Sent to ${to.name}.');
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
    // Naming the person widens the picker to include their own rep, even
    // from another region — the server applies the same rule on the send.
    final recipients = ref.watch(recipientsProvider(widget.person?.id));

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Tell an MR', style: Theme.of(context).textTheme.titleLarge),
              if (widget.person != null) ...[
                const SizedBox(height: 2),
                Text(
                  'about ${widget.person!.name}',
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
              ],
              const SizedBox(height: 16),
              recipients.when(
                loading: () => const LinearProgressIndicator(),
                error: (error, _) => ErrorPanel(
                  error: error,
                  onRetry: () =>
                      ref.invalidate(recipientsProvider(widget.person?.id)),
                ),
                data: (list) {
                  if (list.isEmpty) {
                    return const EmptyPanel(
                      icon: Icons.person_off_outlined,
                      title: 'No reps to write to',
                      message: 'No active MR covers your regions yet.',
                    );
                  }

                  return DropdownButtonFormField<Recipient>(
                    initialValue: _to,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'To',
                      prefixIcon: const Icon(Icons.person_outline),
                      errorText: _serverErrors['to_user_id']?.first,
                    ),
                    items: [
                      for (final mr in list)
                        DropdownMenuItem(
                          value: mr,
                          child: Text(
                            mr.regionName == null
                                ? mr.name
                                : '${mr.name} · ${mr.regionName}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (value) => setState(() => _to = value),
                    validator: (value) =>
                        value == null ? 'Pick who to tell' : null,
                  );
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _subject,
                maxLength: 150,
                decoration: InputDecoration(
                  labelText: 'Subject',
                  errorText: _serverErrors['subject']?.first,
                ),
                validator: (value) =>
                    (value ?? '').trim().isEmpty ? 'Add a subject' : null,
              ),
              TextFormField(
                controller: _body,
                maxLines: 4,
                maxLength: 2000,
                decoration: InputDecoration(
                  labelText: 'Message',
                  alignLabelWithHint: true,
                  errorText: _serverErrors['body']?.first,
                ),
                validator: (value) =>
                    (value ?? '').trim().isEmpty ? 'Write something' : null,
              ),
              const SizedBox(height: 4),
              FilledButton(
                onPressed: _busy ? null : _send,
                child: _busy
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Send'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
