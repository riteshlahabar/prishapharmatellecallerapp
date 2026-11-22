import '../../../core/api/api_client.dart';
import '../../../core/api/token_store.dart';
import '../../../core/constants.dart';
import '../domain/app_user.dart';

class AuthRepository {
  const AuthRepository(this._api, this._tokens);

  final ApiClient _api;
  final TokenStore _tokens;

  /// Signs in and keeps the token.
  ///
  /// `role` is sent so the server refuses a telecaller's credentials here,
  /// rather than letting them in and failing on the first MR endpoint with
  /// a confusing 403 (docs/api/v1-auth.md).
  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    final envelope = await _api.post(
      AppConstants.login,
      body: {
        'email': email.trim(),
        'password': password,
        'role': AppConstants.appRole,
        'device_name': AppConstants.deviceName,
      },
    );

    final data = envelope.dataMap;
    final user = AppUser.fromJson(
      (data['user'] as Map?)?.cast<String, dynamic>() ?? const {},
    );

    await _tokens.save(
      token: data['token'] as String? ?? '',
      user: user.toJson(),
    );

    return user;
  }

  Future<AppUser> me() async {
    final envelope = await _api.get(AppConstants.me);
    final user = AppUser.fromJson(envelope.dataMap);

    // Refresh the cached copy: the rep's region can change under them.
    await _tokens.save(token: _tokens.token ?? '', user: user.toJson());

    return user;
  }

  /// Best-effort: the local token goes either way. If the network call
  /// fails the server-side token is left behind, but it is scoped to this
  /// device name and the next login replaces it.
  Future<void> logout() async {
    try {
      await _api.post(AppConstants.logout);
    } on Object {
      // Ignored on purpose — see above.
    } finally {
      await _tokens.clear();
    }
  }

  AppUser? get cachedUser {
    final json = _tokens.user;

    return json == null ? null : AppUser.fromJson(json);
  }

  bool get isSignedIn => _tokens.hasToken;
}
