import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'secure_storage.g.dart';

@riverpod
SecureStorage secureStorage(Ref ref) => SecureStorage();

/// A driver for the device's secure local storage.
abstract class SecureStorage {
  factory() {
    return switch (defaultTargetPlatform) {
      .android => const _AndroidSecureStorage(),
      _ => const _FlutterSecureStorage(),
    };
  }

  Future<String?> read(String key);

  Future<void> write(String key, String? value);
}

class const _FlutterSecureStorage() implements SecureStorage {
  static const _delegate = FlutterSecureStorage();

  @override
  Future<String?> read(String key) => _delegate.read(key: key);

  @override
  Future<void> write(String key, String? value) =>
      _delegate.write(key: key, value: value);
}

class const _AndroidSecureStorage() implements SecureStorage {
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
