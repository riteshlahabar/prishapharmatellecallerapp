import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/app_theme.dart';
import '../../../core/widgets/app_feedback.dart';
import '../../../core/widgets/brand.dart';
import '../domain/call_log.dart';
import '../state/calls_controller.dart';

/// Every call this telecaller has logged, newest first. Scoped to them by
/// the server — a call log is a personal working record, not the region's.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(callHistoryProvider);

    return Scaffold(
      appBar: BrandAppBar(
        title: 'My calls',
        subtitle: 'Everything you have logged',
        actions: [
          IconButton(
            tooltip: 'Profile',
            onPressed: () => context.push('/profile'),
            icon: const Icon(Icons.person_outline),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(callHistoryProvider.notifier).reload(),
        child: history.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ListView(
            children: [
              SizedBox(height: MediaQuery.sizeOf(context).height * 0.25),
              ErrorPanel(
                error: error,
                onRetry: () => ref.read(callHistoryProvider.notifier).reload(),
              ),
            ],
          ),
          data: (page) {
            if (page.items.isEmpty) {
              return ListView(
                children: [
                  SizedBox(height: MediaQuery.sizeOf(context).height * 0.2),
                  const EmptyPanel(
                    icon: Icons.history,
                    title: 'No calls logged',
                    message: 'Calls you log from the queue appear here.',
                  ),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: page.items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) =>
                  _HistoryTile(call: page.items[index]),
            );
          },
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.call});

  final CallLog call;

  @override
  Widget build(BuildContext context) {
    // One hue per outcome, used for the row's icon and its chip together,
    // so a long history can be read by colour before it is read by word.
    final colour = switch (call.status?.value) {
      'converted' => AppTheme.success,
      'interested' => AppTheme.teal,
      'callback' => AppTheme.warning,
      'not_interested' => AppTheme.danger,
      _ => AppTheme.textSecondary,
    };

    final icon = switch (call.status?.value) {
      'converted' => Icons.verified_outlined,
      'interested' => Icons.thumb_up_outlined,
      'callback' => Icons.event_repeat_outlined,
      'not_interested' => Icons.thumb_down_outlined,
      _ => Icons.phone_missed_outlined,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconPad(icon: icon, colour: colour, size: 38),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    call.personName ?? 'Unknown client',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                StatusChip(label: call.statusLabel, colour: colour),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 10,
              runSpacing: 2,
              children: [
                if (call.calledAt != null)
                  Text(
                    DateFormat('d MMM y, h:mm a')
                        .format(call.calledAt!.toLocal()),
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                if (call.followUpOpen && call.followUpAt != null)
                  Text(
                    'call back ${DateFormat('d MMM').format(call.followUpAt!.toLocal())}',
                    style: TextStyle(
                      fontSize: 12,
                      color: call.followUpDue
                          ? AppTheme.warning
                          : AppTheme.textSecondary,
                    ),
                  ),
                if (call.followUpDoneAt != null)
                  const Text(
                    'call back closed',
                    style: TextStyle(color: AppTheme.success, fontSize: 12),
                  ),
              ],
            ),
            if ((call.notes ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(call.notes!, style: const TextStyle(fontSize: 13)),
            ],
          ],
        ),
      ),
    );
  }
}
