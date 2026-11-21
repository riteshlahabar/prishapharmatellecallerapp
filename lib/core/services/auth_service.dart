import 'package:dio/dio.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _api;
  final PreferencesService _prefs;
  bool _isLoggedIn = false;

  AuthService(this._api, this._prefs) {
    _checkLoginStatus();
  }

  bool get isLoggedIn => _isLoggedIn;

  Future<void> _checkLoginStatus() async {
    final token = await _prefs.getAccessToken();
    _isLoggedIn = token != null && token.isNotEmpty;
  }

  Future<String?> getToken() async {
    return _prefs.getAccessToken();
  }

  Future<String?> getUserName() async {
    return _prefs.getUserName();
  }

  Future<String?> getUserId() async {
    final id = await _prefs.getUserId();
    return id?.toString();
  }

  Future<String?> getRole() async {
    return 'telecaller';
  }

  Future<bool> login({required String email, required String password}) async {
    try {
      final response = await _api.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final accessToken = data['access_token'] ?? data['token'];

        if (accessToken != null) {
          await _prefs.saveAccessToken(accessToken);
          _api.dio.options.headers['Authorization'] = 'Bearer $accessToken';

          if (data['user'] != null) {
            final user = data['user'];
            await _prefs.saveUserId(user['id'] as int);
            await _prefs.saveUserName(user['name'] as String);
            await _prefs.saveUserEmail(user['email'] as String);
          }
          _isLoggedIn = true;
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> logout() async {
    try {
      await _api.post('/auth/logout');
    } catch (e) {
      // ignore error during logout
    } finally {
      await _prefs.clear();
      _api.dio.options.headers.remove('Authorization');
      _isLoggedIn = false;
    }
    return true;
  }
}