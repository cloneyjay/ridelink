import 'package:dio/dio.dart';

/// A failed API call. [statusCode] is null when the server could not be reached.
class ApiException implements Exception {
  const ApiException({
    this.statusCode,
    required this.message,
    this.code,
    this.body = const {},
    this.retryAfter,
  });

  factory ApiException.fromDio(DioException e) {
    final response = e.response;
    if (response == null) {
      return ApiException(message: e.message ?? e.type.name);
    }
    final data = response.data;
    final map = data is Map ? data.cast<String, dynamic>() : null;
    final serverMessage = map?['error'] is String
        ? map!['error'] as String
        : null;
    return ApiException(
      statusCode: response.statusCode,
      message:
          serverMessage ??
          response.statusMessage ??
          'HTTP ${response.statusCode}',
      code: map?['code'] is String ? map!['code'] as String : null,
      body: map ?? const {},
      retryAfter: _parseRetryAfter(response.headers.value('retry-after')),
    );
  }

  /// Delay-seconds form only (what the Go server sends); HTTP-date values are ignored.
  static Duration? _parseRetryAfter(String? value) {
    final seconds = int.tryParse(value?.trim() ?? '');
    return seconds == null || seconds < 0 ? null : Duration(seconds: seconds);
  }

  final int? statusCode;

  /// The server's `error` text when present; for display decisions use [statusCode] or [code].
  final String message;

  /// Machine-readable error code (e.g. `rider_paused`); null on older responses.
  final String? code;

  /// The full error body, for structured extras such as `paused_until` or `documents`.
  final Map<String, dynamic> body;

  /// The server's `Retry-After` (e.g. on a 429), when sent.
  final Duration? retryAfter;

  bool get isNetworkError => statusCode == null;
  bool get isUnauthorized => statusCode == 401;

  /// A lost race on an order action: re-read the server's state, never retry automatically.
  bool get isConflict => statusCode == 409;

  /// The order's status now, sent with a 409 when the server knows it.
  String? get currentStatus =>
      body['status'] is String ? body['status'] as String : null;
  bool get isEmailNotConfirmed =>
      statusCode == 403 &&
      (code == 'email_not_confirmed' || message == 'email_not_confirmed');

  @override
  String toString() => 'ApiException($statusCode, $code, $message)';
}
