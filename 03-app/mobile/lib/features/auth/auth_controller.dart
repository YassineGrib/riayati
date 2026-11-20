import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/api/token_store.dart';
import 'auth_repository.dart';
import 'user.dart';

enum AuthStatus { unknown, signedOut, signedIn }

class AuthState {
  const AuthState.unknown()
    : status = AuthStatus.unknown,
      user = null,
      linkSkipped = false;
  const AuthState.signedOut()
    : status = AuthStatus.signedOut,
      user = null,
      linkSkipped = false;
  const AuthState.signedIn(User this.user, {this.linkSkipped = false})
    : status = AuthStatus.signedIn;
  final AuthStatus status;
  final User? user;

  /// The parent chose "skip for now" on the link screen. Only the shared
  /// calendar needs a partner; everything else works unlinked.
  final bool linkSkipped;
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
      if (user != null) {
        state = AuthState.signedIn(
          user.unlinked(),
          linkSkipped: state.linkSkipped,
        );
      }
    };
    ref.onDispose(() {
      api.onUnauthorized = null;
      api.onNotLinked = null;
    });
    return const AuthState.unknown();
  }

  Future<bool> _readSkip() async {
    try {
      return await ref.read(linkSkipStoreProvider).read();
    } catch (_) {
      return false;
    }
  }

  Future<void> _writeSkip(bool skipped) async {
    try {
      await ref.read(linkSkipStoreProvider).write(skipped);
    } catch (_) {}
  }

  Future<void> signIn({required String email, required String password}) async {
    final user = await ref
        .read(authRepositoryProvider)
        .signIn(email: email, password: password);
    state = AuthState.signedIn(
      user,
      linkSkipped: !user.linked && await _readSkip(),
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
      _writeSkip(false); // best effort; never blocks signing out
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
    if (state.user?.id == previous.id) {
      state = AuthState.signedIn(updated, linkSkipped: state.linkSkipped);
    }
  }

  Future<void> refresh() async {
    if (await ref.read(tokenStoreProvider).read() == null) {
      state = const AuthState.signedOut();
      return;
    }
    final user = await ref.read(authRepositoryProvider).me();
    final skipped = state.linkSkipped || (!user.linked && await _readSkip());
    state = AuthState.signedIn(user, linkSkipped: skipped);
  }

  /// Lets an unlinked parent into the app; the calendar keeps asking to link.
  void skipLink() {
    final user = state.user;
    if (user == null) return;
    state = AuthState.signedIn(user, linkSkipped: true);
    _writeSkip(true);
  }
}
