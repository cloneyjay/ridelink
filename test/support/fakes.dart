import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:ridelink/core/auth/token_storage.dart';

class FakeTokenStorage implements TokenStorage {
  FakeTokenStorage([this.refreshToken]);

  String? refreshToken;
  int clears = 0;

  @override
  Future<String?> readRefreshToken() async => refreshToken;

  @override
  Future<void> writeRefreshToken(String token) async => refreshToken = token;

  @override
  Future<void> clear() async {
    clears++;
    refreshToken = null;
  }
}

typedef FakeHandler = FutureOr<ResponseBody> Function(RequestOptions options);

/// Routes every dio request to [handler] and records it.
class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.handler);

  final FakeHandler handler;
  final requests = <RequestOptions>[];

  int countPath(String fragment) =>
      requests.where((r) => r.uri.path.contains(fragment)).length;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

/// Dispatches by path under /v1 (e.g. 'auth/signin'); unknown paths get 404.
FakeHandler routeHandler(Map<String, FakeHandler> routes) => (o) {
  final handler = routes[o.uri.path.replaceFirst('/v1/', '')];
  return handler == null
      ? jsonResponse(404, {'error': 'not found'})
      : handler(o);
};

ResponseBody emptyResponse(int status) => ResponseBody.fromString('', status);

ResponseBody jsonResponse(int status, Object body) => ResponseBody.fromString(
  jsonEncode(body),
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

Map<String, dynamic> sessionJson({
  String access = 'access-1',
  String refresh = 'refresh-1',
}) => {
  'access_token': access,
  'refresh_token': refresh,
  'expires_in': 3600,
  'expires_at': 1900000000,
  'token_type': 'bearer',
  'user': {'id': 'user-1', 'email': 'moses@example.com'},
};

/// A Timer that never fires: for widget tests that don't exercise the session's refresh schedule
/// (a real hour-long timer would outlive the test).
class InertTimer implements Timer {
  InertTimer(Duration delay, void Function() callback);

  bool _cancelled = false;

  @override
  void cancel() => _cancelled = true;

  @override
  bool get isActive => !_cancelled;

  @override
  int get tick => 0;
}
