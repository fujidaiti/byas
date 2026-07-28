import 'package:paperdoll/core/network/dio_provider.dart';
import 'package:paperdoll/features/auth/data/auth_repository_impl.dart';
import 'package:paperdoll/features/auth/data/device_label.dart';
import 'package:paperdoll/features/auth/data/token_storage.dart';
import 'package:paperdoll/features/auth/domain/auth_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_providers.g.dart';

@riverpod
TokenStorage tokenStorage(Ref ref) => const SecureTokenStorage();

@riverpod
AuthRepository authRepository(Ref ref) =>
    AuthRepositoryImpl(ref.watch(dioProvider));

/// The signed-in session: `null` when signed out, the bearer token when
/// signed in. [build] resolves the persisted token at startup; [signIn] and
/// [signUp] authenticate, persist the returned token, and update the state so
/// the router can react (see `goRouter`'s `redirect`).
@riverpod
class AuthSession extends _$AuthSession {
  late AuthRepository _repo;

  @override
  Future<String?> build() async {
    _repo = ref.watch(authRepositoryProvider);
    try {
      return await ref.watch(tokenStorageProvider).read();
    } on Exception {
      // Treat an unreadable token as signed-out rather than surfacing an
      // error screen at startup.
      return null;
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    final device = await buildDeviceLabel();
    final token = await _repo.signIn(
      email: email,
      password: password,
      device: device,
    );
    await ref.read(tokenStorageProvider).write(token);
    state = AsyncData(token);
  }

  Future<void> signUp({required String email, required String password}) async {
    final device = await buildDeviceLabel();
    final token = await _repo.signIn(
      email: email,
      password: password,
      device: device,
    );
    await ref.read(tokenStorageProvider).write(token);
    state = AsyncData(token);
  }
}
