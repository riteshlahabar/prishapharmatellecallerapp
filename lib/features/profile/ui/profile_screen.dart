import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/app_theme.dart';
import '../../../core/constants.dart';
import '../../../core/widgets/brand.dart';
import '../../auth/state/auth_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider);

    return Scaffold(
      // No app bar: BrandHeader below is this screen's header, and two of
      // them stack into a double title. This screen is pushed over the tabs,
      // so the header carries the way back.
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          BrandHeader(
            onBack: () => context.pop(),
            title: user?.name ?? '—',
            subtitle: user?.email ?? '',
            trailing: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.tint(AppTheme.teal)),
              ),
              alignment: Alignment.center,
              child: Text(
                user?.initials ?? '?',
                style: const TextStyle(
                  color: AppTheme.teal,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Card(
                  child: Column(
                    children: [
                      _Row(
                        icon: Icons.badge_outlined,
                        label: 'Role',
                        value: user?.role.toUpperCase() ?? '—',
                        colour: AppTheme.tileTeal,
                      ),
                      const Divider(height: 1),
                      _Row(
                        icon: Icons.map_outlined,
                        label: 'Region',
                        value: user?.regionLabel ?? '—',
                        colour: AppTheme.tileGreen,
                      ),
                      const Divider(height: 1),
                      _Row(
                        icon: Icons.phone_outlined,
                        label: 'Mobile',
                        value: user?.mobile ?? '—',
                        colour: AppTheme.tileBlue,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.danger,
                    side: const BorderSide(color: AppTheme.danger, width: 1.4),
                  ),
                  onPressed: () => _confirmSignOut(context, ref),
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign out'),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    '${AppConstants.appName} · v1.0.0',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You will need your password to sign back in.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authControllerProvider.notifier).signOut();
    }
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.label,
    required this.value,
    required this.colour,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color colour;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: IconPad(icon: icon, colour: colour, size: 36),
      title: Text(label, style: const TextStyle(fontSize: 13)),
      trailing: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 190),
        child: Text(
          value,
          textAlign: TextAlign.right,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
