import '../../../core/location/geo_point.dart';
import '../../booking/data/booking_models.dart';

/// The assigned rider as the order's parties see them (GET /orders/{id} "rider").
class OrderRider {
  const OrderRider({
    required this.riderId,
    required this.displayName,
    required this.plateNumber,
    required this.hasPhoto,
    required this.ratingAverage,
    required this.ratingCount,
  });

  factory OrderRider.fromJson(Map<String, dynamic> json) {
    final rating = (json['rating'] as Map?)?.cast<String, dynamic>() ?? {};
    return OrderRider(
      riderId: json['rider_id'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '',
      plateNumber: json['plate_number'] as String? ?? '',
      hasPhoto: json['has_photo'] as bool? ?? false,
      ratingAverage: (rating['average'] as num? ?? 0).toDouble(),
      ratingCount: (rating['count'] as num? ?? 0).toInt(),
    );
  }

  final String riderId;
  final String displayName;
  final String plateNumber;
  final bool hasPhoto;
  final double ratingAverage;
  final int ratingCount;
}

/// The receiver's pinned drop-off spot, shared through the receiver link.
class ReceiverLocation {
  const ReceiverLocation({required this.point, this.note, this.updatedAt});

  factory ReceiverLocation.fromJson(Map<String, dynamic> json) =>
      ReceiverLocation(
        point: GeoPoint(
          (json['lat'] as num).toDouble(),
          (json['lng'] as num).toDouble(),
        ),
        note: (json['note'] as String?)?.trim().isEmpty ?? true
            ? null
            : (json['note'] as String).trim(),
        updatedAt: parseTime(json['updated_at']),
      );

  final GeoPoint point;
  final String? note;
  final DateTime? updatedAt;
}

/// The terms snapshot written at acceptance (GET /orders/{id} "terms").
class OrderTerms {
  const OrderTerms({
    required this.total,
    required this.currency,
    this.tripDistanceKm,
    this.breakdown,
    this.pickupWindowMins,
    this.pickupDeadline,
    this.riderCancelGraceSecs,
    this.acceptedAt,
  });

  factory OrderTerms.fromJson(Map<String, dynamic> json) {
    final quote = (json['quote'] as Map?)?.cast<String, dynamic>() ?? {};
    final policy =
        (json['cancel_policy'] as Map?)?.cast<String, dynamic>() ?? {};
    final breakdown = quote['breakdown'];
    return OrderTerms(
      total: (quote['total'] as num? ?? 0).round(),
      currency: quote['currency'] as String? ?? 'KES',
      tripDistanceKm: (quote['trip_distance_km'] as num?)?.toDouble(),
      breakdown: breakdown is Map
          ? QuoteBreakdown.fromJson(breakdown.cast<String, dynamic>())
          : null,
      pickupWindowMins: (policy['pickup_window_mins'] as num?)?.toInt(),
      pickupDeadline: parseTime(policy['pickup_deadline']),
      riderCancelGraceSecs: (policy['rider_cancel_grace_secs'] as num?)
          ?.toInt(),
      acceptedAt: parseTime(json['accepted_at']),
    );
  }

  final int total;
  final String currency;
  final double? tripDistanceKm;
  final QuoteBreakdown? breakdown;
  final int? pickupWindowMins;
  final DateTime? pickupDeadline;
  final int? riderCancelGraceSecs;
  final DateTime? acceptedAt;
}

/// GET /orders/{id} with what the caller's role may see about the other party.
class OrderDetails {
  const OrderDetails({
    required this.order,
    this.rider,
    this.senderName,
    this.receiverLocation,
    this.terms,
  });

  factory OrderDetails.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? obj(String key) =>
        json[key] is Map ? (json[key] as Map).cast<String, dynamic>() : null;
    final rider = obj('rider');
    final sender = obj('sender');
    final receiver = obj('receiver_location');
    final terms = obj('terms');
    return OrderDetails(
      order: Order.fromJson(json),
      rider: rider == null ? null : OrderRider.fromJson(rider),
      senderName: sender?['display_name'] as String?,
      receiverLocation: receiver == null
          ? null
          : ReceiverLocation.fromJson(receiver),
      terms: terms == null ? null : OrderTerms.fromJson(terms),
    );
  }

  final Order order;
  final OrderRider? rider;

  /// "First L.", present only for the assigned rider.
  final String? senderName;
  final ReceiverLocation? receiverLocation;
  final OrderTerms? terms;

  OrderDetails withOrder(Order next) => OrderDetails(
    order: next,
    rider: rider,
    senderName: senderName,
    receiverLocation: receiverLocation,
    terms: terms,
  );
}

class Rating {
  const Rating({
    required this.fromId,
    required this.toId,
    required this.score,
    this.comment,
    this.createdAt,
  });

  factory Rating.fromJson(Map<String, dynamic> json) => Rating(
    fromId: json['from_id'] as String? ?? '',
    toId: json['to_id'] as String? ?? '',
    score: (json['score'] as num? ?? 0).toInt(),
    comment: json['comment'] as String?,
    createdAt: parseTime(json['created_at']),
  );

  final String fromId;
  final String toId;
  final int score;
  final String? comment;
  final DateTime? createdAt;
}

class ReceiverLink {
  const ReceiverLink({required this.url, this.expiresAt});

  factory ReceiverLink.fromJson(Map<String, dynamic> json) => ReceiverLink(
    url: json['url'] as String,
    expiresAt: parseTime(json['expires_at']),
  );

  final String url;
  final DateTime? expiresAt;
}

class Profile {
  const Profile({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.displayName,
    this.legalUpdateRequired = false,
  });

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
    id: json['id'] as String? ?? '',
    email: json['email'] as String? ?? '',
    firstName: json['first_name'] as String? ?? '',
    lastName: json['last_name'] as String? ?? '',
    displayName: json['display_name'] as String? ?? '',
    legalUpdateRequired: json['legal_update_required'] == true,
  );

  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String displayName;

  /// The current Terms/Privacy versions haven't been accepted yet.
  final bool legalUpdateRequired;
}
