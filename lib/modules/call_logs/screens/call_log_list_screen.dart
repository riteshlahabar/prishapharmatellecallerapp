import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../../core/widgets/custom_button.dart';
import '../models/call_log.dart';
import '../providers/call_log_provider.dart';

class CallLogListScreen extends ConsumerWidget {
  const CallLogListScreen({super.key});

  Color _getResultColor(String result) {
    switch (result) {
      case 'completed':
        return Colors.green;
      case 'not_reachable':
        return Colors.orange;
      case 'refused':
        return Colors.red;
      case 'callback_requested':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getResultLabel(String result) {
    switch (result) {
      case 'completed':
        return 'Completed';
      case 'not_reachable':
        return 'Not Reachable';
      case 'refused':
        return 'Refused';
      case 'callback_requested':
        return 'Callback';
      default:
        return result;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apiAsync = ref.watch(apiServiceProvider);
    return apiAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
      data: (apiService) {
        final notifier = ref.read(callLogProvider(apiService).notifier);
        // Auto-load on first visit
        ref.listen.callOnce(callLogProvider(apiService), (prev, next) {
          if (prev == null && next.logs.isEmpty && next.error == null) notifier.loadCallLogs();
        });
        final state = ref.watch(callLogProvider(apiService));
        return Scaffold(
          appBar: AppBar(title: const Text('Call Logs')),
          floatingActionButton: FloatingActionButton(
            onPressed: () => context.push('/call-logs/create'),
            child: const Icon(Icons.add),
          ),
          body: RefreshIndicator(
            onRefresh: () => ref.read(callLogProvider(apiService).notifier).loadCallLogs(),
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(state.error!, textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            CustomButton(
                              text: 'Retry',
                              onPressed: () => ref.read(callLogProvider(apiService).notifier).loadCallLogs(),
                            ),
                          ],
                        ),
                      )
                    : state.logs.isEmpty
                        ? const Center(child: Text('No call logs yet.\nTap + to log a call.'), textAlign: TextAlign.center)
                        : _buildLogList(context, ref, apiService, state.logs),
          ),
        );
      },
    );
  }

  Widget _buildLogList(BuildContext context, WidgetRef ref, apiService, List<CallLog> logs) {
    return ListView.separated(
      itemCount: logs.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final log = logs[index];
        return Slidable(
          key: ValueKey(log.id ?? index),
          endActionPane: ActionPane(
            motion: const ScrollMotion(),
            children: [
              SlidableAction(
                onPressed: (_) async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Delete Call Log'),
                      content: Text('Delete call log for ${log.customerName}?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                      ],
                    ),
                  );
                  if (ok == true) {
                    if (log.id != null) {
                      await ref.read(callLogProvider(apiService).notifier).deleteCallLog(log.id!);
                    }
                  }
                },
                backgroundColor: Colors.red,
                icon: Icons.delete,
                label: 'Delete',
              ),
            ],
          ),
          child: ListTile(
            title: Text(log.customerName, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('${log.callDate} • ${log.callTime}', style: TextStyle(color: Colors.grey.shade600)),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: _getResultColor(log.result).withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
              child: Text(_getResultLabel(log.result), style: TextStyle(color: _getResultColor(log.result), fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ),
        );
      },
    );
  }
}
