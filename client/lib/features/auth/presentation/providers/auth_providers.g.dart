// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(authRepository)
final authRepositoryProvider = AuthRepositoryProvider._();

final class AuthRepositoryProvider
    extends $FunctionalProvider<AuthRepository, AuthRepository, AuthRepository>
    with $Provider<AuthRepository> {
  AuthRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authRepositoryHash();

  @$internal
  @override
  $ProviderElement<AuthRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AuthRepository create(Ref ref) {
    return authRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthRepository>(value),
    );
  }
}

String _$authRepositoryHash() => r'5dfc4a721997a279f4ee58ceed1d946abe36dd9c';

/// The signed-in session: `null` when signed out, the bearer token when
/// signed in. [build] resolves the persisted token at startup; [signIn] and
/// [signUp] authenticate, persist the returned token, and update the state so
/// the router can react (see `goRouter`'s `redirect`).

@ProviderFor(AuthSession)
final authSessionProvider = AuthSessionProvider._();

/// The signed-in session: `null` when signed out, the bearer token when
/// signed in. [build] resolves the persisted token at startup; [signIn] and
/// [signUp] authenticate, persist the returned token, and update the state so
/// the router can react (see `goRouter`'s `redirect`).
final class AuthSessionProvider
    extends $AsyncNotifierProvider<AuthSession, String?> {
  /// The signed-in session: `null` when signed out, the bearer token when
  /// signed in. [build] resolves the persisted token at startup; [signIn] and
  /// [signUp] authenticate, persist the returned token, and update the state so
  /// the router can react (see `goRouter`'s `redirect`).
  AuthSessionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authSessionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authSessionHash();

  @$internal
  @override
  AuthSession create() => AuthSession();
}

String _$authSessionHash() => r'8d1dc2c313aa3ebd5b59db24398940c9d446e2f9';

/// The signed-in session: `null` when signed out, the bearer token when
/// signed in. [build] resolves the persisted token at startup; [signIn] and
/// [signUp] authenticate, persist the returned token, and update the state so
/// the router can react (see `goRouter`'s `redirect`).

abstract class _$AuthSession extends $AsyncNotifier<String?> {
  FutureOr<String?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<String?>, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<String?>, String?>,
              AsyncValue<String?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
