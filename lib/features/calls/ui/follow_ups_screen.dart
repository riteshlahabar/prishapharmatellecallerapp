import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/app_theme.dart';
import '../../../core/state/providers.dart';
import '../../../core/widgets/app_feedback.dart';
import '../domain/call_log.dart';
import '../state/calls_controller.dart';

/// Promised call-backs. Opens on the ones already due, which is what the
/// telecaller needs first thing; the toggle shows everything still open.
class FollowUpsScreen extends ConsumerWidget {
  const FollowUpsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dueOnly = ref.watch(followUpsDueOnlyProvider);
    final followUps = ref.watch(followUpsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Call backs'),
        actions: [
          TextButton(
            onPressed: () =>
                ref.read(followUpsDueOnlyProvider.notifier).toggle(),
            child: Text(dueOnly ? 'Show all open' : 'Show due only'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(followUpsProvider),
        child: followUps.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ListView(
            children: [
              SizedBox(height: MediaQuery.sizeOf(context).height * 0.25),
              ErrorPanel(
                error: error,
                onRetry: () => ref.invalidate(followUpsProvider),
              ),
            ],
          ),
          data: (page) {
            if (page.items.isEmpty) {
              return ListView(
                children: [
                  SizedBox(height: MediaQuery.sizeOf(context).height * 0.2),
                  EmptyPanel(
                    icon: Icons.event_available_outlined,
                    title: dueOnly ? 'Nothing due' : 'No call backs open',
                    message: dueOnly
                        ? 'Call-backs appear here when their time comes.'
                        : 'Promise one by logging a call as "Call back".',
                  ),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: page.items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) => _FollowUpTile(
                call: page.items[index],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FollowUpTile extends ConsumerStatefulWidget {
  const _FollowUpTile({required this.call});

  final CallLog call;

  @override
  ConsumerState<_FollowUpTile> createState() => _FollowUpTileState();
}

class _FollowUpTileState extends ConsumerState<_FollowUpTile> {
  bool _busy = false;

  Future<void> _complete() async {
    setState(() => _busy = true);

    try {
      await ref.read(callActionsProvider).completeFollowUp(widget.call.id);
      if (mounted) showNotice(context, 'Call back closed.');
    } on Object catch (error) {
      if (mounted) showNotice(context, describeError(error), isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _dial() async {
    final ok = await ref.read(dialerProvider).call(widget.call.personMobile);

    if (!ok && mounted) {
      showNotice(context, 'No number for this person.', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final call = widget.call;
    final due = call.followUpDue;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    call.personName ?? 'Unknown person',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (due)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.warning.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Due',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.warning,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.event_repeat,
                    size: 14, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    call.followUpAt == null
                        ? '—'
                        : DateFormat('EEE d MMM, h:mm a')
                            .format(call.followUpAt!.toLocal()),
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12),
                  ),
                ),
              ],
            ),
            if ((call.notes ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                call.notes!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13),
              ),
            ],
            const Divider(height: 18),
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: _busy ? null : _dial,
                    icon: const Icon(Icons.call, size: 18),
                    label: const Text('Call'),
                  ),
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed: _busy ? null : _complete,
                    icon: _busy
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check, size: 18),
                    label: const Text('Done'),
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
