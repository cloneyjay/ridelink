import 'package:dio/dio.dart';

import '../api/api_exception.dart';
import '../config/app_config.dart';
import '../time/server_clock.dart';
import '../version/client_info.dart';
import 'session.dart';

/// Session endpoints. Uses its own Dio without the refresh interceptor.
class AuthApi {
  AuthApi(
    AppConfig config, {
    HttpClientAdapter? adapter,
    ServerClock? clock,
    ClientInfo? clientInfo,
  }) : _dio = Dio(
         BaseOptions(
           baseUrl: config.apiV1,
           contentType: Headers.jsonContentType,
           headers: {...?clientInfo?.headers},
         ),
       ) {
    if (adapter != null) _dio.httpClientAdapter = adapter;
    // Session expiry is compared on the server clock, so learn it from auth responses too.
    if (clock != null) {
      _dio.interceptors.add(
        InterceptorsWrapper(
          onResponse: (response, handler) {
            clock.observe(response.headers.value('date'));
            handler.next(response);
          },
          onError: (err, handler) {
            clock.observe(err.response?.headers.value('date'));
            handler.next(err);
          },
        ),
      );
    }
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
    required String acceptedTermsVersion,
    required String acceptedPrivacyVersion,
  }) => _post('auth/signup', {
    'email': email,
    'first_name': firstName,
    'last_name': lastName,
    'password': password,
    'accepted_terms_version': acceptedTermsVersion,
    'accepted_privacy_version': acceptedPrivacyVersion,
  });

  Future<Session> verifySignup({required String email, required String code}) =>
      _session('auth/signup/verify', {'email': email, 'code': code});

  Future<void> resendSignup(String email) =>
      _post('auth/signup/resend', {'email': email});

  /// A 403 with error `email_not_confirmed` means the code screen is next.
  Future<Session> signIn({required String email, required String password}) =>
      _session('auth/signin', {'email': email, 'password': password});

  /// The accepted versions are sent only when the user ticked the Terms checkbox; a new
  /// account without them gets 400 `legal_acceptance_required`.
  Future<Session> signInWithGoogle({
    required String idToken,
    required String rawNonce,
    String? acceptedTermsVersion,
    String? acceptedPrivacyVersion,
  }) => _session('auth/google', {
    'id_token': idToken,
    'nonce': rawNonce,
    'accepted_terms_version': ?acceptedTermsVersion,
    'accepted_privacy_version': ?acceptedPrivacyVersion,
  });

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
