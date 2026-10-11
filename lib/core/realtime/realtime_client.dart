import 'dart:async';
import 'dart:math';

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
      if (refreshFirst) {
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
      } catch (_) {
        // Handshake rejected (likely an expired token) or unreachable: refresh, then back off.
        refreshFirst = true;
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
        onError: (Object _) => closed.isCompleted ? null : closed.complete(),
        cancelOnError: true,
      );
      await closed.future;
      await sub.cancel();
      if (identical(_channel, channel)) _channel = null;
      if (!_isCurrent(generation)) return;
      await _delay(_backoff(attempt++));
    }
    if (generation == _generation) _running = false;
  }

  Duration _backoff(int attempt) {
    final ms = minBackoff.inMilliseconds * pow(2, min(attempt, 16));
    return Duration(milliseconds: min(ms.toInt(), maxBackoff.inMilliseconds));
  }
}
