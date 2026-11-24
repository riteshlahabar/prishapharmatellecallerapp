import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/data/auth_repository.dart';
import '../../features/calls/data/calls_repository.dart';
import '../../features/messages/data/messages_repository.dart';
import '../../features/persons/data/persons_repository.dart';
import '../../features/products/data/products_repository.dart';
import '../api/api_client.dart';
import '../api/token_store.dart';
import '../dialer.dart';

/// Filled in `main()` once SharedPreferences has opened, so nothing below
/// has to be async just to read a token.
final tokenStoreProvider = Provider<TokenStore>(
  (ref) => throw UnimplementedError('overridden in main()'),
);

/// False until the splash screen has had its moment. The router holds every
/// route behind it, so the app opens on the logo instead of flashing the
/// login screen at a caller who is in fact signed in.
class SplashGate extends Notifier<bool> {
  @override
  bool build() => false;

  void done() => state = true;
}

final splashDoneProvider = NotifierProvider<SplashGate, bool>(SplashGate.new);

/// Set when the server rejects a token for good — expired, account switched
/// off, role moved. The router watches this and drops to the login screen,
/// and the login screen shows the reason once.
class SessionEnded extends Notifier<String?> {
  @override
  String? build() => null;

  void reason(String message) => state = message;

  void clear() => state = null;
}

final sessionEndedProvider = NotifierProvider<SessionEnded, String?>(
  SessionEnded.new,
);

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    tokens: ref.watch(tokenStoreProvider),
    onSignOut: (failure) async {
      await ref.read(tokenStoreProvider).clear();
      ref.read(sessionEndedProvider.notifier).reason(failure.message);
    },
  );
});

final dialerProvider = Provider<Dialer>((ref) => const Dialer());

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    ref.watch(apiClientProvider),
    ref.watch(tokenStoreProvider),
  ),
);

final productsRepositoryProvider = Provider<ProductsRepository>(
  (ref) => ProductsRepository(ref.watch(apiClientProvider)),
);

final personsRepositoryProvider = Provider<PersonsRepository>(
  (ref) => PersonsRepository(ref.watch(apiClientProvider)),
);

final callsRepositoryProvider = Provider<CallsRepository>(
  (ref) => CallsRepository(ref.watch(apiClientProvider)),
);

final messagesRepositoryProvider = Provider<MessagesRepository>(
  (ref) => MessagesRepository(ref.watch(apiClientProvider)),
);
