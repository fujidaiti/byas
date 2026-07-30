import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'secure_storage.g.dart';

@riverpod
SecureStorage secureStorage(Ref ref) => const SecureStorage();

/// A driver for the device's secure local storage.
class SecureStorage {
  const SecureStorage();

  static const _impl = FlutterSecureStorage();

  Future<String?> read(String key) => _impl.read(key: key);

  Future<void> write(String key, String? value) =>
      _impl.write(key: key, value: value);
}
