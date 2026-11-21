import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/auth_service.dart';
import '../../core/providers.dart';
import '../../core/widgets/custom_button.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final _stats = [
    {'label': 'Total Calls', 'value': 0, 'icon': Icons.phone, 'color': Colors.blue},
    {'label': 'Scheduled', 'value': 0, 'icon': Icons.calendar_today, 'color': Colors.orange},
    {'label': 'Completed', 'value': 0, 'icon': Icons.check_circle, 'color': Colors.green},
    {'label': 'Pending', 'value': 0, 'icon': Icons.pending, 'color': Colors.red},
  ];

  @override
  Widget build(BuildContext context) {
    final authAsync = ref.watch(authServiceProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _buildAppBar(context, authAsync, theme),
          ),
          SliverToBoxAdapter(
            child: _buildStatsCards(theme),
          ),
          _buildCallSchedule(theme),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, AsyncValue<AuthService> auth, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [theme.colorScheme.primary, theme.colorScheme.primary.withOpacity(0.75)]),
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Telecaller CRM', style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Row(
            children: [
              CircleAvatar(radius: 22, backgroundColor: Colors.white.withOpacity(0.3), child: Icon(Icons.person, color: Colors.white)),
              const SizedBox(width: 12),
              Expanded(
                child: auth.when(
                  data: (a) => FutureBuilder<String?>(
                    future: a.getUserName(),
                    builder: (context, snap) => Text(
                      'Hello, ${snap.data ?? "Telecaller"}!',
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  loading: (_) => Text('Loading...', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  error: (_, __) => const Text('Hello, Telecaller!', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.4),
        itemCount: _stats.length,
        itemBuilder: (context, i) {
          final s = _stats[i];
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(s['icon'], color: s['color'], size: 30),
                  const SizedBox(height: 8),
                  Text(s['value'].toString(), style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: s['color'])),
                  Text(s['label'], style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCallSchedule(ThemeData theme) {
    final schedule = [
      {'time': '09:30 AM', 'name': 'Rajesh Kumar', 'phone': '9876543210', 'status': 'Scheduled'},
      {'time': '11:00 AM', 'name': 'Priya Sharma', 'phone': '9123456789', 'status': 'Completed'},
      {'time': '02:00 PM', 'name': 'Amit Patel', 'phone': '9988776655', 'status': 'Pending'},
      {'time': '04:30 PM', 'name': 'Sunita Devi', 'phone': '9871234560', 'status': 'Scheduled'},
    ];

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Today's Call Schedule", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
                TextButton.icon(
                  onPressed: () => context.push('/call-schedules'),
                  icon: const Icon(Icons.visibility, size: 18),
                  label: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...schedule.map((s) {
              final color = s['status'] == 'Completed' ? Colors.green : s['status'] == 'Pending' ? Colors.orange : Colors.blue;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(backgroundColor: color.withOpacity(0.15), child: Icon(Icons.phone, color: color)),
                    title: Text(s['name'], style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${s['phone']} • ${s['time']}'),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                      child: Text(s['status'], style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Log Call',
                    icon: Icons.phone_in_talk,
                    onPressed: () => context.push('/call-logs/create'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomButton(
                    text: 'Schedule',
                    icon: Icons.calendar_today,
                    color: Colors.teal,
                    onPressed: () => context.push('/call-schedules/create'),
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
