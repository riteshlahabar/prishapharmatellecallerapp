import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';

final apiServiceProvider = FutureProvider<ApiService>((ref) async {
  return ApiService.create();
});

final authServiceProvider = FutureProvider<AuthService>((ref) async {
  final api = await ref.watch(apiServiceProvider.future);
  return AuthService(api);
});

final isLoggedInProvider = FutureProvider<bool>((ref) async {
  final auth = await ref.watch(authServiceProvider.future);
  return auth.isLoggedIn();
});