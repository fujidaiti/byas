import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'secure_storage.g.dart';

@riverpod
SecureStorage secureStorage(Ref ref) => const SecureStorage();

/// A driver for the device's secure local storage.
///
/// On Android this is backed by a native `EncryptedSharedPreferences` store
/// (via [_AndroidSecureStorage]) rather than `flutter_secure_storage`, so
/// that `SaveWebClipActivity` — a native activity launched from the share
/// sheet, outside the Flutter engine — can read the same token directly.
/// iOS/macOS keep using `flutter_secure_storage`, which has no such native
/// counterpart to share storage with.
class SecureStorage {
  const SecureStorage();

  static final _impl = Platform.isAndroid
      ? const _AndroidSecureStorage()
      : const _FlutterSecureStorage();

  Future<String?> read(String key) => _impl.read(key);

  Future<void> write(String key, String? value) => _impl.write(key, value);
}

abstract interface class _SecureStorageImpl {
  Future<String?> read(String key);

  Future<void> write(String key, String? value);
}

class _FlutterSecureStorage implements _SecureStorageImpl {
  const _FlutterSecureStorage();

  static const _delegate = FlutterSecureStorage();

  @override
  Future<String?> read(String key) => _delegate.read(key: key);

  @override
  Future<void> write(String key, String? value) =>
      _delegate.write(key: key, value: value);
}

class _AndroidSecureStorage implements _SecureStorageImpl {
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
