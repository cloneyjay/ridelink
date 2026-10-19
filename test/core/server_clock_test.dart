import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridelink/core/api/api_client.dart';
import 'package:ridelink/core/api/api_exception.dart';
import 'package:ridelink/core/auth/auth_api.dart';
import 'package:ridelink/core/auth/session_manager.dart';
import 'package:ridelink/core/config/app_config.dart';
import 'package:ridelink/core/time/server_clock.dart';

import '../support/fakes.dart';

void main() {
  final device = DateTime.utc(2026, 10, 13, 9, 42);

  group('parseHttpDate', () {
    test('parses an IMF-fixdate as UTC', () {
      expect(
        parseHttpDate('Tue, 13 Oct 2026 09:43:30 GMT'),
        DateTime.utc(2026, 10, 13, 9, 43, 30),
      );
    });

    test('absent, empty and garbage values are null', () {
      for (final v in [
        null,
        '',
        'yesterday',
        '2026-10-13T09:43:30Z',
        'Tue, 13 Oct 2026 09:43:30 EAT',
        'Tue, 13 Foo 2026 09:43:30 GMT',
        'Tue, 31 Feb 2026 09:43:30 GMT',
        'Tue, 13 Oct 2026 25:43:30 GMT',
      ]) {
        expect(parseHttpDate(v), isNull, reason: '$v');
      }
    });
  });

  group('ServerClock', () {
    test('no sample means no offset: server now is device now', () {
      final clock = ServerClock(deviceNow: () => device);
      expect(clock.hasSample, isFalse);
      expect(clock.now(), device);
    });

    test(
      'a valid Date header sets the offset (with the half-second midpoint)',
      () {
        final clock = ServerClock(deviceNow: () => device);
        clock.observe('Tue, 13 Oct 2026 09:43:30 GMT');
        expect(clock.offset, const Duration(seconds: 90, milliseconds: 500));
        expect(clock.now(), device.add(clock.offset));
      },
    );

    test('absent or invalid headers leave the offset untouched', () {
      final clock = ServerClock(deviceNow: () => device);
      clock.observe('Tue, 13 Oct 2026 09:43:30 GMT');
      final before = clock.offset;
      clock.observe(null);
      clock.observe('not a date');
      expect(clock.offset, before);
    });

    test('small changes are smoothed; a jump replaces the offset', () {
      final clock = ServerClock(deviceNow: () => device);
      clock.observeSample(device.add(const Duration(seconds: 10)), device);
      expect(clock.offset, const Duration(seconds: 10));
      clock.observeSample(device.add(const Duration(seconds: 14)), device);
      expect(clock.offset, const Duration(seconds: 11));
      clock.observeSample(device.subtract(const Duration(minutes: 5)), device);
      expect(clock.offset, const Duration(minutes: -5));
    });
  });

  group('ApiClient feeds the server clock', () {
    final config = AppConfig(apiBaseUrl: Uri.parse('http://test.local'));

    ApiClient build(ServerClock clock, int status, String? date) {
      final adapter = FakeAdapter(
        (_) => ResponseBody.fromString(
          jsonEncode(status < 400 ? {'ok': true} : {'error': 'x'}),
          status,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
            'date': ?(date == null ? null : [date]),
          },
        ),
      );
      final session = SessionManager(
        storage: FakeTokenStorage(),
        authApi: AuthApi(config, adapter: adapter),
      );
      return ApiClient(
        config,
        tokens: session,
        serverClock: clock,
        adapter: adapter,
      );
    }

    test('from a successful response', () async {
      final clock = ServerClock(deviceNow: () => device);
      await build(clock, 200, 'Tue, 13 Oct 2026 09:41:00 GMT').get('x');
      expect(clock.offset, const Duration(seconds: -59, milliseconds: -500));
    });

    test('from an error response too', () async {
      final clock = ServerClock(deviceNow: () => device);
      await expectLater(
        build(clock, 409, 'Tue, 13 Oct 2026 09:42:20 GMT').post('x'),
        throwsA(isA<ApiException>()),
      );
      expect(clock.offset, const Duration(seconds: 20, milliseconds: 500));
    });

    test('ignores an absent or garbage header', () async {
      final clock = ServerClock(deviceNow: () => device);
      await build(clock, 200, null).get('x');
      await build(clock, 200, 'garbage').get('x');
      expect(clock.hasSample, isFalse);
      expect(clock.offset, Duration.zero);
    });
  });
}
