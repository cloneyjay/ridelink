import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridelink/core/api/api_exception.dart';
import 'package:ridelink/core/auth/auth_api.dart';
import 'package:ridelink/core/auth/session.dart';
import 'package:ridelink/core/auth/session_manager.dart';
import 'package:ridelink/core/config/app_config.dart';
import 'package:ridelink/core/time/server_clock.dart';

import '../support/fakes.dart';

class FakeTimer implements Timer {
  FakeTimer(this.delay, this.callback);

  final Duration delay;
  final void Function() callback;
  bool cancelled = false;
  bool fired = false;

  void fire() {
    fired = true;
    callback();
  }

  @override
  void cancel() => cancelled = true;

  @override
  bool get isActive => !cancelled && !fired;

  @override
  int get tick => fired ? 1 : 0;
}

class FakeTimers {
  final all = <FakeTimer>[];

  Timer start(Duration delay, void Function() callback) {
    final t = FakeTimer(delay, callback);
    all.add(t);
    return t;
  }

  List<FakeTimer> get active => all.where((t) => t.isActive).toList();

  FakeTimer get single => active.single;
}

ResponseBody errorResponse(
  int status, {
  String? code,
  Map<String, List<String>> headers = const {},
}) => ResponseBody.fromString(
  jsonEncode({'error': 'x', 'code': ?code}),
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
    ...headers,
  },
);

void main() {
  final config = AppConfig(apiBaseUrl: Uri.parse('http://test.local:8080'));
  final t0 = DateTime.utc(2026, 10, 20, 12);
  int unix(DateTime d) => d.millisecondsSinceEpoch ~/ 1000;

  Map<String, dynamic> sessionAt(
    DateTime expiresAt, {
    String access = 'a1',
    String refresh = 'r1',
    int expiresIn = 3600,
  }) => {
    ...sessionJson(access: access, refresh: refresh),
    'expires_at': unix(expiresAt),
    'expires_in': expiresIn,
  };

  late DateTime deviceNow;
  late ServerClock clock;
  late FakeTimers timers;

  setUp(() {
    deviceNow = t0;
    clock = ServerClock(deviceNow: () => deviceNow);
    timers = FakeTimers();
  });

  ({SessionManager session, FakeAdapter adapter, FakeTokenStorage storage})
  build(FakeHandler handler, {String? storedRefresh}) {
    final adapter = FakeAdapter(handler);
    final storage = FakeTokenStorage(storedRefresh);
    final session = SessionManager(
      storage: storage,
      authApi: AuthApi(config, adapter: adapter),
      clock: clock,
      timer: timers.start,
    );
    addTearDown(session.dispose);
    return (session: session, adapter: adapter, storage: storage);
  }

  group('refresh outcome', () {
    test('a 401 session_expired signs out and clears storage', () async {
      final t = build((_) => errorResponse(401, code: 'session_expired'));
      await t.session.setSession(Session.fromJson(sessionJson()));

      expect(await t.session.refresh(), isFalse);

      expect(t.session.state, isA<SignedOut>());
      expect(t.storage.refreshToken, isNull);
      expect(timers.active, isEmpty);
    });

    test('a 400 missing_fields signs out', () async {
      final t = build((_) => errorResponse(400, code: 'missing_fields'));
      await t.session.setSession(Session.fromJson(sessionJson()));

      expect(await t.session.refresh(), isFalse);

      expect(t.session.state, isA<SignedOut>());
      expect(t.storage.refreshToken, isNull);
    });

    for (final (name, handler) in <(String, FakeHandler)>[
      ('429', (_) => errorResponse(429, code: 'rate_limited')),
      ('500', (_) => errorResponse(500)),
      ('502', (_) => errorResponse(502)),
      ('400 with another code', (_) => errorResponse(400, code: 'bad_json')),
      ('a network error', (_) => throw const SocketException('offline')),
      (
        'a timeout',
        (o) => throw DioException.connectionTimeout(
          timeout: const Duration(seconds: 1),
          requestOptions: o,
        ),
      ),
    ]) {
      test('$name keeps the session and the stored refresh token', () async {
        final t = build(handler);
        await t.session.setSession(
          Session.fromJson(sessionJson(access: 'a1', refresh: 'refresh-1')),
        );

        expect(await t.session.refresh(), isFalse);

        expect(t.session.state, isA<SignedIn>());
        expect(t.session.accessToken, 'a1');
        expect(t.storage.refreshToken, 'refresh-1');
        expect(t.storage.clears, 0);
      });
    }

    test('a transient failure retries with exponential backoff', () async {
      var fail = true;
      final t = build(
        (_) => fail
            ? errorResponse(500)
            : jsonResponse(200, sessionAt(t0.add(const Duration(hours: 1)))),
      );
      await t.session.setSession(Session.fromJson(sessionJson()));

      await t.session.refresh();
      expect(timers.single.delay, const Duration(seconds: 2));
      timers.single.fire();
      await pumpEventQueue();
      expect(timers.single.delay, const Duration(seconds: 4));
      timers.single.fire();
      await pumpEventQueue();
      expect(timers.single.delay, const Duration(seconds: 8));
      expect(t.adapter.countPath('auth/refresh'), 3);

      fail = false;
      timers.single.fire();
      await pumpEventQueue();
      expect(t.session.accessToken, 'a1');
      expect(
        timers.single.delay,
        const Duration(minutes: 59),
        reason: 'success returns to the proactive schedule',
      );
    });

    test('the retry backoff is capped', () async {
      final t = build((_) => errorResponse(502));
      await t.session.setSession(Session.fromJson(sessionJson()));

      await t.session.refresh();
      for (var i = 0; i < 10; i++) {
        timers.single.fire();
        await pumpEventQueue();
      }

      expect(timers.single.delay, SessionManager.maxRetryDelay);
      expect(t.session.state, isA<SignedIn>());
    });

    test('a 429 waits at least Retry-After', () async {
      final t = build(
        (_) => errorResponse(
          429,
          code: 'rate_limited',
          headers: {
            'retry-after': ['17'],
          },
        ),
      );
      await t.session.setSession(Session.fromJson(sessionJson()));

      await t.session.refresh();

      expect(timers.single.delay, const Duration(seconds: 17));
    });

    test('concurrent refreshes share one request', () async {
      final gate = Completer<void>();
      final t = build((_) async {
        await gate.future;
        return jsonResponse(200, sessionJson(access: 'a2', refresh: 'r2'));
      });
      await t.session.setSession(Session.fromJson(sessionJson()));

      final a = t.session.refresh();
      final b = t.session.refresh();
      gate.complete();

      expect(await a, isTrue);
      expect(await b, isTrue);
      expect(t.adapter.countPath('auth/refresh'), 1);
    });
  });

  group('restore', () {
    for (final (name, handler) in <(String, FakeHandler)>[
      ('429', (_) => errorResponse(429, code: 'rate_limited')),
      ('500', (_) => errorResponse(500)),
      ('502', (_) => errorResponse(502)),
      ('a network error', (_) => throw const SocketException('offline')),
    ]) {
      test('$name goes offline and keeps the stored refresh token', () async {
        final t = build(handler, storedRefresh: 'r1');

        await t.session.restore();

        expect(t.session.state, isA<SessionOffline>());
        expect(t.storage.refreshToken, 'r1');
        expect(t.storage.clears, 0);
      });
    }

    test('401 session_expired signs out', () async {
      final t = build(
        (_) => errorResponse(401, code: 'session_expired'),
        storedRefresh: 'r1',
      );

      await t.session.restore();

      expect(t.session.state, isA<SignedOut>());
      expect(t.storage.refreshToken, isNull);
    });

    test('400 missing_fields signs out', () async {
      final t = build(
        (_) => errorResponse(400, code: 'missing_fields'),
        storedRefresh: 'r1',
      );

      await t.session.restore();

      expect(t.session.state, isA<SignedOut>());
    });
  });

  group('proactive refresh', () {
    test('is scheduled 60 s before the access token expires', () async {
      final t = build((_) => errorResponse(500));

      await t.session.setSession(
        Session.fromJson(sessionAt(t0.add(const Duration(hours: 1)))),
      );

      expect(timers.single.delay, const Duration(minutes: 59));
      expect(t.adapter.requests, isEmpty);
    });

    test('fires one refresh and reschedules from the new token', () async {
      final t = build(
        (_) => jsonResponse(
          200,
          sessionAt(
            t0.add(const Duration(hours: 2)),
            access: 'a2',
            refresh: 'r2',
          ),
        ),
      );
      await t.session.setSession(
        Session.fromJson(sessionAt(t0.add(const Duration(hours: 1)))),
      );

      deviceNow = t0.add(const Duration(minutes: 59));
      timers.single.fire();
      await pumpEventQueue();

      expect(t.adapter.countPath('auth/refresh'), 1);
      expect(t.adapter.requests.single.data, {'refresh_token': 'r1'});
      expect(t.session.accessToken, 'a2');
      expect(t.storage.refreshToken, 'r2');
      expect(timers.single.delay, const Duration(minutes: 60));
      expect(timers.all.where((x) => x.isActive), hasLength(1));
    });

    test('uses the server clock offset', () async {
      // The server is 10 minutes ahead of the phone.
      clock.observeSample(t0.add(const Duration(minutes: 10)), t0);
      final t = build((_) => errorResponse(500));

      await t.session.setSession(
        Session.fromJson(sessionAt(t0.add(const Duration(hours: 1)))),
      );

      expect(timers.single.delay, const Duration(minutes: 49));
    });

    test(
      'refreshes immediately when restored with an expiring token',
      () async {
        final t = build((_) => errorResponse(500));
        // Phone clock already past expiry, and the server agrees (no lifetime to fall back on).
        await t.session.setSession(
          Session.fromJson(
            sessionAt(t0.add(const Duration(seconds: 30)), expiresIn: 0),
          ),
        );

        expect(timers.single.delay, Duration.zero);
        expect(t.session.accessTokenExpiresSoon, isTrue);
      },
    );

    test('falls back to expires_in when the clock makes a fresh token look expired', () async {
      final t = build((_) => errorResponse(500));

      await t.session.setSession(
        Session.fromJson(
          sessionAt(t0.subtract(const Duration(hours: 2)), expiresIn: 3600),
        ),
      );

      expect(timers.single.delay, const Duration(minutes: 59));
      expect(t.session.accessTokenExpiresSoon, isFalse);
    });

    test('sign out cancels the timer', () async {
      final t = build((_) => emptyResponse(204));
      await t.session.setSession(
        Session.fromJson(sessionAt(t0.add(const Duration(hours: 1)))),
      );

      await t.session.signOut();

      expect(timers.active, isEmpty);
    });

    test('dispose cancels the timer', () async {
      final adapter = FakeAdapter((_) => errorResponse(500));
      final session = SessionManager(
        storage: FakeTokenStorage(),
        authApi: AuthApi(config, adapter: adapter),
        clock: clock,
        timer: timers.start,
      );
      await session.setSession(
        Session.fromJson(sessionAt(t0.add(const Duration(hours: 1)))),
      );

      session.dispose();

      expect(timers.active, isEmpty);
    });
  });

  group('accessTokenExpiresSoon', () {
    test('turns true within 60 s of expiry', () async {
      final t = build((_) => errorResponse(500));
      await t.session.setSession(
        Session.fromJson(sessionAt(t0.add(const Duration(hours: 1)))),
      );

      deviceNow = t0.add(const Duration(minutes: 58, seconds: 59));
      expect(t.session.accessTokenExpiresSoon, isFalse);
      deviceNow = t0.add(const Duration(minutes: 59));
      expect(t.session.accessTokenExpiresSoon, isTrue);
    });

    test('is false when signed out', () {
      final t = build((_) => errorResponse(500));
      expect(t.session.accessTokenExpiresSoon, isFalse);
    });
  });

  group('foreground check', () {
    test('refreshes when the token expired while in the background', () async {
      final t = build(
        (_) => jsonResponse(
          200,
          sessionAt(t0.add(const Duration(hours: 3)), access: 'a2'),
        ),
      );
      await t.session.setSession(
        Session.fromJson(sessionAt(t0.add(const Duration(hours: 1)))),
      );

      deviceNow = t0.add(const Duration(hours: 2));
      await t.session.ensureFresh();

      expect(t.adapter.countPath('auth/refresh'), 1);
      expect(t.session.accessToken, 'a2');
    });

    test('refreshes within 60 s of expiry', () async {
      final t = build(
        (_) => jsonResponse(
          200,
          sessionAt(t0.add(const Duration(hours: 2)), access: 'a2'),
        ),
      );
      await t.session.setSession(
        Session.fromJson(sessionAt(t0.add(const Duration(hours: 1)))),
      );

      deviceNow = t0.add(const Duration(minutes: 59, seconds: 30));
      await t.session.ensureFresh();

      expect(t.adapter.countPath('auth/refresh'), 1);
    });

    test('does not refresh a fresh token, but re-arms the timer', () async {
      final t = build((_) => errorResponse(500));
      await t.session.setSession(
        Session.fromJson(sessionAt(t0.add(const Duration(hours: 1)))),
      );

      deviceNow = t0.add(const Duration(minutes: 30));
      await t.session.ensureFresh();

      expect(t.adapter.requests, isEmpty);
      expect(timers.single.delay, const Duration(minutes: 29));
    });

    test('does nothing when signed out', () async {
      final t = build((_) => errorResponse(500));
      await t.session.restore();

      await t.session.ensureFresh();

      expect(t.adapter.requests, isEmpty);
      expect(timers.all, isEmpty);
    });
  });

  group('offline recovery', () {
    test('retries the restore on a backoff timer until it signs in', () async {
      var online = false;
      final t = build((_) {
        if (!online) throw const SocketException('offline');
        return jsonResponse(200, sessionAt(t0.add(const Duration(hours: 1))));
      }, storedRefresh: 'r1');

      await t.session.restore();
      expect(t.session.state, isA<SessionOffline>());
      expect(timers.single.delay, const Duration(seconds: 2));

      timers.single.fire();
      await pumpEventQueue();
      expect(t.session.state, isA<SessionOffline>());
      expect(timers.single.delay, const Duration(seconds: 4));

      online = true;
      timers.single.fire();
      await pumpEventQueue();
      expect(t.session.state, isA<SignedIn>());
      expect(t.storage.refreshToken, 'r1');
      expect(
        timers.single.delay,
        const Duration(minutes: 59),
        reason: 'the offline retry is replaced by the proactive refresh',
      );
      expect(t.adapter.countPath('auth/refresh'), 3);
    });

    test('the offline backoff is capped and respects Retry-After', () async {
      var retryAfter = false;
      final t = build(
        (_) => errorResponse(
          retryAfter ? 429 : 500,
          headers: retryAfter
              ? {
                  'retry-after': ['600'],
                }
              : const {},
        ),
        storedRefresh: 'r1',
      );

      await t.session.restore();
      for (var i = 0; i < 10; i++) {
        timers.single.fire();
        await pumpEventQueue();
      }
      expect(timers.single.delay, SessionManager.maxRetryDelay);

      retryAfter = true;
      timers.single.fire();
      await pumpEventQueue();
      expect(timers.single.delay, const Duration(minutes: 10));
      expect(t.session.state, isA<SessionOffline>());
      expect(t.storage.refreshToken, 'r1');
    });

    test(
      'a 401 during an offline retry signs out and stops retrying',
      () async {
        var status = 0;
        final t = build((_) {
          if (status == 0) throw const SocketException('offline');
          return errorResponse(401, code: 'session_expired');
        }, storedRefresh: 'r1');
        await t.session.restore();

        status = 401;
        timers.single.fire();
        await pumpEventQueue();

        expect(t.session.state, isA<SignedOut>());
        expect(t.storage.refreshToken, isNull);
        expect(timers.active, isEmpty);
      },
    );

    test('resume retries immediately while offline', () async {
      var online = false;
      final t = build((_) {
        if (!online) throw const SocketException('offline');
        return jsonResponse(200, sessionAt(t0.add(const Duration(hours: 1))));
      }, storedRefresh: 'r1');
      await t.session.restore();

      online = true;
      await t.session.ensureFresh();

      expect(t.session.state, isA<SignedIn>());
      expect(t.adapter.countPath('auth/refresh'), 2);
    });

    test('resume and the timer together send one request', () async {
      final gate = Completer<void>();
      var calls = 0;
      final t = build((_) async {
        calls++;
        if (calls == 1) throw const SocketException('offline');
        await gate.future;
        return jsonResponse(200, sessionAt(t0.add(const Duration(hours: 1))));
      }, storedRefresh: 'r1');
      await t.session.restore();

      final resumed = t.session.ensureFresh();
      final pressed = t.session.retry();
      await pumpEventQueue();
      gate.complete();
      await Future.wait([resumed, pressed]);

      expect(calls, 2);
      expect(t.session.state, isA<SignedIn>());
    });

    test('the Retry button still works and resets the timer', () async {
      var online = false;
      final t = build((_) {
        if (!online) throw const SocketException('offline');
        return jsonResponse(200, sessionAt(t0.add(const Duration(hours: 1))));
      }, storedRefresh: 'r1');
      await t.session.restore();
      final offlineTimer = timers.single;

      online = true;
      await t.session.retry();

      expect(offlineTimer.cancelled, isTrue);
      expect(t.session.state, isA<SignedIn>());
    });

    test('dispose cancels the offline timer', () async {
      final adapter = FakeAdapter((_) => throw const SocketException('x'));
      final session = SessionManager(
        storage: FakeTokenStorage('r1'),
        authApi: AuthApi(config, adapter: adapter),
        clock: clock,
        timer: timers.start,
      );
      await session.restore();
      expect(timers.active, hasLength(1));

      session.dispose();

      expect(timers.active, isEmpty);
    });
  });

  test('ApiException reads Retry-After seconds', () {
    final e = ApiException.fromDio(
      DioException(
        requestOptions: RequestOptions(),
        response: Response(
          requestOptions: RequestOptions(),
          statusCode: 429,
          headers: Headers.fromMap({
            'retry-after': ['30'],
          }),
        ),
      ),
    );
    expect(e.retryAfter, const Duration(seconds: 30));
  });
}
