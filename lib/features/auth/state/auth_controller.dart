import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/state/providers.dart';
import '../domain/app_user.dart';

/// Who is signed in, if anyone.
///
/// Starts from the cached user so the app opens on the home screen rather
/// than flashing login, then refreshes from `/auth/me` in the background —
/// which is also how a token revoked since last launch gets noticed.
class AuthController extends Notifier<AppUser?> {
  @override
  AppUser? build() => ref.watch(authRepositoryProvider).cachedUser;

  Future<void> signIn({required String email, required String password}) async {
    final user = await ref
        .read(authRepositoryProvider)
        .login(email: email, password: password);

    ref.read(sessionEndedProvider.notifier).clear();
    state = user;
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).logout();
    state = null;
  }

  /// Re-reads the profile. Any failure is swallowed: if the token has died
  /// the client's sign-out hook has already cleared it and the router will
  /// move. There is nothing useful to show the rep here.
  Future<void> refresh() async {
    try {
      state = await ref.read(authRepositoryProvider).me();
    } on Object {
      state = ref.read(authRepositoryProvider).cachedUser;
    }
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AppUser?>(AuthController.new);

/// True when a token is on disk. Read by the router's redirect.
final isSignedInProvider = Provider<bool>((ref) {
  // Depend on the controller so a sign-in or sign-out re-evaluates this.
  ref.watch(authControllerProvider);

  return ref.watch(authRepositoryProvider).isSignedIn;
});
