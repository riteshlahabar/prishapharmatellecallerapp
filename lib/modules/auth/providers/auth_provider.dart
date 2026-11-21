import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';

class User {
  final String? id;
  final String? name;
  final String? email;
  final String? role;

  const User({this.id, this.name, this.email, this.role});

  User copyWith({String? id, String? name, String? email, String? role}) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
    );
  }

  bool get isEmpty => id == null && name == null && email == null && role == null;

  @override
  String toString() => 'User(id: $id, name: $name, email: $email, role: $role)';
}

class AuthNotifier extends Notifier<User?> {
  @override
  User? build() => null;

  Future<String?> _callAuthMethod(Future<String?> Function() fn) async {
    try {
      return await fn();
    } catch (_) {
      return null;
    }
  }

  Future<void> login(String email, String password) async {
    final authAsync = ref.read(authServiceProvider);
    final auth = authAsync.value;
    if (auth == null) return;

    state = const User(id: 'loading', name: '', email: '', role: '');
    final success = await auth.login(email: email, password: password);
    if (success) {
      await refreshUser();
    } else {
      state = null;
    }
  }

  Future<void> logout() async {
    final authAsync = ref.read(authServiceProvider);
    final auth = authAsync.value;
    if (auth != null) {
      await auth.logout();
    }
    state = null;
  }

  Future<void> refreshUser() async {
    final authAsync = ref.read(authServiceProvider);
    final auth = authAsync.value;
    if (auth == null) return;

    final id = await _callAuthMethod(auth.getUserId);
    final name = await _callAuthMethod(auth.getUserName);
    final role = await _callAuthMethod(auth.getRole);
    state = User(id: id, name: name, email: null, role: role);
  }
}

final authNotifierProvider = NotifierProvider<AuthNotifier, User?>((ref) {
  return AuthNotifier(ref);
});
