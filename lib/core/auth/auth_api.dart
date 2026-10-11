import 'package:dio/dio.dart';

import '../api/api_exception.dart';
import '../config/app_config.dart';
import 'session.dart';

/// Session endpoints. Uses its own Dio without the refresh interceptor.
class AuthApi {
  AuthApi(AppConfig config, {HttpClientAdapter? adapter})
    : _dio = Dio(
        BaseOptions(
          baseUrl: config.apiV1,
          contentType: Headers.jsonContentType,
        ),
      ) {
    if (adapter != null) _dio.httpClientAdapter = adapter;
  }

  final Dio _dio;

  Future<Session> refresh(String refreshToken) =>
      _session('auth/refresh', {'refresh_token': refreshToken});

  /// 202 on success; the server emails a 6-digit code.
  Future<void> signUp({
    required String email,
    required String firstName,
    required String lastName,
    required String password,
  }) => _post('auth/signup', {
    'email': email,
    'first_name': firstName,
    'last_name': lastName,
    'password': password,
  });

  Future<Session> verifySignup({required String email, required String code}) =>
      _session('auth/signup/verify', {'email': email, 'code': code});

  Future<void> resendSignup(String email) =>
      _post('auth/signup/resend', {'email': email});

  /// A 403 with error `email_not_confirmed` means the code screen is next.
  Future<Session> signIn({required String email, required String password}) =>
      _session('auth/signin', {'email': email, 'password': password});

  Future<Session> signInWithGoogle({
    required String idToken,
    required String rawNonce,
  }) => _session('auth/google', {'id_token': idToken, 'nonce': rawNonce});

  /// Always 202, whether or not the account exists.
  Future<void> forgotPassword(String email) =>
      _post('auth/password/forgot', {'email': email});

  Future<Session> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) => _session('auth/password/reset', {
    'email': email,
    'code': code,
    'new_password': newPassword,
  });

  Future<Session> _session(String path, Map<String, dynamic> body) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(path, data: body);
      return Session.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> _post(String path, Map<String, dynamic> body) async {
    try {
      await _dio.post<void>(path, data: body);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> logout(String accessToken) async {
    try {
      await _dio.post<void>(
        'auth/logout',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
