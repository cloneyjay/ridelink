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

  Future<Session> refresh(String refreshToken) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        'auth/refresh',
        data: {'refresh_token': refreshToken},
      );
      return Session.fromJson(res.data!);
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
