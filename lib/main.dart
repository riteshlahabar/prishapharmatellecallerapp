import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'app.dart';
import 'core/api/token_store.dart';
import 'core/state/providers.dart';
import 'features/auth/state/auth_controller.dart';

/// How long the Android launch window stays up — the logo Android paints on
/// `launch_background` before Flutter can draw anything.
///
/// There is no second, Flutter-drawn splash. The first frame is simply held
/// back until this has elapsed, so the one splash the user sees is the
/// native one, and when the app finally paints it is already on login or on
/// the shell rather than on a screen that then replaces itself.
const Duration splashHold = Duration(seconds: 5);

Future<void> main() async {
  final startedAt = DateTime.now();
  final binding = WidgetsFlutterBinding.ensureInitialized();

  // Nothing is rasterised until allowFirstFrame(), which is what keeps the
  // native splash on screen for the whole hold.
  binding.deferFirstFrame();

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

  // Measured from process start, so a slow cold start spends the hold
  // rather than adding another five seconds on top of it.
  final remaining = splashHold - DateTime.now().difference(startedAt);
  if (remaining > Duration.zero) await Future<void>.delayed(remaining);

  binding.allowFirstFrame();
}
