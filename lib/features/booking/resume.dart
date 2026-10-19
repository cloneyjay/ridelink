import '../../core/routing/app_router.dart';
import 'booking_routes.dart';
import 'data/booking_models.dart';

/// Where an active order from GET /orders/active resumes on the sender side.
sealed class ResumeTarget {
  const ResumeTarget();

  /// Identifies the live screen, so one the sender deliberately left isn't reopened.
  String get key;
  String get location;
  Object? get extra;
}

class ResumeWaiting extends ResumeTarget {
  const ResumeWaiting(this.pending);

  final PendingOffer pending;

  @override
  String get key => waitingScreenKey(pending.offer.id);
  @override
  String get location => AppRoutes.waitingFor(pending.order.id);
  @override
  Object? get extra => pending;
}

class ResumeTracking extends ResumeTarget {
  const ResumeTracking(this.order);

  final Order order;

  @override
  String get key => trackingScreenKey(order.id);
  @override
  String get location => AppRoutes.trackingFor(order.id);
  @override
  Object? get extra => null;
}

String waitingScreenKey(String offerId) => 'waiting:$offerId';
String trackingScreenKey(String orderId) => 'tracking:$orderId';

/// A pending offer resumes the waiting screen; an assigned or in-progress order resumes
/// tracking; anything else (e.g. still choosing a rider) has no live screen.
ResumeTarget? resumeTargetFor(SenderOrder o) {
  if (o.hasPendingOffer) {
    return ResumeWaiting(
      PendingOffer(
        order: o.order,
        rider: o.rider!,
        offer: o.offer!,
        fromServer: true,
      ),
    );
  }
  if (o.order.isActiveJob) return ResumeTracking(o.order);
  return null;
}

/// Newest first by `created_at` (the server already sends them so; this keeps it stable).
List<SenderOrder> newestFirst(List<SenderOrder> orders) {
  final indexed = orders.indexed.toList()
    ..sort((a, b) {
      final ta = a.$2.order.createdAt;
      final tb = b.$2.order.createdAt;
      if (ta != null && tb != null && ta != tb) return tb.compareTo(ta);
      return a.$1.compareTo(b.$1);
    });
  return [for (final (_, o) in indexed) o];
}

/// Resumable targets, newest first; the first one is the one to open.
List<ResumeTarget> resumeTargets(List<SenderOrder> orders) => [
  for (final o in newestFirst(orders)) ?resumeTargetFor(o),
];
