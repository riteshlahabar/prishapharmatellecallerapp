import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_envelope.dart';
import '../../../core/state/providers.dart';
import '../domain/recipient.dart';
import '../domain/sent_message.dart';

/// Who this telecaller may write to.
///
/// Keyed by the person being written about, because naming one widens the
/// picker to include that person's own rep even when they are based in
/// another region — the common "I spoke to this doctor, their rep should
/// visit" case.
final recipientsProvider =
    FutureProvider.family<List<Recipient>, int?>((ref, personId) {
  return ref.watch(messagesRepositoryProvider).recipients(personId: personId);
});

class SentMessages extends AsyncNotifier<Paginated<SentMessage>> {
  @override
  Future<Paginated<SentMessage>> build() =>
      ref.watch(messagesRepositoryProvider).sent();

  Future<void> reload() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(messagesRepositoryProvider).sent(),
    );
  }
}

final sentMessagesProvider =
    AsyncNotifierProvider<SentMessages, Paginated<SentMessage>>(
  SentMessages.new,
);
