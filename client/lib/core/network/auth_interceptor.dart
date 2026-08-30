import 'package:dio/dio.dart';
import 'package:paperdoll/core/platform/secure_storage.dart';
import 'package:paperdoll/features/auth/presentation/providers/auth_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

/// Attaches the session token to every outgoing request and ends the session
/// when a response comes back 401.
class AuthInterceptor(final Ref _ref) extends Interceptor {
  /// Reads the token straight from secure storage rather than through
  /// `authSessionProvider`: `authSessionProvider` depends on this same `dio`
  /// provider (transitively, via the auth repository), so reading it back
  /// from here would be a genuine dependency cycle Riverpod rejects; storage
  /// has no such relationship and works uniformly for every request.
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _ref.read(secureStorageProvider).readAuthToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  /// Bumps [sessionInvalidationSignalProvider] rather than calling
  /// `authSessionProvider` directly, for the same cycle reason as
  /// [onRequest]. `authSessionProvider` listens to the signal and ends the
  /// session itself, which is always safe (it's a normal forward
  /// dependency), including for a bad-credentials `/signin` 401 — there's no
  /// session yet to end, so its no-op guard in `forceSignOut` covers that
  /// case too.
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      _ref.read(sessionInvalidationSignalProvider.notifier).fire();
    }
    handler.next(err);
  }
}
