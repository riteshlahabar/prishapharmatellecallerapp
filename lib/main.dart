import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'app.dart';
import 'core/api/token_store.dart';
import 'core/state/providers.dart';
import 'features/auth/state/auth_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Opened before the first frame so the router's redirect can read the
  // token synchronously and the app never flashes the login screen at a
  // rep who is already signed in.
  final tokens = await TokenStore.open();

  final container = ProviderContainer(
    overrides: [tokenStoreProvider.overrideWithValue(tokens)],
  );

  // Re-check the profile in the background. If the account was switched off
  // or re-roled since last launch, the client's sign-out hook clears the
  // token and the router moves to login on its own.
  if (tokens.hasToken) {
    unawaited(container.read(authControllerProvider.notifier).refresh());
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const App(),
    ),
  );
}
