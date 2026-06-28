import 'package:dio/dio.dart';

import 'package:paperdoll/core/error/domain_error.dart';

/// Runs a Dio call + JSON parse and normalizes transport failures into typed
/// [DomainError]s. The error interceptor attaches the mapped error to
/// [DioException.error]; anything unexpected becomes an [UnknownError].
Future<T> runRequest<T>(Future<T> Function() action) async {
  try {
    return await action();
  } on DioException catch (e) {
    final error = e.error;
    throw error is DomainError ? error : const UnknownError();
  }
}
