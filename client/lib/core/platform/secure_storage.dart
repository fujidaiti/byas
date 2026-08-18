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
      .android || .iOS => const _NativeSecureStorage(),
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

/// Talks to the platform's own store through a MethodChannel, so that native
/// code outside the Flutter engine — Android's SaveWebClipActivity, iOS's
/// share extension — reads the same physical item this writes.
class const _NativeSecureStorage() implements SecureStorage {
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
