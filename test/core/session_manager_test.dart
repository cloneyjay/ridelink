import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ridelink/core/auth/auth_api.dart';
import 'package:ridelink/core/auth/session.dart';
import 'package:ridelink/core/auth/session_manager.dart';
import 'package:ridelink/core/config/app_config.dart';

import '../support/fakes.dart';

void main() {
  final config = AppConfig(apiBaseUrl: Uri.parse('http://test.local:8080'));

  ({SessionManager session, FakeAdapter adapter, FakeTokenStorage storage})
  build(FakeHandler handler, {String? storedRefresh}) {
    final adapter = FakeAdapter(handler);
    final storage = FakeTokenStorage(storedRefresh);
    return (
      session: SessionManager(
        storage: storage,
        authApi: AuthApi(config, adapter: adapter),
      ),
      adapter: adapter,
      storage: storage,
    );
  }

  test('starts unknown', () {
    final t = build((o) => jsonResponse(500, const {}));
    expect(t.session.state, isA<SessionUnknown>());
  });

  test('restore with a stored refresh token refreshes and signs in', () async {
    final t = build(
      (o) => jsonResponse(200, sessionJson(access: 'a2', refresh: 'r2')),
      storedRefresh: 'r1',
    );

    await t.session.restore();

    expect(t.session.state, isA<SignedIn>());
    expect(t.session.accessToken, 'a2');
    expect(t.storage.refreshToken, 'r2');
    expect(t.adapter.requests.single.data, {'refresh_token': 'r1'});
  });

  test(
    'restore without a stored token signs out without a network call',
    () async {
      final t = build((o) => jsonResponse(500, const {}));

      await t.session.restore();

      expect(t.session.state, isA<SignedOut>());
      expect(t.adapter.requests, isEmpty);
    },
  );

  test(
    'restore with a rejected refresh token signs out and clears storage',
    () async {
      final t = build(
        (o) => jsonResponse(401, {
          'error': 'session expired, please sign in again',
        }),
        storedRefresh: 'r1',
      );

      await t.session.restore();

      expect(t.session.state, isA<SignedOut>());
      expect(t.storage.refreshToken, isNull);
    },
  );

  test(
    'restore while offline goes offline and keeps the stored refresh token',
    () async {
      final t = build(
        (o) => throw const SocketException('offline'),
        storedRefresh: 'r1',
      );

      await t.session.restore();

      expect(t.session.state, isA<SessionOffline>());
      expect(t.session.accessToken, isNull);
      expect(t.storage.refreshToken, 'r1');
    },
  );

  test('retry after offline signs in once the server is reachable', () async {
    var online = false;
    final t = build((o) {
      if (!online) throw const SocketException('offline');
      return jsonResponse(200, sessionJson(access: 'a2', refresh: 'r2'));
    }, storedRefresh: 'r1');
    await t.session.restore();
    expect(t.session.state, isA<SessionOffline>());

    online = true;
    await t.session.retry();

    expect(t.session.state, isA<SignedIn>());
    expect(t.storage.refreshToken, 'r2');
  });

  test('retry still offline stays offline; a 401 on retry signs out', () async {
    var status = 0;
    final t = build((o) {
      if (status == 0) throw const SocketException('offline');
      return jsonResponse(401, {'error': 'session expired'});
    }, storedRefresh: 'r1');
    await t.session.restore();

    await t.session.retry();
    expect(t.session.state, isA<SessionOffline>());
    expect(t.storage.refreshToken, 'r1');

    status = 401;
    await t.session.retry();
    expect(t.session.state, isA<SignedOut>());
    expect(t.storage.refreshToken, isNull);
  });

  test('retry does nothing unless offline', () async {
    final t = build((o) => jsonResponse(500, const {}));
    await t.session.restore();
    await t.session.retry();
    expect(t.session.state, isA<SignedOut>());
    expect(t.adapter.requests, isEmpty);
  });

  test('setSession stores the refresh token and notifies listeners', () async {
    final t = build((o) => jsonResponse(500, const {}));
    var notified = 0;
    t.session.addListener(() => notified++);

    await t.session.setSession(Session.fromJson(sessionJson()));

    expect(t.session.state, isA<SignedIn>());
    expect(t.storage.refreshToken, 'refresh-1');
    expect(notified, 1);
  });

  test(
    'signOut calls logout with the access token, clears storage and signs out',
    () async {
      final t = build((o) => jsonResponse(204, const {}));
      await t.session.setSession(Session.fromJson(sessionJson(access: 'live')));

      await t.session.signOut();

      final logout = t.adapter.requests.single;
      expect(logout.uri.path, '/v1/auth/logout');
      expect(logout.headers['Authorization'], 'Bearer live');
      expect(t.session.state, isA<SignedOut>());
      expect(t.storage.refreshToken, isNull);
    },
  );

  test('signOut still signs out locally when logout fails', () async {
    final t = build((o) => throw const SocketException('offline'));
    await t.session.setSession(Session.fromJson(sessionJson()));

    await t.session.signOut();

    expect(t.session.state, isA<SignedOut>());
    expect(t.storage.refreshToken, isNull);
  });
}
