import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/app_theme.dart';
import '../../../core/widgets/app_feedback.dart';
import '../domain/sent_message.dart';
import '../state/messages_controller.dart';
import 'send_message_sheet.dart';

/// What this telecaller has told the reps, and whether they have read it.
class SentScreen extends ConsumerWidget {
  const SentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sent = ref.watch(sentMessagesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Sent')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showSendMessageSheet(context),
        icon: const Icon(Icons.edit),
        label: const Text('New message'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(sentMessagesProvider.notifier).reload(),
        child: sent.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ListView(
            children: [
              SizedBox(height: MediaQuery.sizeOf(context).height * 0.25),
              ErrorPanel(
                error: error,
                onRetry: () =>
                    ref.read(sentMessagesProvider.notifier).reload(),
              ),
            ],
          ),
          data: (page) {
            if (page.items.isEmpty) {
              return ListView(
                children: [
                  SizedBox(height: MediaQuery.sizeOf(context).height * 0.2),
                  const EmptyPanel(
                    icon: Icons.outgoing_mail,
                    title: 'Nothing sent yet',
                    message: 'Tell a rep what a doctor asked for.',
                  ),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: page.items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) =>
                  _SentTile(message: page.items[index]),
            );
          },
        ),
      ),
    );
  }
}

class _SentTile extends StatelessWidget {
  const _SentTile({required this.message});

  final SentMessage message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    message.subject,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                // Read state belongs to the recipient; this is the one
                // thing the sender wants to know after the fact.
                Icon(
                  message.isRead ? Icons.done_all : Icons.done,
                  size: 18,
                  color: message.isRead
                      ? AppTheme.success
                      : AppTheme.textSecondary,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              message.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 2,
              children: [
                if (message.toName != null)
                  Text('to ${message.toName}',
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 11)),
                if (message.personName != null)
                  Text('re: ${message.personName}',
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 11)),
                if (message.sentAt != null)
                  Text(
                    DateFormat('d MMM, h:mm a')
                        .format(message.sentAt!.toLocal()),
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 11),
                  ),
                Text(
                  message.isRead ? 'read' : 'unread',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: message.isRead
                        ? AppTheme.success
                        : AppTheme.textSecondary,
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
