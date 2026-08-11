import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'secure_storage.g.dart';

@riverpod
SecureStorage secureStorage(Ref ref) => SecureStorage();

/// A driver for the device's secure local storage.
abstract class SecureStorage {
  factory SecureStorage() {
    return switch (defaultTargetPlatform) {
      .android => const _AndroidSecureStorage(),
      _ => const _FlutterSecureStorage(),
    };
  }

  Future<String?> read(String key);

  Future<void> write(String key, String? value);
}

class _FlutterSecureStorage implements SecureStorage {
  const _FlutterSecureStorage();

  static const _delegate = FlutterSecureStorage();

  @override
  Future<String?> read(String key) => _delegate.read(key: key);

  @override
  Future<void> write(String key, String? value) =>
      _delegate.write(key: key, value: value);
}

/// On Android, storage is backed by a native DataStore holding values encrypted
/// with an Android Keystore key (see `TokenStore.kt`) rather than by
/// `flutter_secure_storage`, so that `SaveWebClipActivity` — a native activity
/// launched from the share sheet, outside the Flutter engine — can read the
/// same token directly.
class _AndroidSecureStorage implements SecureStorage {
  const _AndroidSecureStorage();

  static const _channel = MethodChannel(
    'dev.norelease.paperdoll/secure_storage',
  );

  @override
  Future<String?> read(String key) =>
      _channel.invokeMethod<String>('read', {'key': key});

  @override
  Future<void> write(String key, String? value) =>
      _channel.invokeMethod<void>('write', {'key': key, 'value': value});
}
