import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_envelope.dart';
import '../../../core/state/providers.dart';
import '../domain/assignee.dart';
import '../domain/client_type.dart';
import '../domain/person.dart';

/// What the telecaller is searching the queue for. Empty means the whole
/// region-scoped list.
class QueueSearch extends Notifier<String> {
  @override
  String build() => '';

  void set(String value) => state = value;
}

final queueSearchProvider = NotifierProvider<QueueSearch, String>(
  QueueSearch.new,
);

/// The call queue, re-fetched whenever the search changes.
///
/// Logging a call changes a row's `last_call`, so the calls controller
/// invalidates this provider rather than trying to patch a row in place.
final queueProvider = FutureProvider<Paginated<Person>>((ref) {
  final search = ref.watch(queueSearchProvider);

  return ref.watch(personsRepositoryProvider).queue(search: search);
});

/// What the telecaller is searching My Clients for. Its own notifier, not
/// the queue's: the two screens are separate lists and a search typed into
/// one must not reload the other.
class MyClientsSearch extends Notifier<String> {
  @override
  String build() => '';

  void set(String value) => state = value;
}

final myClientsSearchProvider = NotifierProvider<MyClientsSearch, String>(
  MyClientsSearch.new,
);

/// My Clients: the clients this telecaller is the assigned one of,
/// re-fetched whenever the search changes.
///
/// A different question from [queueProvider] — see `PersonsRepository.mine`.
final myClientsProvider = FutureProvider<Paginated<Person>>((ref) {
  final search = ref.watch(myClientsSearchProvider);

  return ref.watch(personsRepositoryProvider).mine(search: search);
});

/// The kinds of client the Add Client form may offer. Loaded from the
/// panel's master rather than hard-coded, and cached for the session: the
/// table is tiny and changes about never.
final clientTypesProvider = FutureProvider<List<ClientType>>(
  (ref) => ref.watch(personsRepositoryProvider).clientTypes(),
);

/// Every active MR, for the Add Client dropdown.
final assignableMrsProvider = FutureProvider<List<Assignee>>(
  (ref) => ref.watch(personsRepositoryProvider).assignableMrs(),
);

/// Everything a new client makes stale, in one place so neither the form nor
/// a future caller has to remember the list: My Clients gains a row, and the
/// queue does too when the client lands in a region this telecaller covers.
void invalidateClientLists(WidgetRef ref) {
  ref.invalidate(myClientsProvider);
  ref.invalidate(queueProvider);
}
