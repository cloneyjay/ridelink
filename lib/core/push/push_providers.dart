import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/session.dart';
import '../providers.dart';
import '../realtime/realtime_event.dart';
import '../routing/app_router.dart';
import '../version/version_gate.dart';
import 'device_registrar.dart';
import 'notification_permission.dart';
import 'push_messaging.dart';
import 'push_navigator.dart';
import 'push_payload.dart';

/// Overridden in main() with the Firebase implementation when Firebase initialised.
final pushMessagingProvider = Provider<PushMessaging>(
  (ref) => const DisabledPushMessaging(),
);

final deviceApiProvider = Provider<DeviceApi>(
  (ref) => ApiDeviceApi(ref.watch(apiClientProvider)),
);

final deviceRegistrarProvider = Provider<DeviceRegistrar>((ref) {
  final registrar = DeviceRegistrar(
    api: ref.watch(deviceApiProvider),
    push: ref.watch(pushMessagingProvider),
    appVersion: ref.watch(appVersionProvider),
  );
  ref.onDispose(registrar.dispose);
  return registrar;
});

final notificationPermissionProvider = Provider<NotificationPermission>(
  (ref) => PlatformNotificationPermission(),
);

/// Whether the app may post notifications; invalidate after asking or on resume.
final notificationsAllowedProvider = FutureProvider.autoDispose<bool>(
  (ref) async =>
      await ref.watch(notificationPermissionProvider).status() ==
      NotificationPermissionStatus.granted,
  retry: (_, _) => null,
);

/// Notification taps, held until the user is signed in.
class PushTaps {
  final _controller = StreamController<PushPayload>.broadcast();
  PushPayload? _pending;

  Stream<PushPayload> get stream => _controller.stream;

  void add(PushPayload? p) {
    if (p == null) return;
    _pending = p;
    _controller.add(p);
  }

  PushPayload? take() {
    final p = _pending;
    _pending = null;
    return p;
  }

  Future<void> dispose() => _controller.close();
}

/// Overridden in main() with the instance the local-notification plugin reports into.
final pushTapsProvider = Provider<PushTaps>((ref) {
  final taps = PushTaps();
  ref.onDispose(taps.dispose);
  return taps;
});

final pushNavigatorProvider = Provider<PushNavigator>(
  (ref) => PushNavigator(
    router: ref.watch(routerProvider),
    mode: ref.watch(appModeProvider),
    bookingRepo: ref.watch(bookingRepositoryProvider),
    riderRepo: ref.watch(riderRepositoryProvider),
    flags: ref.watch(sessionFlagsProvider),
  ),
);

/// The catch-up a realtime reconnect triggers (active orders, offers, notifications).
const pushCatchUpEvent = RealtimeEvent(
  type: 'connected',
  kind: RealtimeEventKind.connected,
  data: {'source': 'push'},
);

/// Device registration, foreground pushes and notification taps. Watch it once from the app
/// root.
final pushLifecycleProvider = Provider<void>((ref) {
  final registrar = ref.watch(deviceRegistrarProvider);
  final session = ref.watch(sessionManagerProvider);
  final taps = ref.watch(pushTapsProvider);
  Future<void> unregister() => registrar.unregister();
  session.beforeSignOut = unregister;
  ref.onDispose(() {
    if (session.beforeSignOut == unregister) session.beforeSignOut = null;
  });

  void openPendingTap() {
    if (ref.read(sessionStateProvider) is! SignedIn) return;
    final tap = taps.take();
    if (tap != null) unawaited(ref.read(pushNavigatorProvider).open(tap));
  }

  void apply(SessionState state) {
    switch (state) {
      case SignedIn(:final session):
        unawaited(registrar.signedIn(session.user.id));
        openPendingTap();
      case SignedOut():
        registrar.signedOut();
      default:
    }
  }

  ref.listen<SessionState>(sessionStateProvider, (_, next) => apply(next));
  apply(ref.read(sessionStateProvider));

  final tapSub = taps.stream.listen((_) => openPendingTap());
  // Foreground: no system notification; refresh as a realtime reconnect would.
  final messageSub = ref
      .watch(pushMessagingProvider)
      .onForegroundMessage
      .listen((data) {
        if (PushPayload.fromData(data) == null) return;
        if (ref.read(sessionStateProvider) is! SignedIn) return;
        ref.read(localRealtimeEventsProvider).add(pushCatchUpEvent);
      });
  ref.onDispose(() {
    tapSub.cancel();
    messageSub.cancel();
  });
});
