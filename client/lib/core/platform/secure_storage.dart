import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'secure_storage.g.dart';

@riverpod
SecureStorage secureStorage(Ref ref) => SecureStorage();

/// A driver for the device's secure local storage.
///
/// The API is deliberately limited to the auth token instead of arbitrary
/// key-value pairs, so that the physical key name stays an implementation
/// detail of whichever store backs the current platform.
abstract class SecureStorage {
  factory() {
    return switch (defaultTargetPlatform) {
      .android || .iOS => const _NativeSecureStorage(),
      _ => const _FlutterSecureStorage(),
    };
  }

  Future<String?> readAuthToken();

  /// Writes [value], or removes the token when it is null.
  Future<void> writeAuthToken(String? value);
}

class const _FlutterSecureStorage() implements SecureStorage {
  /// Unlike Android and iOS, no native code on these platforms reads the
  /// token, so nothing can drift out of sync with this key.
  static const _authTokenKey = 'auth_token';

  static const _delegate = FlutterSecureStorage();

  @override
  Future<String?> readAuthToken() => _delegate.read(key: _authTokenKey);

  @override
  Future<void> writeAuthToken(String? value) =>
      _delegate.write(key: _authTokenKey, value: value);
}

/// Talks to the platform's own store through a MethodChannel. The key the
/// token is stored under is known only to the native implementations.
class const _NativeSecureStorage() implements SecureStorage {
  static const _channel = MethodChannel(
    'dev.norelease.paperdoll/secure_storage',
  );

  @override
  Future<String?> readAuthToken() =>
      _channel.invokeMethod<String>('readAuthToken');

  @override
  Future<void> writeAuthToken(String? value) =>
      _channel.invokeMethod<void>('writeAuthToken', {'value': value});
}
