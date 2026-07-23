import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the bearer token issued by `/signup` and `/signin` across app
/// launches.
abstract interface class TokenStorage {
  Future<String?> read();
  Future<void> write(String token);
  Future<void> delete();
}

class SecureTokenStorage implements TokenStorage {
  const SecureTokenStorage(this._storage);

  final FlutterSecureStorage _storage;

  static const _tokenKey = 'auth_token';

  @override
  Future<String?> read() => _storage.read(key: _tokenKey);

  @override
  Future<void> write(String token) =>
      _storage.write(key: _tokenKey, value: token);

  @override
  Future<void> delete() => _storage.delete(key: _tokenKey);
}
