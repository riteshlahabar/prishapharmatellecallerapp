import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../core/app_theme.dart';
import '../../core/providers.dart';
import '../models/call_schedule.dart';
import '../providers/call_schedule_provider.dart';

class CallScheduleListScreen extends ConsumerStatefulWidget {
  const CallScheduleListScreen({super.key});
  @override
  ConsumerState<CallScheduleListScreen> createState() => _CallScheduleListScreenState();
}

class _CallScheduleListScreenState extends ConsumerState<CallScheduleListScreen> {
  late DateTime _selectedDay;
  late DateTime _focusedDay;
  final _df = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _focusedDay = DateTime.now();
    _load();
  }

  Future<void> _load() async {
    final api = await ref.read(apiServiceProvider.future);
    await ref.read(callScheduleProvider(api).notifier).loadSchedules();
    setState(() {});
  }

  Color _color(String s) {
    if (s == 'completed') return Colors.green;
    if (s == 'cancelled') return Colors.red;
    if (s == 'rescheduled') return Colors.blue;
    return AppTheme.accentColor;
  }

  @override
  Widget build(BuildContext context) {
    return ref.watch(apiServiceProvider).when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Failed to load')),
      data: (api) {
        final schedules = ref.watch(callScheduleProvider(api));
        return Scaffold(
          appBar: AppBar(title: const Text('Call Schedules')),
          floatingActionButton: FloatingActionButton(
            onPressed: () => context.go('/call-schedules/create'),
            child: const Icon(Icons.add),
          ),
          body: RefreshIndicator(
            onRefresh: _load,
            child: Column(children: [
              TableCalendar<CallSchedule>(
                firstDay: DateTime.now().subtract(const Duration(days: 365)),
                lastDay: DateTime.now().add(const Duration(days: 365)),
                focusedDay: _focusedDay,
                selectedDayPredicate: (d) => isSameDay(d, _selectedDay),
                onDaySelected: (s, f) => setState(() { _selectedDay = s; _focusedDay = f; }),
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.2), shape: BoxShape.circle),
                  selectedDecoration: const BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle),
                ),
                eventLoader: (day) => schedules.where((s) => s.scheduledDate == _df.format(day)).toList(),
                calendarBuilders: CalendarBuilders(
                  dotBuilder: (ctx, date, events) => events.isEmpty ? null : Positioned(
                    right: 1, bottom: 1, child: Container(width: 6, height: 6, decoration: BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle))),
                ),
              ),
              const Divider(height: 1),
              Expanded(child: _buildList(schedules)),
            ]),
          ),
        );
      },
    );
  }

  Widget _buildList(List<CallSchedule> schedules) {
    final key = _df.format(_selectedDay);
    final items = schedules.where((s) => s.scheduledDate == key).toList();
    if (items.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.schedule_outlined, size: 64, color: Colors.grey[400]),
        const SizedBox(height: 12),
        Text('No calls for ${DateFormat('EEE, d MMM').format(_selectedDay)}',
            style: TextStyle(color: Colors.grey[600], fontSize: 14)),
      ]));
    }
    return ListView.separated(
      itemCount: items.length, separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final s = items[i];
        return ListTile(
          leading: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Text(s.scheduledTime, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.primaryColor)),
          ),
          title: Text(s.customerName, style: const TextStyle(fontWeight: FontWeight.w500)),
          subtitle: s.notes.isNotEmpty ? Text(s.notes, maxLines: 1, overflow: TextOverflow.ellipsis) : null,
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: _color(s.status).withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
            child: Text(s.status.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _color(s.status))),
          ),
          onTap: () => _showStatusDialog(context, s),
        );
      },
    );
  }

  void _showStatusDialog(BuildContext context, CallSchedule s) {
    final apiAsync = ref.read(apiServiceProvider);
    showDialog(context: context, builder: (dc) => AlertDialog(
      title: Text('Update: ${s.customerName}'),
      content: Column(mainAxisSize: MainAxisSize.min, children: ['pending', 'completed', 'cancelled', 'rescheduled'].map((st) {
        final c = _color(st);
        return ListTile(
          title: Text(st.toUpperCase(), style: TextStyle(color: c, fontWeight: FontWeight.w600)),
          trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[500]),
          onTap: () async {
            Navigator.pop(dc);
            if (apiAsync.hasValue && s.id != null) {
              await ref.read(callScheduleProvider(apiAsync.value!).notifier).updateStatus(s.id!, st);
              setState(() {});
            }
          },
        );
      }).toList()),
      actions: [TextButton(onPressed: () => Navigator.pop(dc), child: const Text('Cancel'))],
    ));
  }
}
