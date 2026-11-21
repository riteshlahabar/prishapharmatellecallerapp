import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../modules/auth/login_screen.dart';
import '../modules/dashboard/screens/dashboard_screen.dart';
import '../modules/customers/screens/customer_list_screen.dart';
import '../modules/call_logs/screens/call_log_list_screen.dart';
import '../modules/call_logs/screens/call_log_create_screen.dart';
import '../modules/call_schedules/screens/call_schedule_list_screen.dart';
import '../modules/call_schedules/screens/call_schedule_create_screen.dart';
import '../modules/reports/screens/reports_screen.dart';
import '../modules/profile/screens/profile_screen.dart';
import 'providers.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authServiceProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    redirect: (context, state) async {
      final isLoggedIn = auth.value?.isLoggedIn ?? false;
      final isLoginRoute = state.matchedLocation == '/login';

      if (!isLoggedIn && !isLoginRoute) return '/login';
      if (isLoggedIn && isLoginRoute) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => DashboardShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/customers',
            builder: (context, state) => const CustomerListScreen(),
          ),
          GoRoute(
            path: '/call-logs',
            builder: (context, state) => const CallLogListScreen(),
          ),
          GoRoute(
            path: '/call-logs/create',
            builder: (context, state) => const CallLogCreateScreen(),
          ),
          GoRoute(
            path: '/call-schedules',
            builder: (context, state) => const CallScheduleListScreen(),
          ),
          GoRoute(
            path: '/call-schedules/create',
            builder: (context, state) => const CallScheduleCreateScreen(),
          ),
          GoRoute(
            path: '/reports',
            builder: (context, state) => const ReportsScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );
});

class DashboardShell extends StatelessWidget {
  final Widget child;
  const DashboardShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex(context),
        onTap: (index) => _onTap(context, index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Customers'),
          BottomNavigationBarItem(icon: Icon(Icons.phone), label: 'Call Logs'),
          BottomNavigationBarItem(icon: Icon(Icons.schedule), label: 'Schedules'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Reports'),
        ],
      ),
    );
  }

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/customers')) return 1;
    if (location.startsWith('/call-logs')) return 2;
    if (location.startsWith('/call-schedules')) return 3;
    if (location.startsWith('/reports')) return 4;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0: context.go('/dashboard');
      case 1: context.go('/customers');
      case 2: context.go('/call-logs');
      case 3: context.go('/call-schedules');
      case 4: context.go('/reports');
    }
  }
}