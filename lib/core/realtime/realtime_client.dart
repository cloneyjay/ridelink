import 'dart:async';
import 'dart:io' show WebSocketException;
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../auth/access_token_source.dart';
import 'realtime_event.dart';

typedef WebSocketConnector = WebSocketChannel Function(
  Uri uri,
  Map<String, dynamic> headers,
);

/// Server-push connection to GET /v1/ws (mobile only: auth via the Authorization header).
class RealtimeClient {
  RealtimeClient({
    required this._uri,
    required this._tokens,
    WebSocketConnector? connect,
    Future<void> Function(Duration)? delay,
    this.minBackoff = const Duration(seconds: 1),
    this.maxBackoff = const Duration(seconds: 30),
  }) : _connect =
           connect ?? ((u, h) => IOWebSocketChannel.connect(u, headers: h)),
       _delay = delay ?? Future<void>.delayed;

  final Uri _uri;
  final AccessTokenSource _tokens;
  final WebSocketConnector _connect;
  final Future<void> Function(Duration) _delay;
  final Duration minBackoff;
  final Duration maxBackoff;

  final _events = StreamController<RealtimeEvent>.broadcast();
  WebSocketChannel? _channel;
  int _generation = 0;
  bool _running = false;

  Stream<RealtimeEvent> get events => _events.stream;
  bool get isRunning => _running;

  void start() {
    if (_running) return;
    _running = true;
    unawaited(_run(++_generation));
  }

  Future<void> stop() async {
    _running = false;
    _generation++;
    final channel = _channel;
    _channel = null;
    await channel?.sink.close();
  }

  Future<void> dispose() async {
    await stop();
    await _events.close();
  }

  bool _isCurrent(int generation) => _running && generation == _generation;

  Future<void> _run(int generation) async {
    var attempt = 0;
    var refreshFirst = false;
    while (_isCurrent(generation)) {
      // Only a rejected or expiring token warrants a refresh; other failures retry as is.
      if (refreshFirst || _tokens.accessTokenExpiresSoon) {
        refreshFirst = false;
        if (!await _tokens.refresh() && !_tokens.hasSession) break;
        if (!_isCurrent(generation)) return;
      }
      final token = _tokens.accessToken;
      if (token == null) break;

      final channel = _connect(_uri, {'Authorization': 'Bearer $token'});
      _channel = channel;
      try {
        await channel.ready;
      } catch (e) {
        final status = handshakeStatusCode(e);
        _debugLog(
          'handshake to $_uri failed: ${_describe(e)}'
          '${status == null ? '' : ' (HTTP $status)'}',
        );
        refreshFirst = status == 401;
        if (!_isCurrent(generation)) return;
        await _delay(_backoff(attempt++));
        continue;
      }

      final closed = Completer<void>();
      final sub = channel.stream.listen(
        (frame) {
          final event = RealtimeEvent.tryParse(frame);
          if (event == null) return;
          if (event.kind == RealtimeEventKind.connected) attempt = 0;
          if (!_events.isClosed) _events.add(event);
        },
        onDone: () => closed.isCompleted ? null : closed.complete(),
        onError: (Object e) {
          _debugLog('stream error: ${_describe(e)}');
          if (!closed.isCompleted) closed.complete();
        },
        cancelOnError: true,
      );
      await closed.future;
      await sub.cancel();
      _debugLog(
        'connection closed (code ${channel.closeCode}, reason ${channel.closeReason})',
      );
      if (identical(_channel, channel)) _channel = null;
      if (!_isCurrent(generation)) return;
      await _delay(_backoff(attempt++));
    }
    if (generation == _generation) _running = false;
  }

  /// The HTTP status of a rejected WebSocket upgrade, or null (unreachable, TLS, timeout...).
  static int? handshakeStatusCode(Object error) {
    final inner = error is WebSocketChannelException ? error.inner : error;
    return inner is WebSocketException ? inner.httpStatusCode : null;
  }

  static String _describe(Object error) {
    final inner = error is WebSocketChannelException ? error.inner : null;
    return inner == null
        ? '${error.runtimeType}: $error'
        : '${error.runtimeType} > ${inner.runtimeType}: $inner';
  }

  // Never log headers: they carry the bearer token.
  static void _debugLog(String message) {
    if (kDebugMode) debugPrint('realtime: $message');
  }

  Duration _backoff(int attempt) {
    final ms = minBackoff.inMilliseconds * pow(2, min(attempt, 16));
    return Duration(milliseconds: min(ms.toInt(), maxBackoff.inMilliseconds));
  }
}
