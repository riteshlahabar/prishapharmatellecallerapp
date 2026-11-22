import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';

/// Where the bearer token and the signed-in user live between launches.
///
/// NOTE: `SharedPreferences` is plain on-device storage. The token is
/// revocable server-side and dies with the account — Phase 6 made the API
/// re-check it on every request — but moving it to the Keychain/Keystore
/// (`flutter_secure_storage`) belongs on the release-hardening list before
/// this ships to real reps.
class TokenStore {
  const TokenStore(this._prefs);

  final SharedPreferences _prefs;

  static Future<TokenStore> open() async =>
      TokenStore(await SharedPreferences.getInstance());

  String? get token => _prefs.getString(AppConstants.tokenKey);

  bool get hasToken => (token ?? '').isNotEmpty;

  Map<String, dynamic>? get user {
    final raw = _prefs.getString(AppConstants.userKey);
    if (raw == null || raw.isEmpty) return null;

    try {
      return (jsonDecode(raw) as Map).cast<String, dynamic>();
    } on FormatException {
      // Written by an older build in a shape this one cannot read.
      return null;
    }
  }

  Future<void> save({required String token, Map<String, dynamic>? user}) async {
    await _prefs.setString(AppConstants.tokenKey, token);
    if (user != null) {
      await _prefs.setString(AppConstants.userKey, jsonEncode(user));
    }
  }

  Future<void> clear() async {
    await _prefs.remove(AppConstants.tokenKey);
    await _prefs.remove(AppConstants.userKey);
  }
}
