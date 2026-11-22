import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/app_theme.dart';
import '../../../core/state/providers.dart';
import '../../../core/widgets/app_feedback.dart';
import '../../calls/domain/call_log.dart';
import '../../calls/ui/log_call_sheet.dart';
import '../domain/person.dart';
import '../state/persons_controller.dart';

/// The queue: everyone in this telecaller's regions, with what happened last
/// time they rang. Tapping a row dials; the button logs the outcome.
class QueueScreen extends ConsumerStatefulWidget {
  const QueueScreen({super.key});

  @override
  ConsumerState<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends ConsumerState<QueueScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _dial(Person person) async {
    final ok = await ref.read(dialerProvider).call(person.mobile);

    if (!ok && mounted) {
      showNotice(context, 'No dialler on this device.', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final queue = ref.watch(queueProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Queue')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search your regions',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _search.clear();
                          ref.read(queueSearchProvider.notifier).set('');
                          setState(() {});
                        },
                      ),
              ),
              onChanged: (value) => setState(() {}),
              onSubmitted: (value) =>
                  ref.read(queueSearchProvider.notifier).set(value),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref.invalidate(queueProvider),
              child: queue.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => ListView(
                  children: [
                    SizedBox(height: MediaQuery.sizeOf(context).height * 0.2),
                    ErrorPanel(
                      error: error,
                      onRetry: () => ref.invalidate(queueProvider),
                    ),
                  ],
                ),
                data: (page) {
                  if (page.items.isEmpty) {
                    return ListView(
                      children: [
                        SizedBox(
                            height: MediaQuery.sizeOf(context).height * 0.18),
                        EmptyPanel(
                          icon: Icons.people_outline,
                          title: _search.text.isEmpty
                              ? 'Nobody in your regions yet'
                              : 'No match for "${_search.text}"',
                          message: _search.text.isEmpty
                              ? 'The admin assigns persons to regions.'
                              : 'Try a different name.',
                        ),
                      ],
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: page.items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final person = page.items[index];

                      return _QueueTile(
                        person: person,
                        onDial: () => _dial(person),
                        onLog: () => showLogCallSheet(context, person: person),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QueueTile extends StatelessWidget {
  const _QueueTile({
    required this.person,
    required this.onDial,
    required this.onLog,
  });

  final Person person;
  final VoidCallback onDial;
  final VoidCallback onLog;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(person.name,
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        person.subtitle,
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (person.hasDueFollowUp)
                  const _Pill(text: 'Due', colour: AppTheme.warning)
                else if (person.neverCalled)
                  const _Pill(text: 'New', colour: AppTheme.primary),
              ],
            ),
            const SizedBox(height: 8),
            _LastCall(call: person.lastCall),
            const Divider(height: 18),
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: person.canDial ? onDial : null,
                    icon: const Icon(Icons.call, size: 18),
                    label: Text(person.canDial ? 'Call' : 'No number'),
                  ),
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed: onLog,
                    icon: const Icon(Icons.edit_note, size: 20),
                    label: const Text('Log'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LastCall extends StatelessWidget {
  const _LastCall({required this.call});

  final CallLog? call;

  @override
  Widget build(BuildContext context) {
    final last = call;

    if (last == null) {
      return const Text(
        'Not called yet',
        style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _Pill(text: last.statusLabel, colour: _statusColour(last)),
        if (last.calledAt != null)
          Text(
            DateFormat('d MMM, h:mm a').format(last.calledAt!.toLocal()),
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 12),
          ),
        if (last.followUpOpen && last.followUpAt != null)
          Text(
            'call back ${DateFormat('d MMM').format(last.followUpAt!.toLocal())}',
            style: TextStyle(
              color: last.followUpDue ? AppTheme.warning : AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: last.followUpDue ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
      ],
    );
  }

  Color _statusColour(CallLog call) => switch (call.status?.value) {
        'converted' => AppTheme.success,
        'interested' => AppTheme.primary,
        'callback' => AppTheme.warning,
        'not_interested' => AppTheme.danger,
        _ => AppTheme.textSecondary,
      };
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.colour});

  final String text;
  final Color colour;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: colour.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600, color: colour),
      ),
    );
  }
}
