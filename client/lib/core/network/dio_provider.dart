import 'package:dio/dio.dart';
import 'package:paperdoll/core/config/app_config_provider.dart';
import 'package:paperdoll/core/network/error_interceptor.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dio_provider.g.dart';

@riverpod
Dio dio(Ref ref) {
  final config = ref.watch(appConfigProvider);
  final client = Dio(BaseOptions(baseUrl: config.apiBaseUrl));
  client.interceptors.add(const ErrorInterceptor());
  ref.onDispose(client.close);
  return client;
}
