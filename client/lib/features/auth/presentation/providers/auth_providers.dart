import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:paperdoll/core/network/dio_provider.dart';
import 'package:paperdoll/features/auth/data/auth_repository_impl.dart';
import 'package:paperdoll/features/auth/data/token_storage.dart';
import 'package:paperdoll/features/auth/domain/auth_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_providers.g.dart';

@riverpod
TokenStorage tokenStorage(Ref ref) => const SecureTokenStorage();

@riverpod
AuthRepository authRepository(Ref ref) =>
    AuthRepositoryImpl(ref.watch(dioProvider));

@riverpod
DeviceInfoPlugin deviceInfoPlugin(Ref ref) => DeviceInfoPlugin();

/// The signed-in session: `null` when signed out, the bearer token when
/// signed in. [build] resolves the persisted token at startup; [signIn] and
/// [signUp] authenticate, persist the returned token, and update the state so
/// the router can react (see `goRouter`'s `redirect`).
@riverpod
class AuthSession extends _$AuthSession {
  late AuthRepository _repo;
  late TokenStorage _tokenStorage;
  late DeviceInfoPlugin _deviceInfoPlugin;

  @override
  Future<String?> build() async {
    _repo = ref.watch(authRepositoryProvider);
    _tokenStorage = ref.watch(tokenStorageProvider);
    _deviceInfoPlugin = ref.watch(deviceInfoPluginProvider);
    try {
      return await _tokenStorage.read();
    } on Exception {
      // Treat an unreadable token as signed-out rather than surfacing an
      // error screen at startup.
      return null;
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    final device = await _buildDeviceLabel();
    final token = await _repo.signIn(
      email: email,
      password: password,
      device: device,
    );
    await _tokenStorage.write(token);
    state = AsyncData(token);
  }

  Future<void> signUp({required String email, required String password}) async {
    final device = await _buildDeviceLabel();
    final token = await _repo.signUp(
      email: email,
      password: password,
      device: device,
    );
    await _tokenStorage.write(token);
    state = AsyncData(token);
  }

  /// Builds the `device` label sent to `/signup` and `/signin`, in the form
  /// `<device model>/<os version>` (e.g. `iPhone15,3/17.4`, `Pixel 8 Pro/14`).
  /// Stored server-side alongside the issued token for session debugging.
  Future<String> _buildDeviceLabel() async {
    if (Platform.isAndroid) {
      final info = await _deviceInfoPlugin.androidInfo;
      return '${info.model}/${info.version.release}';
    }
    if (Platform.isIOS) {
      final info = await _deviceInfoPlugin.iosInfo;
      return '${info.utsname.machine}/${info.systemVersion}';
    }
    if (Platform.isMacOS) {
      final info = await _deviceInfoPlugin.macOsInfo;
      return '${info.model}/${info.osRelease}';
    }
    return Platform.operatingSystem;
  }
}
