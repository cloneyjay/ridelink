import '../../booking/data/booking_models.dart';

/// The boda boda verification checklist (auth-onboarding decisions 16, 24, 25).
enum DocType {
  riderPhoto('rider_photo'),
  nationalId('national_id'),
  drivingLicence('driving_licence'),
  policeClearance('police_clearance'),
  psvInsurance('psv_insurance'),
  logbookOrSaleAgreement('logbook_or_sale_agreement'),
  bikeRearPhoto('bike_rear_photo');

  const DocType(this.wire);
  final String wire;

  static DocType? fromWire(String? value) {
    for (final t in values) {
      if (t.wire == value) return t;
    }
    return null;
  }

  /// Shown as photos, so PDFs aren't accepted.
  bool get imageOnly => this == riderPhoto || this == bikeRearPhoto;

  /// Uploaded with the date it expires.
  bool get needsExpiry => this == psvInsurance || this == drivingLicence;

  /// Uploaded with the date it was issued (valid 12 months from issue).
  bool get needsIssueDate => this == policeClearance;
}

enum DocStatus {
  missing('missing'),
  pending('pending'),
  approved('approved'),
  rejected('rejected');

  const DocStatus(this.wire);
  final String wire;

  static DocStatus fromWire(String? value) => values.firstWhere(
    (s) => s.wire == value,
    orElse: () => DocStatus.missing,
  );
}

class DocumentState {
  const DocumentState({
    required this.type,
    required this.status,
    this.rejectionReason,
    this.expiresOn,
    this.current = false,
  });

  factory DocumentState.fromJson(Map<String, dynamic> json) => DocumentState(
    type: DocType.fromWire(json['doc_type'] as String?) ?? DocType.riderPhoto,
    status: DocStatus.fromWire(json['status'] as String?),
    rejectionReason: json['rejection_reason'] as String?,
    expiresOn: json['expires_on'] is String
        ? DateTime.tryParse(json['expires_on'] as String)
        : null,
    current: json['current'] as bool? ?? false,
  );

  final DocType type;
  final DocStatus status;
  final String? rejectionReason;

  /// Calendar date (no time).
  final DateTime? expiresOn;

  /// An approved, unexpired document of this type is in force.
  final bool current;

  bool get needsUpload =>
      status == DocStatus.missing || status == DocStatus.rejected;
}

enum VerificationStatus {
  pending('pending'),
  verified('verified'),
  rejected('rejected');

  const VerificationStatus(this.wire);
  final String wire;

  static VerificationStatus fromWire(String? value) => values.firstWhere(
    (s) => s.wire == value,
    orElse: () => VerificationStatus.pending,
  );
}

class Verification {
  const Verification({required this.status, required this.documents});

  factory Verification.fromJson(Map<String, dynamic> json) => Verification(
    status: VerificationStatus.fromWire(json['verification_status'] as String?),
    documents: [
      for (final d in (json['documents'] as List? ?? const []))
        DocumentState.fromJson((d as Map).cast<String, dynamic>()),
    ],
  );

  final VerificationStatus status;
  final List<DocumentState> documents;

  DocumentState documentFor(DocType type) => documents.firstWhere(
    (d) => d.type == type,
    orElse: () => DocumentState(type: type, status: DocStatus.missing),
  );

  /// Every checklist item has an upload that isn't rejected.
  bool get allSubmitted =>
      DocType.values.every((t) => !documentFor(t).needsUpload);

  /// Items without a document in force (missing, expired, or not yet approved).
  List<DocType> get notCurrent => [
    for (final t in DocType.values)
      if (!documentFor(t).current) t,
  ];
}

class RiderProfile {
  const RiderProfile({
    required this.id,
    required this.plateNumber,
    required this.isOnline,
    required this.verificationStatus,
    required this.pickupRadiusKm,
    required this.maxDistanceKm,
    required this.deliveryPricePerKm,
    required this.ridePricePerKm,
    required this.maxWeightKg,
    this.pausedUntil,
    this.pauseReason,
    this.pauseFailures = 0,
  });

  factory RiderProfile.fromJson(Map<String, dynamic> json) {
    double n(String k) => (json[k] as num? ?? 0).toDouble();
    return RiderProfile(
      id: json['id'] as String? ?? '',
      plateNumber: json['plate_number'] as String? ?? '',
      isOnline: json['is_online'] as bool? ?? false,
      verificationStatus: VerificationStatus.fromWire(
        json['verification_status'] as String?,
      ),
      pickupRadiusKm: n('pickup_radius_km'),
      maxDistanceKm: n('max_distance_km'),
      deliveryPricePerKm: n('delivery_price_per_km'),
      ridePricePerKm: n('ride_price_per_km'),
      maxWeightKg: n('max_weight_kg'),
      pausedUntil: parseTime(json['paused_until']),
      pauseReason: json['pause_reason'] as String?,
      pauseFailures: (json['pause_failures'] as num? ?? 0).toInt(),
    );
  }

  final String id;
  final String plateNumber;
  final bool isOnline;
  final VerificationStatus verificationStatus;
  final double pickupRadiusKm;
  final double maxDistanceKm;
  final double deliveryPricePerKm;
  final double ridePricePerKm;
  final double maxWeightKg;
  final DateTime? pausedUntil;
  final String? pauseReason;
  final int pauseFailures;

  bool pausedAt(DateTime now) =>
      pausedUntil != null && pausedUntil!.isAfter(now);

  RiderProfile copyWith({
    bool? isOnline,
    DateTime? pausedUntil,
    bool clearPause = false,
  }) => RiderProfile(
    id: id,
    plateNumber: plateNumber,
    isOnline: isOnline ?? this.isOnline,
    verificationStatus: verificationStatus,
    pickupRadiusKm: pickupRadiusKm,
    maxDistanceKm: maxDistanceKm,
    deliveryPricePerKm: deliveryPricePerKm,
    ridePricePerKm: ridePricePerKm,
    maxWeightKg: maxWeightKg,
    pausedUntil: clearPause ? null : (pausedUntil ?? this.pausedUntil),
    pauseReason: clearPause ? null : pauseReason,
    pauseFailures: pauseFailures,
  );
}

class RateRange {
  const RateRange(this.min, this.max);

  factory RateRange.fromJson(Object? json) {
    final m = json is Map ? json.cast<String, dynamic>() : const {};
    return RateRange(
      (m['min'] as num? ?? 0).toDouble(),
      (m['max'] as num? ?? 0).toDouble(),
    );
  }

  final double min;
  final double max;

  bool contains(double v) => v >= min && v <= max;
}

/// GET /riders/me/limits: the ranges the settings screen enforces.
class RiderLimits {
  const RiderLimits({
    required this.minMaxDistanceKm,
    required this.maxPickupRadiusKm,
    required this.defaultPickupRadiusKm,
    required this.deliveryRate,
    required this.rideRate,
  });

  factory RiderLimits.fromJson(Map<String, dynamic> json) => RiderLimits(
    minMaxDistanceKm: (json['min_max_distance_km'] as num? ?? 0).toDouble(),
    maxPickupRadiusKm: (json['max_pickup_radius_km'] as num? ?? 0).toDouble(),
    defaultPickupRadiusKm: (json['default_pickup_radius_km'] as num? ?? 0)
        .toDouble(),
    deliveryRate: RateRange.fromJson(json['delivery_rate']),
    rideRate: RateRange.fromJson(json['ride_rate']),
  );

  final double minMaxDistanceKm;
  final double maxPickupRadiusKm;
  final double defaultPickupRadiusKm;
  final RateRange deliveryRate;
  final RateRange rideRate;
}

class RiderSettingsInput {
  const RiderSettingsInput({
    required this.pickupRadiusKm,
    required this.maxDistanceKm,
    required this.deliveryPricePerKm,
    required this.ridePricePerKm,
    required this.maxWeightKg,
  });

  final double pickupRadiusKm;
  final double maxDistanceKm;
  final double deliveryPricePerKm;
  final double ridePricePerKm;
  final double maxWeightKg;

  Map<String, dynamic> toJson() => {
    'pickup_radius_km': pickupRadiusKm,
    'max_distance_km': maxDistanceKm,
    'delivery_price_per_km': deliveryPricePerKm,
    'ride_price_per_km': ridePricePerKm,
    'max_weight_kg': maxWeightKg,
  };
}

/// A pending offer as the rider sees it (screen 6), from GET /riders/me/active.
class RiderOffer {
  const RiderOffer({
    required this.id,
    required this.orderId,
    required this.expiresAt,
    required this.serviceType,
    required this.pickupAddress,
    required this.dropoffAddress,
    this.offeredAt,
    this.distanceKm,
    this.distanceEstimated = false,
    this.quotedTotal,
    this.breakdown,
    this.pickupDistanceKm,
    this.pickupWindowMins,
  });

  factory RiderOffer.fromJson(Map<String, dynamic> json) {
    final breakdown = json['quote_breakdown'];
    return RiderOffer(
      id: json['id'] as String? ?? '',
      orderId: json['order_id'] as String? ?? '',
      offeredAt: parseTime(json['offered_at']),
      expiresAt: parseTime(json['expires_at']) ?? DateTime.now(),
      serviceType:
          ServiceType.fromWire(json['service_type'] as String?) ??
          ServiceType.delivery,
      pickupAddress: json['pickup_address'] as String? ?? '',
      dropoffAddress: json['dropoff_address'] as String? ?? '',
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      distanceEstimated: json['distance_estimated'] as bool? ?? false,
      quotedTotal: (json['quoted_total'] as num?)?.round(),
      breakdown: breakdown is Map
          ? QuoteBreakdown.fromJson(breakdown.cast<String, dynamic>())
          : null,
      pickupDistanceKm: (json['pickup_distance_km'] as num?)?.toDouble(),
      pickupWindowMins: (json['pickup_window_mins'] as num?)?.toInt(),
    );
  }

  final String id;
  final String orderId;
  final DateTime? offeredAt;
  final DateTime expiresAt;
  final ServiceType serviceType;
  final String pickupAddress;
  final String dropoffAddress;
  final double? distanceKm;
  final bool distanceEstimated;
  final int? quotedTotal;
  final QuoteBreakdown? breakdown;
  final double? pickupDistanceKm;
  final int? pickupWindowMins;

  /// Decision window from server timestamps only, so phone clock skew doesn't matter.
  Duration get window {
    final w = offeredAt == null
        ? expiresAt.difference(DateTime.now())
        : expiresAt.difference(offeredAt!);
    return w.isNegative ? Duration.zero : w;
  }
}

class RiderActive {
  const RiderActive({this.offer, this.order});

  factory RiderActive.fromJson(Map<String, dynamic> json) => RiderActive(
    offer: json['offer'] is Map
        ? RiderOffer.fromJson((json['offer'] as Map).cast<String, dynamic>())
        : null,
    order: json['order'] is Map
        ? Order.fromJson((json['order'] as Map).cast<String, dynamic>())
        : null,
  );

  final RiderOffer? offer;
  final Order? order;
}
