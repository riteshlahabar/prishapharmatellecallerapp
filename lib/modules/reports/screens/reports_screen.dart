import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/app_theme.dart';
import '../../core/providers.dart';
import '../../core/services/api_service.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});
  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  DateTime fromDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime toDate = DateTime.now();
  List<Map<String, dynamic>> reportData = [];
  int totalCalls = 0, completed = 0, notReached = 0, callbacks = 0;
  bool isLoading = false;
  String? error;

  Future<void> _pickDate(bool isFrom) async {
    final picked = await showDatePicker(context: context, initialDate: isFrom ? fromDate : toDate, firstDate: DateTime(2020), lastDate: DateTime.now());
    if (picked != null) setState(() => isFrom ? fromDate = picked : toDate = picked);
  }

  Future<void> _generateReport() async {
    if (fromDate.isAfter(toDate)) { setState(() => error = 'From date must be before to date.'); return; }
    setState(() { isLoading = true; error = null; });
    try {
      final api = await ref.read(apiServiceProvider).future;
      final resp = await api.dio.get('/reports', queryParameters: {'from': DateFormat('yyyy-MM-dd').format(fromDate), 'to': DateFormat('yyyy-MM-dd').format(toDate)});
      if (resp.data != null) {
        final list = resp.data is List ? resp.data : (resp.data['data'] as List? ?? []);
        totalCalls = 0; completed = 0; notReached = 0; callbacks = 0;
        for (final item in list) {
          totalCalls += (item['calls_made'] ?? item['total_calls'] ?? 0);
          completed += item['completed'] ?? 0; notReached += item['not_reached'] ?? 0; callbacks += item['callbacks'] ?? 0;
        }
        setState(() => reportData = list.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e)).toList());
      }
    } catch (e) { setState(() => error = e.toString()); }
    finally { if (mounted) setState(() => isLoading = false); }
  }

  Widget _dateTile(String label, DateTime dt) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
      child: Row(children: [Icon(Icons.date_range, size: 20, color: AppTheme.primaryColor), const SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          Text(DateFormat('dd MMM yyyy').format(dt), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ])),
      ]));
  }

  DateTime _parseDate(dynamic v) {
    if (v is DateTime) return v;
    final s = v.toString();
    try { return DateFormat('yyyy-MM-dd').parse(s); } catch (_) {}
    try { return DateFormat('dd/MM/yyyy').parse(s); } catch (_) {}
    return DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy');
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      appBar: AppBar(title: const Text('Reports'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Expanded(child: InkWell(onTap: () => _pickDate(true), child: _dateTile('From', fromDate))),
            const SizedBox(width: 12),
            Expanded(child: InkWell(onTap: () => _pickDate(false), child: _dateTile('To', toDate))),
          ]),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: ElevatedButton.icon(
            onPressed: isLoading ? null : _generateReport,
            icon: isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.bar_chart),
            label: Text(isLoading ? 'Generating...' : 'Generate Report'),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          )),
          if (error != null) ...[const SizedBox(height: 12), Text('Error: $error', style: const TextStyle(color: AppTheme.errorColor))],
          const SizedBox(height: 16),
          _buildStatCards(),
          if (reportData.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Daily Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...reportData.map((day) => Padding(padding: const EdgeInsets.only(bottom: 8),
              child: Card(elevation: 1, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: Icon(Icons.calendar_today, color: AppTheme.primaryColor),
                  title: Text(fmt.format(day['date'] is DateTime ? day['date'] : day['date'] is String ? _parseDate(day['date']) : DateTime.now())),
                  subtitle: Text('Calls: ${day['calls_made'] ?? day['total_calls'] ?? 0} | Completed: ${day['completed'] ?? 0}'),
                  trailing: Chip(label: Text('${day['completed'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    backgroundColor: Colors.green.withValues(alpha: 0.15), labelStyle: const TextStyle(color: Colors.green)),
                ),
              ),
            )),
          ],
          if (reportData.isEmpty && !isLoading && error == null)
            Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(children: [Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 12), Text('Select dates and generate a report', style: TextStyle(color: Colors.grey.shade600)),
              ]),
            )),
        ]),
      ),
    );
  }

  Widget _buildStatCards() {
    final entries = <({String label, int value, IconData icon, Color color})>[
      (label: 'Total Calls', value: totalCalls, icon: Icons.phone, color: Colors.blue),
      (label: 'Completed', value: completed, icon: Icons.check_circle, color: Colors.green),
      (label: 'Not Reached', value: notReached, icon: Icons.signal_wifi_off, color: Colors.orange),
      (label: 'Callbacks', value: callbacks, icon: Icons.schedule, color: Colors.purple),
    ];
    return GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.5),
      itemCount: 4,
      itemBuilder: (context, i) {
        final e = entries[i];
        return Card(elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(e.icon, color: e.color, size: 28), const SizedBox(height: 6),
              Text(e.value.toString(), style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: e.color)),
              Text(e.label, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
            ],
          ),
        ));
      },
    );
  }
}