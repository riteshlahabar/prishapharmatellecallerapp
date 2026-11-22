import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_envelope.dart';
import '../../../core/state/providers.dart';
import '../domain/person.dart';

/// What the telecaller is searching the queue for. Empty means the whole
/// region-scoped list.
class QueueSearch extends Notifier<String> {
  @override
  String build() => '';

  void set(String value) => state = value;
}

final queueSearchProvider =
    NotifierProvider<QueueSearch, String>(QueueSearch.new);

/// The call queue, re-fetched whenever the search changes.
///
/// Logging a call changes a row's `last_call`, so the calls controller
/// invalidates this provider rather than trying to patch a row in place.
final queueProvider = FutureProvider<Paginated<Person>>((ref) {
  final search = ref.watch(queueSearchProvider);

  return ref.watch(personsRepositoryProvider).queue(search: search);
});
