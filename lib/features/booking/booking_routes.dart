import 'data/booking_models.dart';

enum RiderListNotice { offerDeclined, offerExpired }

/// Rider list route payload; [notice] is shown once (e.g. after a declined offer).
class RiderListArgs {
  const RiderListArgs({this.order, this.notice});

  final Order? order;
  final RiderListNotice? notice;
}

/// The order plus the rider the sender picked from the list.
class RiderChoice {
  const RiderChoice({required this.order, required this.rider});

  final Order order;
  final RiderQuote rider;
}

class PendingOffer {
  const PendingOffer({
    required this.order,
    required this.rider,
    required this.offer,
    this.fromServer = false,
  });

  final Order order;
  final RiderQuote rider;
  final Offer offer;

  /// Read back from the server (resume) rather than just sent: the countdown then runs to
  /// `expires_at` instead of starting at the full window.
  final bool fromServer;
}
