/// The shared public-profile body from GET /senders/{id}/public-profile,
/// /riders/{id}/public-profile and /me/public-profile. The only place that parses it.
enum PublicProfileRole {
  sender('sender'),
  rider('rider');

  const PublicProfileRole(this.wire);
  final String wire;

  static PublicProfileRole fromWire(String? value) =>
      value == rider.wire ? rider : sender;
}

/// Wire keys inside `stats_30d` / `all_time`.
abstract final class PublicStatKey {
  static const orders = 'orders';
  static const paymentSuccessPct = 'payment_success_pct';
  static const cancellationPct = 'cancellation_pct';
  static const completed = 'completed';
  static const acceptPct = 'accept_pct';
  static const onTimePct = 'on_time_pct';
  static const disputePct = 'dispute_pct';
  static const positivePct = 'positive_pct';
}

abstract final class PublicBadge {
  static const verifiedRider = 'verified_rider';
}

class PublicRating {
  const PublicRating({required this.average, required this.count});

  factory PublicRating.fromJson(Map<String, dynamic> json) => PublicRating(
    average: (json['average'] as num? ?? 0).toDouble(),
    count: (json['count'] as num? ?? 0).toInt(),
  );

  final double average;
  final int count;
}

class PublicProfile {
  const PublicProfile({
    required this.role,
    required this.id,
    required this.firstName,
    required this.photoUrl,
    required this.joinedAt,
    required this.badges,
    required this.newOnRideLink,
    required this.stats30d,
    required this.allTime,
    this.rating,
    this.terms,
    this.computedAt,
  });

  factory PublicProfile.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> obj(Object? v) =>
        v is Map ? v.cast<String, dynamic>() : const {};
    final rating = json['rating'];
    final terms = json['terms'];
    return PublicProfile(
      role: PublicProfileRole.fromWire(json['role'] as String?),
      id: json['id'] as String? ?? '',
      firstName: json['first_name'] as String? ?? '',
      photoUrl: json['photo_url'] as String?,
      joinedAt: _time(json['joined_at']),
      badges: [
        for (final b in (json['badges'] as List? ?? const []))
          if (b is String) b,
      ],
      newOnRideLink: json['new_on_ridelink'] as bool? ?? false,
      stats30d: {
        for (final e in obj(json['stats_30d']).entries)
          e.key: (e.value as num?)?.round(),
      },
      allTime: {
        for (final e in obj(json['all_time']).entries)
          e.key: (e.value as num? ?? 0).round(),
      },
      rating: rating is Map
          ? PublicRating.fromJson(rating.cast<String, dynamic>())
          : null,
      terms: terms is Map ? terms.cast<String, dynamic>() : null,
      computedAt: _time(json['computed_at']),
    );
  }

  static DateTime? _time(Object? v) =>
      v is String ? DateTime.tryParse(v) : null;

  final PublicProfileRole role;
  final String id;
  final String firstName;

  /// The Go photo endpoint URL for either role (`/v1/riders/{id}/photo` or
  /// `/v1/senders/{id}/photo`), or null when there is no photo. Only its
  /// presence is used; bytes load through the authenticated client.
  final String? photoUrl;
  final DateTime? joinedAt;
  final List<String> badges;
  final bool newOnRideLink;

  /// Whole-number percentages 0–100; null below the server's minimum sample.
  final Map<String, int?> stats30d;
  final Map<String, int> allTime;
  final PublicRating? rating;

  /// Rider price terms, passed through unparsed (screen 3 shows the trip's quote).
  final Map<String, dynamic>? terms;
  final DateTime? computedAt;

  bool get isVerifiedRider => badges.contains(PublicBadge.verifiedRider);

  int _count(String key) => stats30d[key] ?? 0;

  int get orders30d => _count(PublicStatKey.orders);
  int? get paymentSuccessPct => stats30d[PublicStatKey.paymentSuccessPct];
  int? get cancellationPct => stats30d[PublicStatKey.cancellationPct];
  int get ordersAllTime => allTime[PublicStatKey.orders] ?? 0;

  int get completed30d => _count(PublicStatKey.completed);
  int? get acceptPct => stats30d[PublicStatKey.acceptPct];
  int? get onTimePct => stats30d[PublicStatKey.onTimePct];
  int? get disputePct => stats30d[PublicStatKey.disputePct];
  int? get positivePct => stats30d[PublicStatKey.positivePct];
  int get completedAllTime => allTime[PublicStatKey.completed] ?? 0;
}
