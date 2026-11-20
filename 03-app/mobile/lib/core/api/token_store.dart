import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class TokenStore {
  Future<String?> read();
  Future<void> write(String token);
  Future<void> clear();
}

class SecureTokenStore implements TokenStore {
  const SecureTokenStore();
  static const _storage = FlutterSecureStorage();
  static const _key = 'auth_token';
  @override
  Future<String?> read() => _storage.read(key: _key);
  @override
  Future<void> write(String token) => _storage.write(key: _key, value: token);
  @override
  Future<void> clear() => _storage.delete(key: _key);
}

final tokenStoreProvider = Provider<TokenStore>(
  (ref) => const SecureTokenStore(),
);

/// Remembers that the parent chose "skip for now" on the link screen.
abstract interface class LinkSkipStore {
  Future<bool> read();
  Future<void> write(bool skipped);
}

class SecureLinkSkipStore implements LinkSkipStore {
  const SecureLinkSkipStore();
  static const _storage = FlutterSecureStorage();
  static const _key = 'link_skipped';
  @override
  Future<bool> read() async => (await _storage.read(key: _key)) == '1';
  @override
  Future<void> write(bool skipped) => skipped
      ? _storage.write(key: _key, value: '1')
      : _storage.delete(key: _key);
}

final linkSkipStoreProvider = Provider<LinkSkipStore>(
  (ref) => const SecureLinkSkipStore(),
);
