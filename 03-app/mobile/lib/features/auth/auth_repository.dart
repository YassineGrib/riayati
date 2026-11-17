import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/api/token_store.dart';
import 'user.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    ref.watch(apiClientProvider),
    ref.watch(tokenStoreProvider),
  ),
);

class AuthRepository {
  AuthRepository(this.api, this.tokens);
  final ApiClient api;
  final TokenStore tokens;
  Future<User> signIn({required String email, required String password}) =>
      _authenticate('/login', {'email': email, 'password': password});
  Future<User> register({
    required String name,
    required String email,
    required String password,
    required String role,
    required bool terms,
  }) => _authenticate('/register', {
    'name': name,
    'email': email,
    'password': password,
    'role': role,
    'terms': terms,
  });
  Future<User> _authenticate(String path, Map<String, dynamic> data) async {
    final json = await api.post<Map<String, dynamic>>(path, data: data);
    final user = User.fromJson(json['user'] as Map<String, dynamic>);
    await tokens.write(json['token'] as String);
    return user;
  }

  Future<User> me() async => User.fromJson(
    (await api.get<Map<String, dynamic>>('/me'))['user']
        as Map<String, dynamic>,
  );
  Future<void> forgotPassword(String email) async {
    await api.post<dynamic>('/forgot-password', data: {'email': email});
  }

  Future<void> signOut() async {
    try {
      await api.post<dynamic>('/logout');
    } finally {
      await tokens.clear();
    }
  }
}
