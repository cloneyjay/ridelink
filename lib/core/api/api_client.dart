import 'package:dio/dio.dart';

import '../auth/access_token_source.dart';
import '../config/app_config.dart';
import 'api_exception.dart';

/// REST client for the Go server. Paths are relative to /v1 (e.g. 'orders/123').
class ApiClient {
  ApiClient(
    AppConfig config, {
    required this._tokens,
    HttpClientAdapter? adapter,
  }) : _dio = Dio(
         BaseOptions(
           baseUrl: config.apiV1,
           contentType: Headers.jsonContentType,
         ),
       ) {
    if (adapter != null) _dio.httpClientAdapter = adapter;
    _dio.interceptors.add(
      InterceptorsWrapper(onRequest: _onRequest, onError: _onError),
    );
  }

  static const _retriedKey = 'ridelink.retried';

  final AccessTokenSource _tokens;
  final Dio _dio;

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _send(() => _dio.get(path, queryParameters: query));

  Future<dynamic> post(String path, {Object? data}) =>
      _send(() => _dio.post(path, data: data));

  Future<dynamic> patch(String path, {Object? data}) =>
      _send(() => _dio.patch(path, data: data));

  Future<dynamic> delete(String path, {Object? data}) =>
      _send(() => _dio.delete(path, data: data));

  Future<dynamic> _send(Future<Response<dynamic>> Function() call) async {
    try {
      return (await call()).data;
    } on DioException catch (e) {
      throw e.error is ApiException ? e.error! : ApiException.fromDio(e);
    }
  }

  void _onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _tokens.accessToken;
    if (token != null && !_isAuthPath(options)) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  Future<void> _onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final eligible =
        err.response?.statusCode == 401 &&
        !_isAuthPath(options) &&
        options.extra[_retriedKey] != true;
    if (!eligible) {
      handler.next(err);
      return;
    }
    // Another request may already have rotated the token; only refresh if ours is still current.
    final sentWith = options.headers['Authorization'];
    final current = _tokens.accessToken;
    final alreadyRotated = current != null && sentWith != 'Bearer $current';
    if (!alreadyRotated && !await _tokens.refresh()) {
      handler.next(err);
      return;
    }
    try {
      options.extra[_retriedKey] = true;
      options.headers['Authorization'] = 'Bearer ${_tokens.accessToken}';
      handler.resolve(await _dio.fetch<dynamic>(options));
    } on DioException catch (retryErr) {
      handler.next(retryErr);
    }
  }

  // Session endpoints manage their own tokens and must never trigger a refresh.
  static bool _isAuthPath(RequestOptions o) => o.uri.path.contains('/v1/auth/');
}
