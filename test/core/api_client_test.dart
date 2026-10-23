import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridelink/core/api/api_client.dart';
import 'package:ridelink/core/api/api_exception.dart';
import 'package:ridelink/core/auth/auth_api.dart';
import 'package:ridelink/core/auth/session.dart';
import 'package:ridelink/core/auth/session_manager.dart';
import 'package:ridelink/core/config/app_config.dart';
import 'package:ridelink/core/version/client_info.dart';

import '../support/fakes.dart';

void main() {
  final config = AppConfig(apiBaseUrl: Uri.parse('http://test.local:8080'));

  late FakeTokenStorage storage;

  ({ApiClient api, SessionManager session, FakeAdapter adapter}) build(
    FakeHandler handler,
  ) {
    final adapter = FakeAdapter(handler);
    storage = FakeTokenStorage();
    final session = SessionManager(
      storage: storage,
      authApi: AuthApi(config, adapter: adapter),
    );
    final api = ApiClient(config, tokens: session, adapter: adapter);
    return (api: api, session: session, adapter: adapter);
  }

  Future<void> signIn(
    SessionManager session, {
    String access = 'old',
    String refresh = 'r1',
  }) => session.setSession(
    Session.fromJson(sessionJson(access: access, refresh: refresh)),
  );

  test('attaches the bearer token and returns decoded JSON', () async {
    final t = build(
      (o) => jsonResponse(200, {'auth': o.headers['Authorization']}),
    );
    await signIn(t.session, access: 'tok');

    final data = await t.api.get('profile');

    expect(data, {'auth': 'Bearer tok'});
    expect(
      t.adapter.requests.single.uri.toString(),
      'http://test.local:8080/v1/profile',
    );
  });

  test(
    'concurrent 401s trigger exactly one refresh and both requests are retried',
    () async {
      final t = build((o) async {
        if (o.uri.path.endsWith('/v1/auth/refresh')) {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          return jsonResponse(200, sessionJson(access: 'new', refresh: 'r2'));
        }
        if (o.headers['Authorization'] == 'Bearer new') {
          return jsonResponse(200, {'path': o.uri.path});
        }
        return jsonResponse(401, {'error': 'invalid or expired token'});
      });
      await signIn(t.session);

      final results = await Future.wait([
        t.api.get('orders'),
        t.api.get('profile'),
      ]);

      expect(results, [
        {'path': '/v1/orders'},
        {'path': '/v1/profile'},
      ]);
      expect(t.adapter.countPath('/auth/refresh'), 1);
      expect(
        t.adapter.requests
            .firstWhere((r) => r.uri.path.endsWith('/auth/refresh'))
            .data,
        {'refresh_token': 'r1'},
      );
      expect(storage.refreshToken, 'r2');
      expect(t.session.accessToken, 'new');
    },
  );

  test(
    'refresh rejected with 401 signs out and surfaces the original 401',
    () async {
      final t = build((o) {
        if (o.uri.path.endsWith('/v1/auth/refresh')) {
          return jsonResponse(401, {
            'error': 'session expired, please sign in again',
          });
        }
        return jsonResponse(401, {'error': 'invalid or expired token'});
      });
      await signIn(t.session);

      await expectLater(
        t.api.get('orders'),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401),
        ),
      );
      expect(t.session.state, isA<SignedOut>());
      expect(storage.refreshToken, isNull);
    },
  );

  test('a retried request that is still 401 is not retried again', () async {
    final t = build((o) {
      if (o.uri.path.endsWith('/v1/auth/refresh')) {
        return jsonResponse(200, sessionJson(access: 'new', refresh: 'r2'));
      }
      return jsonResponse(401, {'error': 'invalid or expired token'});
    });
    await signIn(t.session);

    await expectLater(t.api.get('orders'), throwsA(isA<ApiException>()));
    expect(t.adapter.countPath('/auth/refresh'), 1);
    expect(t.adapter.countPath('/v1/orders'), 2);
  });

  test('401 from /v1/auth/* never triggers a refresh', () async {
    final t = build(
      (o) => jsonResponse(401, {'error': 'email or password is incorrect'}),
    );
    await signIn(t.session);

    await expectLater(
      t.api.post('auth/signin', data: {'email': 'a@b.c', 'password': 'x'}),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          'email or password is incorrect',
        ),
      ),
    );
    expect(t.adapter.countPath('/auth/refresh'), 0);
  });

  test('maps the server error body into ApiException', () async {
    final t = build(
      (o) => jsonResponse(422, {'error': 'order can no longer be edited'}),
    );
    await signIn(t.session);

    await expectLater(
      t.api.patch('orders/o1/route', data: const {}),
      throwsA(
        isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 422)
            .having(
              (e) => e.message,
              'message',
              'order can no longer be edited',
            ),
      ),
    );
  });

  test('unreachable server becomes a network ApiException', () async {
    final t = build((o) => throw const SocketException('connection refused'));
    await signIn(t.session);

    await expectLater(
      t.api.get('profile'),
      throwsA(
        isA<ApiException>().having(
          (e) => e.isNetworkError,
          'isNetworkError',
          true,
        ),
      ),
    );
  });

  test('DioException without response maps to a network error', () {
    final e = ApiException.fromDio(
      DioException(requestOptions: RequestOptions(path: '/x')),
    );
    expect(e.isNetworkError, isTrue);
  });

  group('client info headers', () {
    const info = ClientInfo(appVersion: '1.0.0+12', platform: 'android');

    test('every API request carries the app version and platform', () async {
      final adapter = FakeAdapter((o) => jsonResponse(200, {}));
      final session = SessionManager(
        storage: FakeTokenStorage(),
        authApi: AuthApi(config, adapter: adapter),
      );
      final api = ApiClient(
        config,
        tokens: session,
        clientInfo: info,
        adapter: adapter,
      );
      await signIn(session, access: 'tok');

      await api.get('profile');
      await api.post('orders', data: const {});
      await api.postMultipart(
        'orders/o1/evidence',
        fields: const {'kind': 'photo'},
        fileBytes: const [1, 2, 3],
        fileName: 'a.jpg',
      );

      expect(adapter.requests, hasLength(3));
      for (final r in adapter.requests) {
        expect(r.headers['X-App-Version'], '1.0.0+12');
        expect(r.headers['X-App-Platform'], 'android');
        expect(r.headers['Authorization'], 'Bearer tok');
      }
    });

    test('a request retried after a token refresh keeps the headers', () async {
      final adapter = FakeAdapter((o) {
        if (o.uri.path.endsWith('/v1/auth/refresh')) {
          return jsonResponse(200, sessionJson(access: 'new', refresh: 'r2'));
        }
        if (o.headers['Authorization'] == 'Bearer new') {
          return jsonResponse(200, {});
        }
        return jsonResponse(401, {'error': 'invalid or expired token'});
      });
      final session = SessionManager(
        storage: FakeTokenStorage(),
        authApi: AuthApi(config, adapter: adapter, clientInfo: info),
      );
      final api = ApiClient(
        config,
        tokens: session,
        clientInfo: info,
        adapter: adapter,
      );
      await signIn(session);

      await api.get('orders');

      expect(adapter.requests, hasLength(3));
      for (final r in adapter.requests) {
        expect(r.headers['X-App-Version'], '1.0.0+12');
        expect(r.headers['X-App-Platform'], 'android');
      }
    });

    test('auth endpoints carry the headers too', () async {
      final adapter = FakeAdapter(
        (o) => jsonResponse(200, sessionJson(access: 'a', refresh: 'r')),
      );
      final auth = AuthApi(config, adapter: adapter, clientInfo: info);

      await auth.signIn(email: 'a@b.c', password: 'x');
      await auth.logout('a');

      for (final r in adapter.requests) {
        expect(r.headers['X-App-Version'], '1.0.0+12');
        expect(r.headers['X-App-Platform'], 'android');
      }
      expect(adapter.requests.last.headers['Authorization'], 'Bearer a');
    });

    test('without client info no telemetry headers are sent', () async {
      final t = build((o) => jsonResponse(200, {}));
      await signIn(t.session);

      await t.api.get('profile');

      final headers = t.adapter.requests.single.headers;
      expect(headers.containsKey('X-App-Version'), isFalse);
      expect(headers.containsKey('X-App-Platform'), isFalse);
    });
  });

  group('ClientInfo', () {
    test('joins version and build number', () {
      final info = ClientInfo.from(
        version: '1.0.0',
        buildNumber: '12',
        platform: 'android',
      );
      expect(info.headers, {
        'X-App-Version': '1.0.0+12',
        'X-App-Platform': 'android',
      });
    });

    test('omits an empty build number', () {
      expect(
        ClientInfo.from(version: '1.0.0', buildNumber: ' ').appVersion,
        '1.0.0',
      );
    });

    test('platform name is lower case', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      expect(currentPlatformName(), 'ios');
      expect(
        ClientInfo.from(version: '1.0.0', buildNumber: '1').platform,
        'ios',
      );
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      expect(currentPlatformName(), 'android');
    });
  });
}
