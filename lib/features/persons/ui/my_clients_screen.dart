import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/app_theme.dart';
import '../../../core/state/providers.dart';
import '../../../core/widgets/app_feedback.dart';
import '../../../core/widgets/brand.dart';
import '../../calls/ui/log_call_sheet.dart';
import '../domain/person.dart';
import '../state/persons_controller.dart';

/// My Clients: every client this telecaller is the assigned one of.
///
/// Not the same list as Home. Home is the call queue — everyone in the
/// regions this telecaller covers, whoever owns them. This is the ones that
/// are theirs, including a client an MR added and handed over, which is the
/// point: the two apps share a client and each sees it from its own side.
///
/// The scope is the server's (`?mine=1`), so there is nothing to filter here
/// but the search box. Calling and logging work the same as on Home, because
/// a client being yours is no reason to make ringing them a trip back.
class MyClientsScreen extends ConsumerStatefulWidget {
  const MyClientsScreen({super.key});

  @override
  ConsumerState<MyClientsScreen> createState() => _MyClientsScreenState();
}

class _MyClientsScreenState extends ConsumerState<MyClientsScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _dial(Person person) async {
    final ok = await ref.read(dialerProvider).call(person.mobile);

    if (!ok && mounted) {
      showNotice(context, 'No dialler on this device.', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final clients = ref.watch(myClientsProvider);

    return Scaffold(
      appBar: const BrandAppBar(
        title: 'My clients',
        subtitle: 'The clients assigned to you',
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/clients/new'),
        icon: const Icon(Icons.person_add_alt),
        label: const Text('Add client'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search name, mobile or city',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        tooltip: 'Clear',
                        onPressed: () {
                          _search.clear();
                          ref.read(myClientsSearchProvider.notifier).set('');
                          setState(() {});
                        },
                      ),
              ),
              onChanged: (value) => setState(() {}),
              // On submit, not on every keystroke: each search is one
              // request.
              onSubmitted: (value) =>
                  ref.read(myClientsSearchProvider.notifier).set(value),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref.invalidate(myClientsProvider),
              child: clients.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => ListView(
                  children: [
                    SizedBox(height: MediaQuery.sizeOf(context).height * 0.2),
                    ErrorPanel(
                      error: error,
                      onRetry: () => ref.invalidate(myClientsProvider),
                    ),
                  ],
                ),
                data: (page) {
                  if (page.items.isEmpty) {
                    return ListView(
                      children: [
                        SizedBox(
                          height: MediaQuery.sizeOf(context).height * 0.18,
                        ),
                        EmptyPanel(
                          icon: Icons.people_outline,
                          title: _search.text.isEmpty
                              ? 'No clients yet'
                              : 'No match for "${_search.text}"',
                          message: _search.text.isEmpty
                              ? 'Clients you add, and the ones an MR assigns '
                                    'to you, will appear here.'
                              : 'Try a different name, mobile or city.',
                        ),
                      ],
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                    itemCount: page.items.length + 1,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      if (index == page.items.length) {
                        return _CountFooter(
                          shown: page.items.length,
                          total: page.total,
                        );
                      }

                      final person = page.items[index];

                      return _ClientTile(
                        client: person,
                        onDial: () => _dial(person),
                        onLog: () => showLogCallSheet(context, person: person),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClientTile extends StatelessWidget {
  const _ClientTile({
    required this.client,
    required this.onDial,
    required this.onLog,
  });

  final Person client;
  final VoidCallback onDial;
  final VoidCallback onLog;

  /// A colour per kind, so a long list is scannable before it is read. The
  /// hue is chosen by meaning, never by position in the list.
  Color get _hue => switch (client.type) {
    'hospital' => AppTheme.tileBlue,
    'medical' => AppTheme.tileGreen,
    _ => AppTheme.tileTeal,
  };

  IconData get _icon => switch (client.type) {
    'hospital' => Icons.local_hospital_outlined,
    'medical' => Icons.storefront_outlined,
    _ => Icons.person_outline,
  };

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconPad(icon: _icon, colour: _hue, size: 38),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        client.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        client.subtitle,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusChip(label: client.typeLabel, colour: _hue),
              ],
            ),
            const SizedBox(height: 8),
            // A Wrap, not a Row: a mobile number beside an MR's name and a
            // region overflows a narrow handset.
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                if ((client.mobile ?? '').isNotEmpty)
                  _Fact(icon: Icons.phone_outlined, text: client.mobile!),
                if ((client.regionName ?? '').isNotEmpty)
                  _Fact(icon: Icons.map_outlined, text: client.regionName!),
                // The other side of the client: who to talk to about it.
                if ((client.mrName ?? '').isNotEmpty)
                  _Fact(icon: Icons.badge_outlined, text: client.mrName!),
              ],
            ),
            const Divider(height: 18),
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: client.canDial ? onDial : null,
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.success,
                    ),
                    icon: const Icon(Icons.call, size: 18),
                    label: Text(client.canDial ? 'Call' : 'No number'),
                  ),
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed: onLog,
                    style: TextButton.styleFrom(foregroundColor: AppTheme.teal),
                    icon: const Icon(Icons.edit_note, size: 20),
                    label: const Text('Log'),
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

/// How much of the list is on screen.
///
/// The server pages at 20 and this screen shows the first page, like every
/// other list in the app — so when there is more, say so plainly and point
/// at the search box rather than leaving the telecaller to wonder.
class _CountFooter extends StatelessWidget {
  const _CountFooter({required this.shown, required this.total});

  final int shown;
  final int total;

  @override
  Widget build(BuildContext context) {
    if (total <= shown) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        'Showing $shown of $total. Search to narrow the list.',
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppTheme.textSecondary),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}
