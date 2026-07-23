import 'package:dio/dio.dart';
import 'package:openapi/api.dart' as api;
import 'package:paperdoll/core/network/request_runner.dart';
import 'package:paperdoll/features/auth/domain/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<String> signUp({
    required String email,
    required String password,
    required String device,
  }) {
    return runRequest(() async {
      final res = await _dio.post<Map<String, dynamic>>(
        '/signup',
        data: api.SignUpRequest(
          email: email,
          password: password,
          device: device,
        ).toJson(),
      );
      return api.SignUp201Response.fromJson(res.data)!.token;
    });
  }

  @override
  Future<String> signIn({
    required String email,
    required String password,
    required String device,
  }) {
    return runRequest(() async {
      final res = await _dio.post<Map<String, dynamic>>(
        '/signin',
        data: api.SignInRequest(
          email: email,
          password: password,
          device: device,
        ).toJson(),
      );
      // The signin 200 response has the same {token} shape as signup's 201;
      // the generator didn't emit a distinct type for it.
      return api.SignUp201Response.fromJson(res.data)!.token;
    });
  }
}
