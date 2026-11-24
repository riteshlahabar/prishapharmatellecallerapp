import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_envelope.dart';
import '../../../core/state/providers.dart';
import '../../persons/state/persons_controller.dart';
import '../../products/domain/product.dart';
import '../domain/call_log.dart';
import '../domain/call_status.dart';

/// This telecaller's own call history.
class CallHistory extends AsyncNotifier<Paginated<CallLog>> {
  @override
  Future<Paginated<CallLog>> build() =>
      ref.watch(callsRepositoryProvider).history();

  Future<void> reload() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(callsRepositoryProvider).history(),
    );
  }
}

final callHistoryProvider =
    AsyncNotifierProvider<CallHistory, Paginated<CallLog>>(CallHistory.new);

/// Whether the follow-up screen is showing only what is due, or everything
/// still promised.
class FollowUpsDueOnly extends Notifier<bool> {
  @override
  bool build() => true;

  void toggle() => state = !state;
}

final followUpsDueOnlyProvider = NotifierProvider<FollowUpsDueOnly, bool>(
  FollowUpsDueOnly.new,
);

final followUpsProvider = FutureProvider<Paginated<CallLog>>((ref) {
  final dueOnly = ref.watch(followUpsDueOnlyProvider);

  return ref.watch(callsRepositoryProvider).followUps(dueOnly: dueOnly);
});

/// The one place a call is written, so every list that shows the result is
/// refreshed together and none of them can go stale on their own.
class CallActions {
  const CallActions(this._ref);

  final Ref _ref;

  Future<CallLog> log({
    required int personId,
    required CallStatus status,
    String? notes,
    DateTime? followUpAt,
    List<ProductLineInput> products = const [],
  }) async {
    final call = await _ref
        .read(callsRepositoryProvider)
        .log(
          personId: personId,
          status: status,
          notes: notes,
          followUpAt: followUpAt,
          products: products,
        );

    _refreshAll();

    return call;
  }

  Future<CallLog> completeFollowUp(int id) async {
    final call = await _ref.read(callsRepositoryProvider).completeFollowUp(id);

    _refreshAll();

    return call;
  }

  /// Logging a call closes any open call-back on that person server-side and
  /// changes the queue row's `last_call`, so all three views move together.
  void _refreshAll() {
    _ref.invalidate(queueProvider);
    _ref.invalidate(followUpsProvider);
    _ref.read(callHistoryProvider.notifier).reload();
  }
}

final callActionsProvider = Provider<CallActions>(CallActions.new);
