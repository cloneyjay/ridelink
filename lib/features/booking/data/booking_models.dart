import '../../../core/location/geo_point.dart';

enum ServiceType {
  delivery('delivery'),
  ride('ride');

  const ServiceType(this.wire);
  final String wire;

  static ServiceType? fromWire(String? value) {
    for (final t in values) {
      if (t.wire == value) return t;
    }
    return null;
  }
}

/// Declared item value (schema-mismatch decisions 5–7). KES 10,000 is the cap.
enum ValueBand {
  under500('under_500'),
  from500To2000('500_to_2000'),
  from2000To5000('2000_to_5000'),
  from5000To10000('5000_to_10000');

  const ValueBand(this.wire);
  final String wire;
}

class PlacePrediction {
  const PlacePrediction({
    required this.placeId,
    required this.primaryText,
    required this.secondaryText,
  });

  factory PlacePrediction.fromJson(Map<String, dynamic> json) =>
      PlacePrediction(
        placeId: json['place_id'] as String,
        primaryText: json['primary_text'] as String? ?? '',
        secondaryText: json['secondary_text'] as String? ?? '',
      );

  final String placeId;
  final String primaryText;
  final String secondaryText;
}

class Place {
  const Place({
    required this.placeId,
    required this.name,
    required this.address,
    required this.location,
    this.localLabel,
  });

  factory Place.fromJson(Map<String, dynamic> json) => Place(
    placeId: json['place_id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    address: json['address'] as String? ?? '',
    location: GeoPoint.fromJson(
      (json['location'] as Map).cast<String, dynamic>(),
    ),
  );

  final String placeId;
  final String name;
  final String address;
  final GeoPoint location;

  /// Shown only on this device when there is no real address (e.g. "Current location").
  final String? localLabel;

  bool get hasAddress => name.isNotEmpty || address.isNotEmpty;

  /// Text shown to the sender: the place name, plus the address when it adds detail.
  String get label {
    if (!hasAddress) return localLabel ?? coordinateText(location);
    if (address.isEmpty) return name;
    if (name.isEmpty || address.contains(name)) return address;
    return '$name, $address';
  }

  /// Text stored on the order: the address, or language-neutral coordinates when there is none.
  String get orderAddress => hasAddress ? label : coordinateText(location);
}

/// "-1.28636, 36.81720": 5 decimals (about 1 m), readable in any language.
String coordinateText(GeoPoint p) =>
    '${p.lat.toStringAsFixed(5)}, ${p.lng.toStringAsFixed(5)}';

class ItemCategory {
  const ItemCategory({
    required this.id,
    required this.code,
    required this.status,
    required this.requiresExtraCheck,
  });

  factory ItemCategory.fromJson(Map<String, dynamic> json) => ItemCategory(
    id: json['id'] as String,
    code: json['code'] as String? ?? '',
    status: json['status'] as String? ?? 'allowed',
    requiresExtraCheck: json['requires_extra_check'] as bool? ?? false,
  );

  final String id;
  final String code;
  final String status;
  final bool requiresExtraCheck;

  bool get isProhibited => status == 'prohibited';
}

class RouteInput {
  const RouteInput({required this.pickup, required this.dropoff});

  final Place pickup;
  final Place dropoff;

  Map<String, dynamic> toJson() => {
    'pickup_address': pickup.orderAddress,
    'dropoff_address': dropoff.orderAddress,
    'pickup_location': pickup.location.toJson(),
    'dropoff_location': dropoff.location.toJson(),
  };
}

class DeclarationInput {
  const DeclarationInput({
    required this.categoryId,
    required this.description,
    required this.valueBand,
    this.weightKg,
  });

  final String categoryId;
  final String description;
  final double? weightKg;
  final ValueBand valueBand;

  Map<String, dynamic> toJson() => {
    'category_id': categoryId,
    'description': description,
    'weight_kg': ?weightKg,
    'value_band': valueBand.wire,
  };
}

class CreateOrderInput {
  const CreateOrderInput({
    required this.serviceType,
    required this.route,
    this.receiverName,
    this.declaration,
  });

  final ServiceType serviceType;
  final RouteInput route;
  final String? receiverName;
  final DeclarationInput? declaration;

  Map<String, dynamic> toJson() => {
    'service_type': serviceType.wire,
    ...route.toJson(),
    'receiver_name': ?receiverName,
    if (declaration != null) 'declaration': declaration!.toJson(),
  };
}

/// Order statuses after acceptance where a rider is on the job (not terminal).
const activeJobStatuses = {
  'accepted',
  'started',
  'in_transit',
  'arrived',
  'payment_requested',
  'cash_pending',
  'paid',
  'handed_over',
};

const terminalStatuses = {
  'completed',
  'cancelled',
  'expired',
  'payment_failed',
  'unresolved',
};

class Order {
  const Order({
    required this.id,
    required this.serviceType,
    required this.status,
    required this.pickupAddress,
    required this.dropoffAddress,
    this.pickupLocation,
    this.dropoffLocation,
    this.receiverName,
    this.distanceKm,
    this.distanceEstimated = false,
    this.riderId,
    this.senderId,
    this.agreedPrice,
    this.acceptedAt,
    this.pickupDistanceKm,
    this.pickupWindowMins,
    this.pickupDeadline,
    this.pickupArrivedAt,
    this.cancelReason,
    this.quoteBreakdown,
    this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    GeoPoint? point(Object? v) =>
        v is Map ? GeoPoint.fromJson(v.cast<String, dynamic>()) : null;
    final breakdown = json['quote_breakdown'];
    return Order(
      id: json['id'] as String,
      serviceType:
          ServiceType.fromWire(json['service_type'] as String?) ??
          ServiceType.delivery,
      status: json['status'] as String? ?? '',
      pickupAddress: json['pickup_address'] as String? ?? '',
      dropoffAddress: json['dropoff_address'] as String? ?? '',
      pickupLocation: point(json['pickup_location']),
      dropoffLocation: point(json['dropoff_location']),
      receiverName: json['receiver_name'] as String?,
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      distanceEstimated: json['distance_estimated'] as bool? ?? false,
      riderId: json['rider_id'] as String?,
      senderId: json['sender_id'] as String?,
      agreedPrice: (json['agreed_price'] as num?)?.round(),
      acceptedAt: parseTime(json['accepted_at']),
      pickupDistanceKm: (json['pickup_distance_km'] as num?)?.toDouble(),
      pickupWindowMins: (json['pickup_window_mins'] as num?)?.toInt(),
      pickupDeadline: parseTime(json['pickup_deadline']),
      pickupArrivedAt: parseTime(json['pickup_arrived_at']),
      cancelReason: json['cancel_reason'] as String?,
      quoteBreakdown: breakdown is Map
          ? QuoteBreakdown.fromJson(breakdown.cast<String, dynamic>())
          : null,
      createdAt: parseTime(json['created_at']),
    );
  }

  final String id;
  final ServiceType serviceType;
  final String status;
  final String pickupAddress;
  final String dropoffAddress;
  final GeoPoint? pickupLocation;
  final GeoPoint? dropoffLocation;
  final String? receiverName;
  final double? distanceKm;
  final bool distanceEstimated;
  final String? riderId;
  final String? senderId;

  /// Whole KES, fixed at acceptance.
  final int? agreedPrice;
  final DateTime? acceptedAt;
  final double? pickupDistanceKm;
  final int? pickupWindowMins;
  final DateTime? pickupDeadline;
  final DateTime? pickupArrivedAt;

  /// `sender` / `rider` / `pickup_timeout`.
  final String? cancelReason;

  /// Present only if the server includes the agreed breakdown on the order.
  final QuoteBreakdown? quoteBreakdown;
  final DateTime? createdAt;

  bool get routeEditable => status == 'created';
  bool get isActiveJob => activeJobStatuses.contains(status);
  bool get isTerminal => terminalStatuses.contains(status);
  bool get arrivedAtPickup => pickupArrivedAt != null;

  /// Applies an `order.updated` realtime payload (only the keys it carries).
  Order applyUpdate(Map<String, dynamic> data) {
    T? pick<T>(String key, T? current, T? Function(Object?) parse) =>
        data.containsKey(key) ? parse(data[key]) : current;
    return copyWith(
      status: data['status'] is String ? data['status'] as String : status,
      agreedPrice: pick<int>(
        'agreed_price',
        agreedPrice,
        (v) => (v as num?)?.round(),
      ),
      pickupWindowMins: pick<int>(
        'pickup_window_mins',
        pickupWindowMins,
        (v) => (v as num?)?.toInt(),
      ),
      pickupDeadline: pick('pickup_deadline', pickupDeadline, parseTime),
      pickupArrivedAt: pick('pickup_arrived_at', pickupArrivedAt, parseTime),
      cancelReason: pick<String>(
        'cancel_reason',
        cancelReason,
        (v) => v as String?,
      ),
    );
  }

  Order copyWith({
    String? status,
    int? agreedPrice,
    int? pickupWindowMins,
    DateTime? pickupDeadline,
    DateTime? pickupArrivedAt,
    String? cancelReason,
  }) => Order(
    id: id,
    serviceType: serviceType,
    status: status ?? this.status,
    pickupAddress: pickupAddress,
    dropoffAddress: dropoffAddress,
    pickupLocation: pickupLocation,
    dropoffLocation: dropoffLocation,
    receiverName: receiverName,
    distanceKm: distanceKm,
    distanceEstimated: distanceEstimated,
    riderId: riderId,
    senderId: senderId,
    agreedPrice: agreedPrice ?? this.agreedPrice,
    acceptedAt: acceptedAt,
    pickupDistanceKm: pickupDistanceKm,
    pickupWindowMins: pickupWindowMins ?? this.pickupWindowMins,
    pickupDeadline: pickupDeadline ?? this.pickupDeadline,
    pickupArrivedAt: pickupArrivedAt ?? this.pickupArrivedAt,
    cancelReason: cancelReason ?? this.cancelReason,
    quoteBreakdown: quoteBreakdown,
    createdAt: createdAt,
  );
}

DateTime? parseTime(Object? v) => v is String ? DateTime.tryParse(v) : null;

class QuoteBreakdown {
  const QuoteBreakdown({
    required this.baseFare,
    required this.platformKm,
    required this.platformAmount,
    required this.riderKm,
    required this.riderRate,
    required this.riderAmount,
    required this.minimumFareApplied,
  });

  factory QuoteBreakdown.fromJson(Map<String, dynamic> json) => QuoteBreakdown(
    baseFare: (json['base_fare'] as num? ?? 0).round(),
    platformKm: (json['platform_km'] as num? ?? 0).toDouble(),
    platformAmount: (json['platform_amount'] as num? ?? 0).round(),
    riderKm: (json['rider_km'] as num? ?? 0).toDouble(),
    riderRate: json['rider_rate'] as num? ?? 0,
    riderAmount: (json['rider_amount'] as num? ?? 0).round(),
    minimumFareApplied: json['minimum_fare_applied'] as bool? ?? false,
  );

  final int baseFare;
  final double platformKm;
  final int platformAmount;
  final double riderKm;
  final num riderRate;
  final int riderAmount;
  final bool minimumFareApplied;

  Map<String, dynamic> toJson() => {
    'base_fare': baseFare,
    'platform_km': platformKm,
    'platform_amount': platformAmount,
    'rider_km': riderKm,
    'rider_rate': riderRate,
    'rider_amount': riderAmount,
    'minimum_fare_applied': minimumFareApplied,
  };
}

class RiderQuote {
  const RiderQuote({
    required this.riderId,
    required this.displayName,
    required this.hasPhoto,
    required this.ratingAverage,
    required this.ratingCount,
    required this.onTimeRate,
    required this.completed,
    required this.pickupDistanceKm,
    required this.pickupWindowMins,
    required this.total,
    required this.currency,
    required this.breakdown,
  });

  factory RiderQuote.fromJson(Map<String, dynamic> json) {
    final rating = (json['rating'] as Map?)?.cast<String, dynamic>() ?? {};
    final quote = (json['quote'] as Map?)?.cast<String, dynamic>() ?? {};
    return RiderQuote(
      riderId: json['rider_id'] as String,
      displayName: json['display_name'] as String? ?? '',
      hasPhoto: json['has_photo'] as bool? ?? false,
      ratingAverage: (rating['average'] as num? ?? 0).toDouble(),
      ratingCount: (rating['count'] as num? ?? 0).toInt(),
      onTimeRate: (json['on_time_rate'] as num?)?.toDouble(),
      completed: (json['completed'] as num?)?.toInt(),
      pickupDistanceKm: (json['pickup_distance_km'] as num? ?? 0).toDouble(),
      pickupWindowMins: (json['pickup_window_mins'] as num? ?? 0).toInt(),
      total: (quote['total'] as num? ?? 0).round(),
      currency: quote['currency'] as String? ?? 'KES',
      breakdown: QuoteBreakdown.fromJson(
        (quote['breakdown'] as Map?)?.cast<String, dynamic>() ?? {},
      ),
    );
  }

  final String riderId;
  final String displayName;
  final bool hasPhoto;
  final double ratingAverage;
  final int ratingCount;

  /// 0..1, null until the rider has pickups on record.
  final double? onTimeRate;
  final int? completed;
  final double pickupDistanceKm;
  final int pickupWindowMins;
  final int total;
  final String currency;
  final QuoteBreakdown breakdown;

  Map<String, dynamic> toJson() => {
    'rider_id': riderId,
    'display_name': displayName,
    'has_photo': hasPhoto,
    'rating': {'average': ratingAverage, 'count': ratingCount},
    'on_time_rate': onTimeRate,
    'completed': completed,
    'pickup_distance_km': pickupDistanceKm,
    'pickup_window_mins': pickupWindowMins,
    'quote': {
      'total': total,
      'currency': currency,
      'breakdown': breakdown.toJson(),
    },
  };
}

class RiderList {
  const RiderList({
    required this.tripDistanceKm,
    required this.distanceEstimated,
    required this.riders,
  });

  factory RiderList.fromJson(Map<String, dynamic> json) => RiderList(
    tripDistanceKm: (json['trip_distance_km'] as num?)?.toDouble(),
    distanceEstimated: json['distance_estimated'] as bool? ?? false,
    riders: [
      for (final r in (json['riders'] as List? ?? const []))
        RiderQuote.fromJson((r as Map).cast<String, dynamic>()),
    ],
  );

  final double? tripDistanceKm;
  final bool distanceEstimated;
  final List<RiderQuote> riders;
}

class Offer {
  const Offer({
    required this.id,
    required this.orderId,
    required this.riderId,
    required this.expiresAt,
    this.offeredAt,
    this.quotedTotal,
    this.pickupWindowMins,
  });

  factory Offer.fromJson(Map<String, dynamic> json) => Offer(
    id: json['id'] as String,
    orderId: json['order_id'] as String? ?? '',
    riderId: json['rider_id'] as String? ?? '',
    expiresAt: DateTime.parse(json['expires_at'] as String),
    offeredAt: json['offered_at'] is String
        ? DateTime.parse(json['offered_at'] as String)
        : null,
    quotedTotal: (json['quoted_total'] as num?)?.round(),
    pickupWindowMins: (json['pickup_window_mins'] as num?)?.toInt(),
  );

  final String id;
  final String orderId;
  final String riderId;
  final DateTime expiresAt;
  final DateTime? offeredAt;
  final int? quotedTotal;
  final int? pickupWindowMins;

  /// Decision window from server timestamps only, so phone clock skew doesn't matter.
  Duration? get serverWindow =>
      offeredAt == null ? null : expiresAt.difference(offeredAt!);

  Map<String, dynamic> toJson() => {
    'id': id,
    'order_id': orderId,
    'rider_id': riderId,
    'expires_at': expiresAt.toUtc().toIso8601String(),
    'offered_at': offeredAt?.toUtc().toIso8601String(),
    'quoted_total': quotedTotal,
    'pickup_window_mins': pickupWindowMins,
  };
}

/// The sender's view of one order (GET /orders/{id}, GET /orders/active): the order plus the
/// live offer while one is pending. The server is the only source of this state.
class SenderOrder {
  const SenderOrder({required this.order, this.offer, this.rider});

  factory SenderOrder.fromJson(Map<String, dynamic> json) {
    final order = Order.fromJson(json);
    final pending = json['pending_offer'];
    if (pending is Map && pending['offer'] is Map && pending['rider'] is Map) {
      try {
        return SenderOrder(
          order: order,
          offer: Offer.fromJson((pending['offer'] as Map).cast()),
          rider: RiderQuote.fromJson((pending['rider'] as Map).cast()),
        );
      } catch (_) {
        // A malformed offer is treated as none; the order itself is still valid.
      }
    }
    return SenderOrder(order: order);
  }

  final Order order;
  final Offer? offer;
  final RiderQuote? rider;

  bool get hasPendingOffer => offer != null && rider != null;
}
