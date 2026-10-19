import '../../booking/data/booking_models.dart';
import '../../evidence/data/evidence_models.dart';

/// What the rider can do next on an active job.
enum JobAction {
  /// Fallback when automatic arrival hasn't fired (pickup-timer decision 16).
  arrivedAtPickup,
  pickedUp,
  startTrip,
  arrivedAtDropoff,
  requestPayment,

  /// Waiting for the sender to tap "I've paid".
  waitForSender,

  /// Sender says they paid: confirm received or not received.
  confirmPayment,
  handOver,
  complete,

  /// Terminal: completed, cancelled, unresolved, expired.
  none,
}

JobAction nextAction(Order o) => switch (o.status) {
  'accepted' =>
    o.arrivedAtPickup ? JobAction.pickedUp : JobAction.arrivedAtPickup,
  'started' => JobAction.startTrip,
  'in_transit' => JobAction.arrivedAtDropoff,
  'arrived' => JobAction.requestPayment,
  'payment_requested' => JobAction.waitForSender,
  'cash_pending' => JobAction.confirmPayment,
  'paid' => JobAction.handOver,
  'handed_over' => JobAction.complete,
  _ => JobAction.none,
};

/// The status a plain PATCH /status moves to for [action], or null if the action uses another endpoint.
String? statusFor(JobAction action) => switch (action) {
  JobAction.pickedUp => 'started',
  JobAction.startTrip => 'in_transit',
  JobAction.arrivedAtDropoff => 'arrived',
  JobAction.handOver => 'handed_over',
  JobAction.complete => 'completed',
  _ => null,
};

/// The evidence photo [action] needs first: deliveries only, never rides (founder decision
/// 2026-10-19; the server answers 422 evidence_photo_required otherwise).
MediaKind? requiredPhoto(Order o, JobAction action) {
  if (o.serviceType != ServiceType.delivery) return null;
  return switch (action) {
    JobAction.pickedUp => MediaKind.pickupPhoto,
    JobAction.handOver => MediaKind.handoverPhoto,
    _ => null,
  };
}

/// The photo card a delivery shows in [o]'s status, or null (rides never show one).
MediaKind? photoStepFor(Order o) {
  if (o.serviceType != ServiceType.delivery) return null;
  return switch (o.status) {
    'accepted' when o.arrivedAtPickup => MediaKind.pickupPhoto,
    'started' => MediaKind.pickupPhoto,
    'paid' || 'handed_over' => MediaKind.handoverPhoto,
    _ => null,
  };
}

/// Only before pickup (accepted -> cancelled is the only cancel transition after acceptance).
bool riderCanCancel(Order o) => o.status == 'accepted';

/// Rider cancels within this time of accepting don't count toward the pause (pickup-timer decision 17).
const riderCancelGrace = Duration(minutes: 2);

/// Time left in the no-penalty cancel window, or zero once it has passed.
Duration cancelGraceLeft(Order o, DateTime now) {
  final accepted = o.acceptedAt;
  if (accepted == null) return Duration.zero;
  final left = accepted.add(riderCancelGrace).difference(now);
  return left.isNegative ? Duration.zero : left;
}

/// Sender's step progress on screen 7: accepted -> at pickup -> in transit -> payment -> delivered.
enum TrackingStep { accepted, atPickup, inTransit, payment, delivered }

TrackingStep trackingStep(Order o) => switch (o.status) {
  'accepted' =>
    o.arrivedAtPickup ? TrackingStep.atPickup : TrackingStep.accepted,
  'started' || 'in_transit' => TrackingStep.inTransit,
  'arrived' ||
  'payment_requested' ||
  'cash_pending' ||
  'paid' ||
  'unresolved' => TrackingStep.payment,
  'handed_over' || 'completed' => TrackingStep.delivered,
  _ => TrackingStep.accepted,
};

/// Time until the pickup deadline, or null once the rider has arrived (one countdown, decision 7).
Duration? pickupCountdown(Order o, DateTime now) {
  if (o.status != 'accepted' || o.arrivedAtPickup) return null;
  final deadline = o.pickupDeadline;
  if (deadline == null) return null;
  final left = deadline.difference(now);
  return left.isNegative ? Duration.zero : left;
}

/// Whole minutes, rounded up, for "Rider arrives in N min".
int minutesLeft(Duration d) => (d.inSeconds / 60).ceil();

/// "9:05" for countdowns.
String formatClock(Duration d) {
  final s = d.inSeconds < 0 ? 0 : d.inSeconds;
  return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
}
