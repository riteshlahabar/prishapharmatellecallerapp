import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/app_theme.dart';
import '../../calls/state/calls_controller.dart';

/// The bottom-nav frame the five main screens live in.
class AppShell extends ConsumerWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // How many call-backs are already due. Comes from the same request the
    // follow-ups screen uses, so the badge cannot disagree with the list.
    final due = ref
        .watch(followUpsProvider)
        .maybeWhen(
          data: (page) => ref.watch(followUpsDueOnlyProvider)
              ? page.total
              : page.items.where((call) => call.followUpDue).length,
          orElse: () => 0,
        );

    return Scaffold(
      body: navigationShell,
      // A hairline over the bar: the theme gives it a white ground, and
      // without this it melts into a white screen behind it.
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppTheme.line)),
        ),
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: (index) => navigationShell.goBranch(
            index,
            // A second tap on the current tab pops it back to its first screen.
            initialLocation: index == navigationShell.currentIndex,
          ),
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            const NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people),
              label: 'Clients',
            ),
            NavigationDestination(
              icon: Badge.count(
                count: due,
                isLabelVisible: due > 0,
                child: const Icon(Icons.event_repeat_outlined),
              ),
              selectedIcon: Badge.count(
                count: due,
                isLabelVisible: due > 0,
                child: const Icon(Icons.event_repeat),
              ),
              label: 'Call backs',
            ),
            const NavigationDestination(
              icon: Icon(Icons.history_outlined),
              selectedIcon: Icon(Icons.history),
              label: 'History',
            ),
            const NavigationDestination(
              icon: Icon(Icons.send_outlined),
              selectedIcon: Icon(Icons.send),
              label: 'Sent',
            ),
          ],
        ),
      ),
    );
  }
}
