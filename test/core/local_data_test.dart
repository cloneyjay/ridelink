import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridelink/core/auth/auth_api.dart';
import 'package:ridelink/core/auth/session.dart';
import 'package:ridelink/core/auth/session_manager.dart';
import 'package:ridelink/core/config/app_config.dart';
import 'package:ridelink/core/location/geo_point.dart';
import 'package:ridelink/core/location/location_service.dart';
import 'package:ridelink/core/mode/app_mode.dart';
import 'package:ridelink/core/providers.dart';
import 'package:ridelink/core/push/push_locale.dart';
import 'package:ridelink/core/push/push_payload.dart';
import 'package:ridelink/core/push/push_preferences.dart';
import 'package:ridelink/core/push/push_taps.dart';
import 'package:ridelink/core/storage/local_store.dart';
import 'package:ridelink/features/ratings/rating_prompt_store.dart';

import '../support/fakes.dart';

MemoryLocalStore userStore() => MemoryLocalStore()
  ..values[RatingPromptStore.storageKey] = ['order-1']
  ..values[PushPreferences.notificationsAskedKey] = '1'
  ..values[localeStoreKey] = 'sw';

void main() {
  late MemoryLocalStore store;
  late MemoryModeStore modeStore;
  late FakeTokenStorage tokens;
  late SessionManager session;
  late ProviderContainer container;

  void setUpWith(FakeHandler auth) {
    store = userStore();
    modeStore = MemoryModeStore(AppMode.rider);
    tokens = FakeTokenStorage('refresh-1');
    final config = AppConfig(apiBaseUrl: Uri.parse('http://test.local'));
    session = SessionManager(
      storage: tokens,
      authApi: AuthApi(config, adapter: FakeAdapter(auth)),
      timer: InertTimer.new,
    );
    container = ProviderContainer(
      overrides: [
        sessionManagerProvider.overrideWithValue(session),
        localStoreProvider.overrideWithValue(store),
        modeStoreProvider.overrideWithValue(modeStore),
      ],
    );
    addTearDown(container.dispose);
    container.read(userDataLifecycleProvider);
    container
        .read(lastKnownLocationProvider.notifier)
        .set(
          LocationFix(point: const GeoPoint(-1.26, 36.8), at: DateTime(2026)),
        );
    container.read(sessionFlagsProvider).openedLiveScreens.add('tracking:o');
    container
        .read(pushTapsProvider)
        .add(const PushPayload(type: 'offer.received', orderId: 'o'));
  }

  void expectWiped() {
    expect(store.values, {localeStoreKey: 'sw'}, reason: 'only the language');
    expect(modeStore.mode, isNull);
    expect(container.read(appModeProvider).mode, AppMode.sender);
    expect(container.read(lastKnownLocationProvider), isNull);
    expect(container.read(sessionFlagsProvider).openedLiveScreens, isEmpty);
    expect(container.read(pushTapsProvider).take(), isNull);
  }

  void expectKept() {
    expect(store.values.keys, hasLength(3));
    expect(container.read(appModeProvider).mode, AppMode.rider);
    expect(container.read(lastKnownLocationProvider), isNotNull);
  }

  test('clearUserData keeps only the device language', () async {
    setUpWith(routeHandler({}));
    await container.read(localDataProvider).clearUserData();
    expectWiped();
  });

  test('a definitive rejection (401 on refresh) wipes user data', () async {
    setUpWith(
      routeHandler({
        'auth/refresh': (_) => jsonResponse(401, {'error': 'x'}),
      }),
    );
    container.read(appModeProvider);
    await session.restore();
    expect(session.state, isA<SignedOut>());
    expect(tokens.refreshToken, isNull);
    expectWiped();
  });

  test('a transient refresh failure keeps everything', () async {
    setUpWith(
      routeHandler({
        'auth/refresh': (_) => jsonResponse(503, {'error': 'x'}),
      }),
    );
    container.read(appModeProvider);
    await session.restore();
    expect(session.state, isA<SessionOffline>());
    expectKept();
  });

  test('a normal sign-out keeps mode and prompts', () async {
    setUpWith(
      routeHandler({
        'auth/refresh': (_) => jsonResponse(200, sessionJson()),
        'auth/logout': (_) => emptyResponse(204),
      }),
    );
    container.read(appModeProvider);
    await session.restore();
    expect(session.state, isA<SignedIn>());
    await session.signOut();
    expect(session.state, isA<SignedOut>());
    expectKept();
  });
}
