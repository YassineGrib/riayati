import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/api/token_store.dart';
import 'auth_repository.dart';
import 'user.dart';

enum AuthStatus { unknown, signedOut, signedIn }

class AuthState {
  const AuthState.unknown() : status = AuthStatus.unknown, user = null;
  const AuthState.signedOut() : status = AuthStatus.signedOut, user = null;
  const AuthState.signedIn(User this.user) : status = AuthStatus.signedIn;
  final AuthStatus status;
  final User? user;
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    final api = ref.watch(apiClientProvider);
    api.onUnauthorized = () async {
      state = const AuthState.signedOut();
    };
    api.onNotLinked = () {
      final user = state.user;
      if (user != null) state = AuthState.signedIn(user.unlinked());
    };
    ref.onDispose(() {
      api.onUnauthorized = null;
      api.onNotLinked = null;
    });
    return const AuthState.unknown();
  }

  Future<void> signIn({required String email, required String password}) async {
    state = AuthState.signedIn(
      await ref
          .read(authRepositoryProvider)
          .signIn(email: email, password: password),
    );
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String role,
    required bool terms,
  }) async {
    state = AuthState.signedIn(
      await ref
          .read(authRepositoryProvider)
          .register(
            name: name,
            email: email,
            password: password,
            role: role,
            terms: terms,
          ),
    );
  }

  Future<void> signOut() async {
    try {
      await ref.read(authRepositoryProvider).signOut();
    } finally {
      state = const AuthState.signedOut();
    }
  }

  Future<void> updateProfile({
    required String name,
    required String email,
    String? phone,
    String? wilaya,
    int? childrenCount,
    String? currentPassword,
  }) async {
    final previous = state.user;
    if (previous == null) return;
    final updated = await ref
        .read(authRepositoryProvider)
        .updateProfile(
          name: name,
          email: email,
          phone: phone,
          wilaya: wilaya,
          childrenCount: childrenCount,
          currentPassword: currentPassword,
        );
    // A request that finishes after sign-out must not restore the session.
    if (state.user?.id == previous.id) state = AuthState.signedIn(updated);
  }

  Future<void> refresh() async {
    if (await ref.read(tokenStoreProvider).read() == null) {
      state = const AuthState.signedOut();
      return;
    }
    state = AuthState.signedIn(await ref.read(authRepositoryProvider).me());
  }
}
