import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridelink/core/auth/access_token_source.dart';
import 'package:ridelink/core/realtime/realtime_client.dart';
import 'package:ridelink/core/realtime/realtime_event.dart';
import 'package:ridelink/core/version/client_info.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class FakeTokens implements AccessTokenSource {
  @override
  String? accessToken = 't1';
  @override
  bool hasSession = true;
  @override
  bool accessTokenExpiresSoon = false;

  bool refreshSucceeds = true;
  bool signOutOnFailedRefresh = true;
  int refreshes = 0;

  @override
  Future<bool> refresh() async {
    refreshes++;
    if (refreshSucceeds) {
      accessToken = 't${refreshes + 1}';
      accessTokenExpiresSoon = false;
      return true;
    }
    if (signOutOnFailedRefresh) {
      hasSession = false;
      accessToken = null;
    }
    return false;
  }
}

class FakeSink implements WebSocketSink {
  FakeSink(this.channel);
  final FakeChannel channel;
  final _done = Completer<void>();

  @override
  void add(dynamic data) => channel.sent.add(data);
  @override
  void addError(Object error, [StackTrace? stackTrace]) {}
  @override
  Future addStream(Stream stream) => stream.forEach(add);
  @override
  Future close([int? closeCode, String? closeReason]) async {
    channel.closed = true;
    if (!channel.incoming.isClosed) await channel.incoming.close();
    if (!_done.isCompleted) _done.complete();
  }

  @override
  Future get done => _done.future;
}

/// What IOWebSocketChannel reports when the server answers the upgrade with [status].
Object rejected(int status) => WebSocketChannelException.from(
  WebSocketException(
    "Connection to 'http://test.local:8080/v1/ws#' was not upgraded to websocket",
    status,
  ),
);

/// What IOWebSocketChannel reports when the server can't be reached.
Object unreachable() =>
    WebSocketChannelException.from(const SocketException('Connection refused'));

class FakeChannel with StreamChannelMixin implements WebSocketChannel {
  FakeChannel({bool failHandshake = false, Object? handshakeError})
    : handshakeError = handshakeError ?? (failHandshake ? rejected(401) : null);

  final Object? handshakeError;
  final incoming = StreamController<dynamic>();
  final sent = <dynamic>[];
  bool closed = false;

  @override
  Future<void> get ready =>
      handshakeError == null ? Future.value() : Future.error(handshakeError!);
  @override
  Stream get stream => incoming.stream;
  @override
  late final WebSocketSink sink = FakeSink(this);
  @override
  String? get protocol => null;
  @override
  int? get closeCode => null;
  @override
  String? get closeReason => null;

  void emit(String type, [Map<String, dynamic> data = const {}]) =>
      incoming.add(jsonEncode({'type': type, 'data': data}));
}

void main() {
  final uri = Uri.parse('ws://test.local:8080/v1/ws');

  group('RealtimeEvent.tryParse', () {
    test('maps known types and keeps data', () {
      final e = RealtimeEvent.tryParse(
        '{"type":"order.updated","data":{"order_id":"o1","status":"accepted"}}',
      )!;
      expect(e.kind, RealtimeEventKind.orderUpdated);
      expect(e.type, 'order.updated');
      expect(e.data, {'order_id': 'o1', 'status': 'accepted'});
    });

    test('maps every documented type', () {
      const expected = {
        'connected': RealtimeEventKind.connected,
        'order.updated': RealtimeEventKind.orderUpdated,
        'offer.received': RealtimeEventKind.offerReceived,
        'offer.resolved': RealtimeEventKind.offerResolved,
        'notification.created': RealtimeEventKind.notificationCreated,
        'rider.location': RealtimeEventKind.riderLocation,
      };
      expected.forEach(
        (type, kind) =>
            expect(RealtimeEvent.tryParse('{"type":"$type"}')!.kind, kind),
      );
    });

    test('passes unknown types through as generic events', () {
      final e = RealtimeEvent.tryParse(
        '{"type":"pickup.arrived","data":{"order_id":"o1"}}',
      )!;
      expect(e.kind, RealtimeEventKind.unknown);
      expect(e.type, 'pickup.arrived');
      expect(e.data['order_id'], 'o1');
    });

    test('ignores malformed frames', () {
      expect(RealtimeEvent.tryParse('not json'), isNull);
      expect(RealtimeEvent.tryParse('{"data":{}}'), isNull);
      expect(RealtimeEvent.tryParse('[1,2]'), isNull);
    });
  });

  group('RealtimeClient', () {
    test('connects with the bearer token and emits parsed events', () async {
      final tokens = FakeTokens();
      final channel = FakeChannel();
      Uri? connectedUri;
      Map<String, dynamic>? headers;
      final client = RealtimeClient(
        uri: uri,
        tokens: tokens,
        connect: (u, h) {
          connectedUri = u;
          headers = h;
          return channel;
        },
        delay: (_) async {},
      );

      final events = <RealtimeEvent>[];
      final sub = client.events.listen(events.add);
      client.start();
      await pumpEventQueue();
      channel.emit('connected');
      channel.emit('offer.received', {'offer_id': 'of1'});
      await pumpEventQueue();

      expect(connectedUri, uri);
      expect(headers, {'Authorization': 'Bearer t1'});
      expect(events.map((e) => e.kind), [
        RealtimeEventKind.connected,
        RealtimeEventKind.offerReceived,
      ]);
      expect(channel.sent, isEmpty, reason: 'client never sends data frames');

      await client.stop();
      await sub.cancel();
      expect(channel.closed, isTrue);
    });

    test('reconnects with exponential backoff capped at 30 s', () async {
      final tokens = FakeTokens();
      final delays = <Duration>[];
      late RealtimeClient client;
      client = RealtimeClient(
        uri: uri,
        tokens: tokens,
        connect: (_, _) {
          final c = FakeChannel();
          c.incoming.close();
          return c;
        },
        delay: (d) async {
          delays.add(d);
          if (delays.length == 7) await client.stop();
        },
      );

      client.start();
      await pumpEventQueue(times: 50);

      expect(delays.map((d) => d.inSeconds), [1, 2, 4, 8, 16, 30, 30]);
    });

    test('a connected event resets the backoff', () async {
      final tokens = FakeTokens();
      final delays = <Duration>[];
      var attempt = 0;
      late RealtimeClient client;
      client = RealtimeClient(
        uri: uri,
        tokens: tokens,
        connect: (_, _) {
          attempt++;
          final c = FakeChannel();
          if (attempt == 3) c.emit('connected');
          c.incoming.close();
          return c;
        },
        delay: (d) async {
          delays.add(d);
          if (delays.length == 3) await client.stop();
        },
      );

      client.start();
      await pumpEventQueue(times: 50);

      expect(delays.map((d) => d.inSeconds), [1, 2, 1]);
    });

    test(
      'a handshake rejected with 401 refreshes the token before reconnecting',
      () async {
        final tokens = FakeTokens();
        final usedHeaders = <String>[];
        var attempt = 0;
        late RealtimeClient client;
        client = RealtimeClient(
          uri: uri,
          tokens: tokens,
          connect: (_, h) {
            attempt++;
            usedHeaders.add(h['Authorization'] as String);
            return FakeChannel(failHandshake: attempt == 1);
          },
          delay: (_) async {},
        );

        client.start();
        await pumpEventQueue(times: 50);

        expect(tokens.refreshes, 1);
        expect(usedHeaders.take(2), ['Bearer t1', 'Bearer t2']);
        await client.stop();
      },
    );

    test('stops reconnecting when the refresh signs the user out', () async {
      final tokens = FakeTokens()..refreshSucceeds = false;
      var connects = 0;
      final client = RealtimeClient(
        uri: uri,
        tokens: tokens,
        connect: (_, _) {
          connects++;
          return FakeChannel(failHandshake: true);
        },
        delay: (_) async {},
      );

      client.start();
      await pumpEventQueue(times: 50);

      expect(connects, 1);
      expect(client.isRunning, isFalse);
    });

    test(
      'keeps retrying when the refresh fails but the session remains (offline)',
      () async {
        final tokens = FakeTokens()
          ..refreshSucceeds = false
          ..signOutOnFailedRefresh = false;
        var connects = 0;
        late RealtimeClient client;
        client = RealtimeClient(
          uri: uri,
          tokens: tokens,
          connect: (_, _) {
            connects++;
            return FakeChannel(failHandshake: true);
          },
          delay: (_) async {
            if (connects == 3) await client.stop();
          },
        );

        client.start();
        await pumpEventQueue(times: 50);

        expect(connects, 3);
      },
    );

    for (final (name, error) in [
      ('HTTP 500', rejected(500)),
      ('HTTP 502', rejected(502)),
      ('HTTP 429', rejected(429)),
      ('unreachable', unreachable()),
      ('a timeout', TimeoutException('connect')),
    ]) {
      test(
        'a handshake failing with $name retries with the same token',
        () async {
          final tokens = FakeTokens();
          final usedHeaders = <String>[];
          final delays = <Duration>[];
          late RealtimeClient client;
          client = RealtimeClient(
            uri: uri,
            tokens: tokens,
            connect: (_, h) {
              usedHeaders.add(h['Authorization'] as String);
              return FakeChannel(handshakeError: error);
            },
            delay: (d) async {
              delays.add(d);
              if (delays.length == 3) await client.stop();
            },
          );

          client.start();
          await pumpEventQueue(times: 50);

          expect(tokens.refreshes, 0);
          expect(usedHeaders, ['Bearer t1', 'Bearer t1', 'Bearer t1']);
          expect(delays.map((d) => d.inSeconds), [1, 2, 4]);
        },
      );
    }

    test(
      'refreshes before connecting when the token is about to expire',
      () async {
        final tokens = FakeTokens()..accessTokenExpiresSoon = true;
        final usedHeaders = <String>[];
        final client = RealtimeClient(
          uri: uri,
          tokens: tokens,
          connect: (_, h) {
            usedHeaders.add(h['Authorization'] as String);
            return FakeChannel();
          },
          delay: (_) async {},
        );

        client.start();
        await pumpEventQueue();

        expect(tokens.refreshes, 1);
        expect(usedHeaders, ['Bearer t2']);
        await client.stop();
      },
    );

    test(
      'after a non-401 failure, refreshes only once the token nears expiry',
      () async {
        final tokens = FakeTokens();
        final usedHeaders = <String>[];
        late RealtimeClient client;
        client = RealtimeClient(
          uri: uri,
          tokens: tokens,
          connect: (_, h) {
            usedHeaders.add(h['Authorization'] as String);
            return FakeChannel(
              handshakeError: usedHeaders.length < 3 ? unreachable() : null,
            );
          },
          delay: (_) async {
            if (usedHeaders.length == 2) tokens.accessTokenExpiresSoon = true;
          },
        );

        client.start();
        await pumpEventQueue(times: 50);

        expect(tokens.refreshes, 1);
        expect(usedHeaders, ['Bearer t1', 'Bearer t1', 'Bearer t2']);
        await client.stop();
      },
    );

    test('logs the handshake failure and status without the token', () async {
      final logs = <String>[];
      final original = debugPrint;
      debugPrint = (String? m, {int? wrapWidth}) => logs.add(m ?? '');
      addTearDown(() => debugPrint = original);
      final tokens = FakeTokens()..accessToken = 'secret-token';
      late RealtimeClient client;
      client = RealtimeClient(
        uri: uri,
        tokens: tokens,
        connect: (_, _) => FakeChannel(handshakeError: rejected(403)),
        delay: (_) async => client.stop(),
      );

      client.start();
      await pumpEventQueue(times: 20);

      final line = logs.singleWhere((l) => l.contains('handshake'));
      expect(line, contains('WebSocketException'));
      expect(line, contains('HTTP 403'));
      expect(line, contains('ws://test.local:8080/v1/ws'));
      expect(logs.join(' '), isNot(contains('secret-token')));
    });

    test('handshakeStatusCode reads the upgrade status only', () {
      expect(RealtimeClient.handshakeStatusCode(rejected(401)), 401);
      expect(RealtimeClient.handshakeStatusCode(unreachable()), isNull);
      expect(
        RealtimeClient.handshakeStatusCode(TimeoutException('connect')),
        isNull,
      );
    });

    test('does not connect without an access token', () async {
      final tokens = FakeTokens()
        ..accessToken = null
        ..hasSession = false;
      var connects = 0;
      final client = RealtimeClient(
        uri: uri,
        tokens: tokens,
        connect: (_, _) {
          connects++;
          return FakeChannel();
        },
        delay: (_) async {},
      );

      client.start();
      await pumpEventQueue();

      expect(connects, 0);
      expect(client.isRunning, isFalse);
    });

    test('sends the app version and platform with the handshake', () async {
      final channel = FakeChannel();
      Map<String, dynamic>? headers;
      final client = RealtimeClient(
        uri: uri,
        tokens: FakeTokens(),
        clientInfo: const ClientInfo(
          appVersion: '1.0.0+12',
          platform: 'android',
        ),
        connect: (_, h) {
          headers = h;
          return channel;
        },
        delay: (_) async {},
      );

      client.start();
      await pumpEventQueue();

      expect(headers, {
        'X-App-Version': '1.0.0+12',
        'X-App-Platform': 'android',
        'Authorization': 'Bearer t1',
      });
      await client.stop();
    });
  });
}
