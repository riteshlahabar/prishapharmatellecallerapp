import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../features/auth/state/auth_controller.dart';
import '../features/auth/ui/login_screen.dart';
import '../features/calls/ui/follow_ups_screen.dart';
import '../features/calls/ui/history_screen.dart';
import '../features/messages/ui/sent_screen.dart';
import '../features/persons/ui/home_screen.dart';
import '../features/profile/ui/profile_screen.dart';
import '../features/shell/ui/app_shell.dart';
import '../features/splash/ui/splash_screen.dart';
import 'state/providers.dart';

final _rootKey = GlobalKey<NavigatorState>();

/// Routes, with one redirect: the splash holds the app until the session is
/// settled, then no token means login and a token means anywhere but login.
/// The redirect reads synchronous providers rather than hitting disk, so it
/// cannot flicker.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/splash',
    refreshListenable: _AuthListenable(ref),
    redirect: (context, state) {
      final atSplash = state.matchedLocation == '/splash';

      // Nothing is reachable until the splash releases, so a cold start
      // cannot show login for a frame and then replace it.
      if (!ref.read(splashDoneProvider)) return atSplash ? null : '/splash';

      final signedIn = ref.read(isSignedInProvider);
      final atLogin = state.matchedLocation == '/login';

      if (atSplash) return signedIn ? '/' : '/login';
      if (!signedIn) return atLogin ? null : '/login';
      if (atLogin) return '/';

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/follow-ups',
                builder: (context, state) => const FollowUpsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/history',
                builder: (context, state) => const HistoryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/sent',
                builder: (context, state) => const SentScreen(),
              ),
            ],
          ),
        ],
      ),
      // Outside the shell: full screen over the tabs.
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  );
});

/// Bridges Riverpod to GoRouter's `refreshListenable`.
class _AuthListenable extends ChangeNotifier {
  _AuthListenable(Ref ref) {
    ref.listen(isSignedInProvider, (_, _) => notifyListeners());
    ref.listen(splashDoneProvider, (_, _) => notifyListeners());
  }
}
