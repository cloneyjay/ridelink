import 'package:go_router/go_router.dart';

import '../../features/booking/data/booking_repository.dart';
import '../../features/booking/resume.dart';
import '../../features/rider/data/rider_repository.dart';
import '../mode/app_mode.dart';
import '../providers.dart';
import '../routing/app_router.dart';
import 'push_payload.dart';

/// Where a tapped push opens, decided from the server's current state (never from the push).
class PushNavigator {
  PushNavigator({
    required this.router,
    required this.mode,
    required this.bookingRepo,
    required this.riderRepo,
    required this.flags,
  });

  final GoRouter router;
  final AppModeController mode;
  final BookingRepository bookingRepo;
  final RiderRepository riderRepo;
  final SessionFlags flags;

  Future<void> open(PushPayload p) async {
    final riderScreen = riderScreenFor(p.type);
    if (riderScreen != null) {
      // Nested under rider home, so back returns there.
      router.go(riderScreen);
      return;
    }
    final orderId = p.orderId;
    if (orderId == null) return;
    if (p.isOffer ||
        riderPushTypes.contains(p.type) ||
        mode.mode == AppMode.rider) {
      await _openAsRider(orderId, offer: p.isOffer);
    } else {
      await _openAsSender(orderId);
    }
  }

  /// Rider home shows the active offer or job from GET /riders/me/active; any other order
  /// opens its detail on top.
  Future<void> _openAsRider(String orderId, {required bool offer}) async {
    router.go(AppRoutes.riderHome);
    if (offer) return;
    try {
      final active = await riderRepo.active();
      if (active.order?.id == orderId || active.offer?.orderId == orderId) {
        return;
      }
    } catch (_) {}
    router.push(AppRoutes.orderDetailFor(orderId, asRider: true));
  }

  Future<void> _openAsSender(String orderId) async {
    try {
      final view = await bookingRepo.senderOrder(orderId);
      final live = resumeTargetFor(view);
      if (live != null) flags.openedLiveScreens.add(live.key);
      final route = senderRouteAfterConflict(view);
      router.go(route.location, extra: route.extra);
    } catch (_) {
      router.push(AppRoutes.orderDetailFor(orderId));
    }
  }
}
