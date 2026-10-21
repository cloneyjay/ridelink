import 'dart:async';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridelink/core/api/api_client.dart';
import 'package:ridelink/core/auth/access_token_source.dart';
import 'package:ridelink/core/auth/auth_api.dart';
import 'package:ridelink/core/auth/session.dart';
import 'package:ridelink/core/auth/session_manager.dart';
import 'package:ridelink/core/config/app_config.dart';
import 'package:ridelink/core/providers.dart';
import 'package:ridelink/core/push/device_registrar.dart';
import 'package:ridelink/core/push/local_notifier.dart';
import 'package:ridelink/core/push/push_locale.dart';
import 'package:ridelink/core/push/push_messaging.dart';
import 'package:ridelink/core/push/push_payload.dart';
import 'package:ridelink/core/push/push_providers.dart';
import 'package:ridelink/core/push/push_text.dart';
import 'package:ridelink/core/realtime/realtime_event.dart';
import 'package:ridelink/core/storage/local_store.dart';
import 'package:ridelink/core/version/version_gate.dart';
import 'package:ridelink/l10n/app_localizations.dart';

import '../support/beta_fakes.dart';
import '../support/fakes.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final sw = lookupAppLocalizations(const Locale('sw'));

  group('push payload', () {
    test('reads the data-only fields and ignores anything else', () {
      final p = PushPayload.fromData({
        'type': 'offer.received',
        'order_id': 'order-1',
        'notification_id': 'n-1',
        'amount': 350,
      })!;
      expect(p.type, 'offer.received');
      expect(p.orderId, 'order-1');
      expect(p.notificationId, 'n-1');
      expect(p.isOffer, isTrue);
      final back = PushPayload.decode(p.encode())!;
      expect(
        (back.type, back.orderId, back.notificationId),
        ('offer.received', 'order-1', 'n-1'),
      );
    });

    test('a message without a type is not a RideLink push', () {
      expect(PushPayload.fromData({'order_id': 'order-1'}), isNull);
      expect(PushPayload.fromData({'type': ''}), isNull);
      expect(PushPayload.decode('not json'), isNull);
      expect(PushPayload.decode(null), isNull);
    });
  });

  group('background message -> localized notification', () {
    Future<LocalPushNotification> show(
      Map<String, dynamic> data,
      AppLocalizations l,
    ) async {
      final notifier = FakeLocalNotifier();
      await showBackgroundPush(data, notifier, l);
      expect(notifier.initializations, 1);
      return notifier.shown.single;
    }

    test('offer.received uses the high-importance offers channel', () async {
      final n = await show({
        'type': 'offer.received',
        'order_id': 'order-1',
      }, en);
      expect(n.title, en.pushOfferTitle);
      expect(n.body, en.pushOfferBody);
      expect(n.channel, PushChannel.offers);
      expect(n.channelName, en.pushChannelOffersName);
      expect(PushPayload.decode(n.payload)!.orderId, 'order-1');
    });

    test('generic text per type on the default channel', () async {
      final cases = <String, ({String title, String body})>{
        'pickup_arrived': (
          title: en.notifPickupArrivedTitle,
          body: en.notifPickupArrivedBody,
        ),
        'payment_requested': (
          title: en.notifPaymentRequestedTitle,
          body: en.notifPaymentRequestedBodyNoAmount,
        ),
        'payment_sent': (
          title: en.notifPaymentSentTitle,
          body: en.notifPaymentSentBodyNoAmount,
        ),
        'payment_confirmed': (
          title: en.notifPaymentConfirmedTitle,
          body: en.notifPaymentConfirmedBodyNoAmount,
        ),
        'payment_unresolved': (
          title: en.notifPaymentUnresolvedTitle,
          body: en.notifPaymentUnresolvedBody,
        ),
        'pickup_timeout': (
          title: en.notifPickupTimeoutTitle,
          body: en.notifPickupTimeoutBody,
        ),
        'pickup_timeout_rider': (
          title: en.notifPickupTimeoutRiderTitle,
          body: en.notifPickupTimeoutRiderBody,
        ),
        'receiver_location_shared': (
          title: en.notifReceiverLocationTitle,
          body: en.notifReceiverLocationBody,
        ),
        'document_expiring': (
          title: en.pushDocumentTitle,
          body: en.pushDocumentBody,
        ),
        'document_expired': (
          title: en.pushDocumentTitle,
          body: en.pushDocumentBody,
        ),
        'order.updated': (title: en.pushGenericTitle, body: en.pushGenericBody),
        'something.new': (title: en.pushGenericTitle, body: en.pushGenericBody),
      };
      for (final MapEntry(key: type, value: text) in cases.entries) {
        final n = await show({'type': type, 'order_id': 'order-9'}, en);
        expect((n.title, n.body), (text.title, text.body), reason: type);
        expect(n.channel, PushChannel.updates, reason: type);
        expect(n.channelName, en.pushChannelUpdatesName);
      }
    });

    test('a push without a type shows nothing', () async {
      final notifier = FakeLocalNotifier();
      await showBackgroundPush({'order_id': 'x'}, notifier, en);
      expect(notifier.shown, isEmpty);
    });

    test('Swahili when the app last ran in Swahili', () async {
      final strings = localizationsFor(saved: 'sw', device: const Locale('en'));
      final n = await show({'type': 'offer.received'}, strings);
      expect(n.title, sw.pushOfferTitle);
      expect(n.body, sw.pushOfferBody);
      expect(n.title, isNot(en.pushOfferTitle));
    });

    test('locale falls back to the device language, then English', () async {
      expect(
        localizationsFor(device: const Locale('sw', 'KE')).localeName,
        'sw',
      );
      expect(localizationsFor(device: const Locale('fr')).localeName, 'en');
      expect(localizationsFor(saved: 'xx').localeName, 'en');
    });

    test('the resolved app language is saved for the background', () async {
      final store = MemoryLocalStore();
      await saveAppLocale(store, resolveAppLocale(const Locale('sw', 'KE')));
      expect(store.getString(localeStoreKey), 'sw');
      await saveAppLocale(store, resolveAppLocale(const Locale('de')));
      expect(store.getString(localeStoreKey), 'en');
    });
  });

  group('device registration', () {
    late FakeDeviceApi api;
    late FakePushMessaging push;
    late DeviceRegistrar registrar;

    setUp(() {
      api = FakeDeviceApi();
      push = FakePushMessaging();
      registrar = DeviceRegistrar(api: api, push: push, appVersion: '1.4.0');
    });
    tearDown(() async {
      await registrar.dispose();
      await push.close();
    });

    test('registers the token once per user and token', () async {
      await registrar.signedIn('user-1');
      await registrar.signedIn('user-1');
      expect(api.registered, [(token: 'fcm-1', appVersion: '1.4.0')]);
    });

    test('a refreshed token is registered again', () async {
      await registrar.signedIn('user-1');
      push.refreshes.add('fcm-2');
      await pumpEventQueue();
      expect(api.registered.map((r) => r.token), ['fcm-1', 'fcm-2']);
    });

    test(
      'a failed registration is retried on the next sign-in state',
      () async {
        api.registerError = offlineError;
        await registrar.signedIn('user-1');
        api.registerError = null;
        await registrar.signedIn('user-1');
        expect(api.registered, hasLength(2));
        await registrar.signedIn('user-1');
        expect(api.registered, hasLength(2));
      },
    );

    test('sign-out unregisters the token, best effort', () async {
      await registrar.signedIn('user-1');
      api.unregisterError = offlineError;
      await registrar.unregister();
      expect(api.unregistered, ['fcm-1']);
      await registrar.signedIn('user-1');
      expect(api.registered, hasLength(2), reason: 'state reset on sign-out');
    });

    test('without Firebase nothing is sent', () async {
      final off = DeviceRegistrar(
        api: api,
        push: const DisabledPushMessaging(),
        appVersion: '1.4.0',
      );
      await off.signedIn('user-1');
      await off.unregister();
      expect(api.registered, isEmpty);
      expect(api.unregistered, isEmpty);
    });

    test('POST and DELETE /v1/devices bodies', () async {
      final adapter = FakeAdapter((o) => emptyResponse(204));
      final client = ApiClient(
        AppConfig(apiBaseUrl: Uri.parse('http://test.local')),
        tokens: _NoTokens(),
        adapter: adapter,
      );
      final devices = ApiDeviceApi(client);
      await devices.register(token: 'fcm-1', appVersion: '1.4.0');
      await devices.unregister('fcm-1');
      final post = adapter.requests.first;
      expect((post.method, post.uri.path), ('POST', '/v1/devices'));
      expect(post.data, {
        'token': 'fcm-1',
        'platform': 'android',
        'app_version': '1.4.0',
      });
      final delete = adapter.requests.last;
      expect((delete.method, delete.uri.path), ('DELETE', '/v1/devices'));
      expect(delete.data, {'token': 'fcm-1'});
    });
  });

  group('push lifecycle', () {
    late FakeDeviceApi api;
    late FakePushMessaging push;
    late SessionManager session;
    late FakeAdapter authAdapter;
    late ProviderContainer container;

    setUp(() async {
      api = FakeDeviceApi();
      push = FakePushMessaging();
      final config = AppConfig(apiBaseUrl: Uri.parse('http://test.local'));
      authAdapter = FakeAdapter(
        routeHandler({'auth/logout': (_) => emptyResponse(204)}),
      );
      session = SessionManager(
        storage: FakeTokenStorage(),
        authApi: AuthApi(config, adapter: authAdapter),
        timer: InertTimer.new,
      );
      container = ProviderContainer(
        overrides: [
          appConfigProvider.overrideWithValue(config),
          sessionManagerProvider.overrideWithValue(session),
          pushMessagingProvider.overrideWithValue(push),
          deviceApiProvider.overrideWithValue(api),
          appVersionProvider.overrideWithValue('2.0.1'),
        ],
      );
    });
    tearDown(() async {
      container.dispose();
      await push.close();
    });

    test(
      'registers after sign-in; unregisters before the session clears',
      () async {
        container.read(pushLifecycleProvider);
        await session.setSession(Session.fromJson(sessionJson()));
        await pumpEventQueue();
        expect(api.registered, [(token: 'fcm-1', appVersion: '2.0.1')]);

        api.unregisterGate = Completer<void>();
        final signingOut = session.signOut();
        await pumpEventQueue();
        expect(api.unregistered, ['fcm-1']);
        expect(session.state, isA<SignedIn>(), reason: 'still signed in');
        expect(authAdapter.countPath('auth/logout'), 0);
        api.unregisterGate!.complete();
        await signingOut;
        expect(session.state, isA<SignedOut>());
        expect(authAdapter.countPath('auth/logout'), 1);
      },
    );

    test('a failed unregister never blocks sign-out', () async {
      container.read(pushLifecycleProvider);
      await session.setSession(Session.fromJson(sessionJson()));
      await pumpEventQueue();
      api.unregisterError = offlineError;
      await session.signOut();
      expect(session.state, isA<SignedOut>());
    });

    test(
      'a foreground push triggers the realtime catch-up, no notification',
      () async {
        final events = <RealtimeEvent>[];
        final sub = container
            .read(localRealtimeEventsProvider)
            .stream
            .listen(events.add);
        addTearDown(sub.cancel);
        container.read(pushLifecycleProvider);
        push.messages.add({'type': 'offer.received', 'order_id': 'o-1'});
        await pumpEventQueue();
        expect(events, isEmpty, reason: 'signed out');

        await session.setSession(Session.fromJson(sessionJson()));
        push.messages.add({'type': 'offer.received', 'order_id': 'o-1'});
        push.messages.add({'unrelated': 'x'});
        await pumpEventQueue();
        expect(events.map((e) => e.kind), [RealtimeEventKind.connected]);
      },
    );
  });

  group('minimum version', () {
    test('compares dotted versions numerically', () {
      expect(compareVersions('1.2.10', '1.2.9'), 1);
      expect(compareVersions('1.2', '1.2.0'), 0);
      expect(compareVersions('1.0.0+7', '1.0.0'), 0);
      expect(compareVersions('0.9.9', '1.0.0'), -1);
      expect(compareVersions('abc', '1.0.0'), isNull);
    });

    ProviderContainer gate(
      FakeAppConfigRepository repo,
      String installed, {
      DateTime Function()? clock,
    }) {
      final c = ProviderContainer(
        overrides: [
          appConfigRepositoryProvider.overrideWithValue(repo),
          appVersionProvider.overrideWithValue(installed),
          if (clock != null) clockProvider.overrideWithValue(clock),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    RemoteAppConfig config(String min) => RemoteAppConfig(
      minSupportedVersion: min,
      latestVersion: '1.5.0',
      storeUrl: 'https://play.google.com/store/apps/details?id=x',
    );

    test('below the minimum blocks; equal or above does not', () async {
      for (final (installed, blocked) in [
        ('1.1.9', true),
        ('1.2.0', false),
        ('1.3.0', false),
      ]) {
        final c = gate(
          FakeAppConfigRepository(config: config('1.2.0')),
          installed,
        );
        await c.read(versionGateProvider.notifier).check();
        final status = c.read(versionGateProvider);
        expect(status is UpdateRequired, blocked, reason: installed);
        if (status is UpdateRequired) {
          expect(status.storeUrl, contains('play.google.com'));
        }
      }
    });

    test('offline never blocks', () async {
      final c = gate(FakeAppConfigRepository(error: offlineError), '0.1.0');
      await c.read(versionGateProvider.notifier).check();
      expect(c.read(versionGateProvider), isA<VersionOk>());
    });

    test('checked at most every 30 minutes', () async {
      var now = DateTime(2026, 10, 21, 9);
      final repo = FakeAppConfigRepository(config: config('1.0.0'));
      final c = gate(repo, '1.0.0', clock: () => now);
      final g = c.read(versionGateProvider.notifier);
      await g.check();
      now = now.add(const Duration(minutes: 29));
      await g.check();
      expect(repo.calls, 1);
      repo.config = config('2.0.0');
      now = now.add(const Duration(minutes: 1));
      await g.check();
      expect(repo.calls, 2);
      expect(c.read(versionGateProvider), isA<UpdateRequired>());
    });

    test('parses GET /v1/app/config', () {
      final c = RemoteAppConfig.fromJson({
        'min_supported_version': {'android': '1.2.0'},
        'latest_version': {'android': '1.3.0'},
        'store_url': {'android': 'https://play.example/x'},
      });
      expect(c.minSupportedVersion, '1.2.0');
      expect(c.latestVersion, '1.3.0');
      expect(c.storeUrl, 'https://play.example/x');
      expect(RemoteAppConfig.fromJson({}).minSupportedVersion, isNull);
    });
  });
}

class _NoTokens implements AccessTokenSource {
  @override
  String? get accessToken => null;
  @override
  bool get hasSession => false;
  @override
  bool get accessTokenExpiresSoon => false;
  @override
  Future<bool> refresh() async => false;
}
