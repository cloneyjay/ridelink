import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/google_auth.dart';
import '../features/booking/data/booking_repository.dart';
import '../features/evidence/data/evidence_repository.dart';
import '../features/notifications/data/notification_repository.dart';
import '../features/orders/data/orders_repository.dart';
import '../features/profile/public/public_profile_repository.dart';
import '../features/ratings/rating_prompt_store.dart';
import '../features/restrictions/data/restrictions_repository.dart';
import '../features/rider/data/rider_repository.dart';
import '../features/shell/account_repository.dart';
import 'api/api_client.dart';
import 'auth/auth_api.dart';
import 'auth/session.dart';
import 'auth/session_manager.dart';
import 'auth/token_storage.dart';
import 'config/app_config.dart';
import 'files/document_picker.dart';
import 'files/evidence_camera.dart';
import 'location/location_service.dart';
import 'location/location_tracker.dart';
import 'mode/app_mode.dart';
import 'navigation/navigation_launcher.dart';
import 'push/push_preferences.dart';
import 'push/push_taps.dart';
import 'realtime/realtime_client.dart';
import 'realtime/realtime_event.dart';
import 'routing/rider_intent.dart';
import 'share/share_service.dart';
import 'storage/local_data.dart';
import 'storage/local_store.dart';
import 'time/server_clock.dart';
import 'version/client_info.dart';

final appConfigProvider = Provider<AppConfig>(
  (ref) => AppConfig.fromEnvironment(),
);

final tokenStorageProvider = Provider<TokenStorage>(
  (ref) => SecureTokenStorage(),
);

final authApiProvider = Provider<AuthApi>(
  (ref) => AuthApi(
    ref.watch(appConfigProvider),
    clock: ref.watch(serverClockProvider),
    clientInfo: ref.watch(clientInfoProvider),
  ),
);

final sessionManagerProvider = Provider<SessionManager>((ref) {
  final manager = SessionManager(
    storage: ref.watch(tokenStorageProvider),
    authApi: ref.watch(authApiProvider),
    clock: ref.watch(serverClockProvider),
  );
  ref.onDispose(manager.dispose);
  return manager;
});

/// Session state as a Riverpod value (unknown / signedOut / signedIn).
final sessionStateProvider =
    NotifierProvider<SessionStateNotifier, SessionState>(
      SessionStateNotifier.new,
    );

class SessionStateNotifier extends Notifier<SessionState> {
  @override
  SessionState build() {
    final manager = ref.watch(sessionManagerProvider);
    void sync() => state = manager.state;
    manager.addListener(sync);
    ref.onDispose(() => manager.removeListener(sync));
    return manager.state;
  }
}

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(
    ref.watch(appConfigProvider),
    tokens: ref.watch(sessionManagerProvider),
    serverClock: ref.watch(serverClockProvider),
    clientInfo: ref.watch(clientInfoProvider),
  ),
);

final realtimeClientProvider = Provider<RealtimeClient>((ref) {
  final client = RealtimeClient(
    uri: ref.watch(appConfigProvider).webSocketUri,
    tokens: ref.watch(sessionManagerProvider),
    clientInfo: ref.watch(clientInfoProvider),
  );
  ref.onDispose(client.dispose);
  return client;
});

/// Keeps the realtime connection open exactly while signed in. Watch it once from the app root.
final realtimeLifecycleProvider = Provider<void>((ref) {
  final client = ref.watch(realtimeClientProvider);
  void apply(SessionState state) =>
      state is SignedIn ? client.start() : client.stop();
  ref.listen<SessionState>(sessionStateProvider, (_, next) => apply(next));
  apply(ref.read(sessionStateProvider));
});

/// Events raised inside the app, e.g. a catch-up after a foreground push.
final localRealtimeEventsProvider = Provider<StreamController<RealtimeEvent>>((
  ref,
) {
  final controller = StreamController<RealtimeEvent>.broadcast();
  ref.onDispose(controller.close);
  return controller;
});

/// Server events from GET /v1/ws merged with [localRealtimeEventsProvider].
final realtimeEventsProvider = StreamProvider<RealtimeEvent>((ref) {
  final server = ref.watch(realtimeClientProvider).events;
  final local = ref.watch(localRealtimeEventsProvider).stream;
  final out = StreamController<RealtimeEvent>();
  final subs = <StreamSubscription<RealtimeEvent>>[];
  out.onListen = () {
    subs
      ..add(server.listen(out.add, onError: out.addError))
      ..add(local.listen(out.add, onError: out.addError));
  };
  out.onCancel = () async {
    for (final s in subs) {
      await s.cancel();
    }
  };
  return out.stream;
});

final googleAuthProvider = Provider<GoogleAuth>(
  (ref) => GoogleSignInAuth(ref.watch(appConfigProvider).googleServerClientId),
);

final riderIntentProvider = Provider<RiderIntent>((ref) {
  final intent = RiderIntent();
  ref.onDispose(intent.dispose);
  return intent;
});

final bookingRepositoryProvider = Provider<BookingRepository>(
  (ref) => ApiBookingRepository(ref.watch(apiClientProvider)),
);

final accountRepositoryProvider = Provider<AccountRepository>(
  (ref) => ApiAccountRepository(ref.watch(apiClientProvider)),
);

final locationServiceProvider = Provider<LocationService>(
  (ref) => GeolocatorLocationService(),
);

/// Whether the signed-in user has a rider profile; re-checked whenever the session changes.
final isRiderProvider = FutureProvider<bool>((ref) {
  final session = ref.watch(sessionStateProvider);
  if (session is! SignedIn) return false;
  return ref.watch(accountRepositoryProvider).isRider();
}, retry: (_, _) => null);

/// The sender's last known fix: biases place search and seeds the default pickup.
final lastKnownLocationProvider =
    NotifierProvider<LastKnownLocation, LocationFix?>(LastKnownLocation.new);

class LastKnownLocation extends Notifier<LocationFix?> {
  @override
  LocationFix? build() => null;

  void set(LocationFix? fix) => state = fix;
}

final riderRepositoryProvider = Provider<RiderRepository>(
  (ref) => ApiRiderRepository(ref.watch(apiClientProvider)),
);

final locationTrackerProvider = Provider<LocationTracker>(
  (ref) => GeolocatorLocationTracker(),
);

final documentPickerProvider = Provider<DocumentPicker>(
  (ref) => PlatformDocumentPicker(),
);

/// Evidence photos come from the camera only (founder decision 2026-10-19).
final evidenceCameraProvider = Provider<EvidenceCamera>(
  (ref) => PlatformEvidenceCamera(),
);

/// Overridden in main() with the SharedPreferences-backed store.
final modeStoreProvider = Provider<ModeStore>((ref) => MemoryModeStore());

final appModeProvider = Provider<AppModeController>((ref) {
  final controller = AppModeController(ref.watch(modeStoreProvider));
  ref.onDispose(controller.dispose);
  return controller;
});

/// Injectable clock for countdowns and grace windows.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Device-to-server clock offset, fed by every API response's `Date` header.
final serverClockProvider = Provider<ServerClock>(
  (ref) => ServerClock(deviceNow: ref.watch(clockProvider)),
);

/// Server-adjusted "now": use it for every countdown driven by a server timestamp.
final serverNowProvider = Provider<DateTime Function()>(
  (ref) => ref.watch(serverClockProvider).now,
);

/// Per-app-session flags (reset on restart).
class SessionFlags {
  /// Live screens (waiting/tracking) already opened this session, so a resume never
  /// sends the sender back to one they deliberately left.
  final openedLiveScreens = <String>{};
}

final sessionFlagsProvider = Provider<SessionFlags>((ref) => SessionFlags());

/// Overridden in main() with the SharedPreferences-backed store.
final localStoreProvider = Provider<LocalStore>((ref) => MemoryLocalStore());

final pushPreferencesProvider = Provider<PushPreferences>(
  (ref) => PushPreferences(ref.watch(localStoreProvider)),
);

final ratingPromptStoreProvider = Provider<RatingPromptStore>(
  (ref) => RatingPromptStore(ref.watch(localStoreProvider)),
);

final ordersRepositoryProvider = Provider<OrdersRepository>(
  (ref) => ApiOrdersRepository(ref.watch(apiClientProvider)),
);

final evidenceRepositoryProvider = Provider<EvidenceRepository>(
  (ref) => ApiEvidenceRepository(ref.watch(apiClientProvider)),
);

final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => ApiNotificationRepository(ref.watch(apiClientProvider)),
);

final restrictionsRepositoryProvider = Provider<RestrictionsRepository>(
  (ref) => ApiRestrictionsRepository(ref.watch(apiClientProvider)),
);

final publicProfileRepositoryProvider = Provider<PublicProfileRepository>(
  (ref) => ApiPublicProfileRepository(ref.watch(apiClientProvider)),
);

final navigationLauncherProvider = Provider<NavigationLauncher>(
  (ref) => UrlNavigationLauncher(),
);

final shareServiceProvider = Provider<ShareService>(
  (ref) => SharePlusService(),
);

/// The signed-in user's id, or null.
final currentUserIdProvider = Provider<String?>((ref) {
  final session = ref.watch(sessionStateProvider);
  return session is SignedIn ? session.session.user.id : null;
});

/// Wipes the user's device data; see [LocalData.clearUserData].
final localDataProvider = Provider<LocalData>(
  (ref) => LocalData(
    store: ref.watch(localStoreProvider),
    mode: ref.watch(appModeProvider),
    resetMemory: [
      () => ref.read(lastKnownLocationProvider.notifier).set(null),
      () => ref.read(sessionFlagsProvider).openedLiveScreens.clear(),
      () => ref.read(pushTapsProvider).take(),
    ],
  ),
);

/// A definitive session rejection (401 on refresh) wipes the user's device data. Read it once
/// from the app root before restoring the session.
final userDataLifecycleProvider = Provider<void>((ref) {
  final session = ref.watch(sessionManagerProvider);
  final data = ref.watch(localDataProvider);
  Future<void> clear() => data.clearUserData();
  session.onSessionRejected = clear;
  ref.onDispose(() {
    if (session.onSessionRejected == clear) session.onSessionRejected = null;
  });
});
