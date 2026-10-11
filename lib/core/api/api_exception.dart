import 'package:dio/dio.dart';

/// A failed API call. [statusCode] is null when the server could not be reached.
class ApiException implements Exception {
  const ApiException({this.statusCode, required this.message});

  factory ApiException.fromDio(DioException e) {
    final response = e.response;
    if (response == null) {
      return ApiException(message: e.message ?? e.type.name);
    }
    final data = response.data;
    final serverMessage = data is Map && data['error'] is String
        ? data['error'] as String
        : null;
    return ApiException(
      statusCode: response.statusCode,
      message:
          serverMessage ??
          response.statusMessage ??
          'HTTP ${response.statusCode}',
    );
  }

  final int? statusCode;

  /// The server's `error` text when present; for display decisions use [statusCode].
  final String message;

  bool get isNetworkError => statusCode == null;
  bool get isUnauthorized => statusCode == 401;
  bool get isEmailNotConfirmed =>
      statusCode == 403 && message == 'email_not_confirmed';

  @override
  String toString() => 'ApiException($statusCode, $message)';
}
