import 'dart:convert';

import '../../../core/storage/local_store.dart';
import 'booking_models.dart';

/// The offer the sender is waiting on, kept on the device so the waiting screen can resume
/// after a restart (no sender-side endpoint returns the pending offer).
class StoredPendingOffer {
  const StoredPendingOffer({required this.offer, required this.rider});

  final Offer offer;
  final RiderQuote rider;
}

class PendingOfferStore {
  PendingOfferStore(this._store);

  static const _key = 'ridelink.pending_offer';
  final LocalStore _store;

  Future<void> save(Offer offer, RiderQuote rider) => _store.setString(
    _key,
    jsonEncode({'offer': offer.toJson(), 'rider': rider.toJson()}),
  );

  /// The stored offer for [orderId], or null.
  StoredPendingOffer? read(String orderId) {
    final raw = _store.getString(_key);
    if (raw == null) return null;
    try {
      final json = (jsonDecode(raw) as Map).cast<String, dynamic>();
      final offer = Offer.fromJson(
        (json['offer'] as Map).cast<String, dynamic>(),
      );
      if (offer.orderId != orderId) return null;
      return StoredPendingOffer(
        offer: offer,
        rider: RiderQuote.fromJson(
          (json['rider'] as Map).cast<String, dynamic>(),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() => _store.remove(_key);
}
