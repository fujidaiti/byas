import 'package:paperdoll/core/network/dio_provider.dart';
import 'package:paperdoll/core/platform/device.dart';
import 'package:paperdoll/core/platform/secure_storage.dart';
import 'package:paperdoll/features/auth/data/auth_repository_impl.dart';
import 'package:paperdoll/features/auth/domain/auth_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_providers.g.dart';

@riverpod
AuthRepository authRepository(Ref ref) => AuthRepositoryImpl(
  ref.watch(dioProvider),
  ref.watch(secureStorageProvider),
);

/// The signed-in session: `null` when signed out, the bearer token when
/// signed in. [build] resolves the persisted token at startup; [signIn] and
/// [signUp] authenticate, persist the returned token, and update the state so
/// the router can react (see `goRouter`'s `redirect`).
@riverpod
class AuthSession extends _$AuthSession {
  late AuthRepository _repo;
  late Device _device;

  @override
  Future<String?> build() async {
    _repo = ref.watch(authRepositoryProvider);
    _device = ref.watch(deviceProvider);
    try {
      return await _repo.readAuthToken();
    } on Exception {
      // Treat an unreadable token as signed-out rather than surfacing an
      // error screen at startup.
      return null;
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    final device = await _device.label();
    final token = await _repo.signIn(
      email: email,
      password: password,
      device: device,
    );
    await _repo.writeAuthToken(token);
    state = AsyncData(token);
  }

  Future<void> signUp({required String email, required String password}) async {
    final device = await _device.label();
    final token = await _repo.signUp(
      email: email,
      password: password,
      device: device,
    );
    await _repo.writeAuthToken(token);
    state = AsyncData(token);
  }
}
