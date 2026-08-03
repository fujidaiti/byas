import 'package:dio/dio.dart';
import 'package:paperdoll/core/config/app_config_provider.dart';
import 'package:paperdoll/core/network/auth_interceptor.dart';
import 'package:paperdoll/core/network/error_interceptor.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dio_provider.g.dart';

/// Bounds every request so a stalled connection surfaces a network error
/// instead of leaving the UI spinning forever.
const _connectTimeout = Duration(seconds: 10);
const _receiveTimeout = Duration(seconds: 15);
const _sendTimeout = Duration(seconds: 15);

// Kept alive for the app's lifetime: the client owns a connection pool and is
// a singleton. Auto-disposing it would let an in-flight request (e.g. sign-in,
// where nothing watches this provider during the round-trip) close the client
// mid-flight, failing with a "connection after it was closed" error.
@Riverpod(keepAlive: true)
Dio dio(Ref ref) {
  final config = ref.watch(appConfigProvider);
  final client = Dio(
    BaseOptions(
      baseUrl: config.apiBaseUrl,
      connectTimeout: _connectTimeout,
      receiveTimeout: _receiveTimeout,
      sendTimeout: _sendTimeout,
    ),
  );
  client.interceptors.add(AuthInterceptor(ref));
  client.interceptors.add(const ErrorInterceptor());
  ref.onDispose(client.close);
  return client;
}
