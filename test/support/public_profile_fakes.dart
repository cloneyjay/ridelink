import 'dart:async';
import 'dart:typed_data';

import 'package:ridelink/core/api/api_exception.dart';
import 'package:ridelink/features/profile/public/public_profile_models.dart';
import 'package:ridelink/features/profile/public/public_profile_repository.dart';

/// The sender body from docs/notes/public-profiles-spec.md ("Shared response shape").
Map<String, dynamic> senderProfileJson({
  String id = 'sender-1',
  int? paymentPct = 100,
  int? cancelPct = 8,
  int orders30d = 12,
  int ordersAllTime = 47,
  bool newOnRideLink = false,
  String joinedAt = '2026-10-01T00:00:00Z',
  bool hasPhoto = true,
}) => {
  'role': 'sender',
  'id': id,
  'first_name': 'Wanjiru',
  'photo_url': hasPhoto ? 'http://test.local/v1/senders/$id/photo' : null,
  'joined_at': joinedAt,
  'badges': <String>[],
  'new_on_ridelink': newOnRideLink,
  'stats_30d': {
    'orders': orders30d,
    'payment_success_pct': paymentPct,
    'cancellation_pct': cancelPct,
  },
  'all_time': {'orders': ordersAllTime},
  'computed_at': '2026-10-27T02:00:00Z',
};

Map<String, dynamic> riderProfileJson({
  String id = 'rider-1',
  bool verified = true,
  int? onTimePct = 98,
  int completed30d = 40,
  int completedAllTime = 340,
  double ratingAverage = 4.8,
  int ratingCount = 120,
}) => {
  'role': 'rider',
  'id': id,
  'first_name': 'Moses',
  'photo_url': null,
  'joined_at': '2026-10-01T00:00:00Z',
  'badges': [if (verified) 'verified_rider'],
  'new_on_ridelink': false,
  'stats_30d': {
    'completed': completed30d,
    'accept_pct': 90,
    'on_time_pct': onTimePct,
    'dispute_pct': 0,
    'positive_pct': 97,
  },
  'all_time': {'completed': completedAllTime},
  'rating': {'average': ratingAverage, 'count': ratingCount},
  'terms': {'delivery_price_per_km': 16},
  'computed_at': '2026-10-27T02:00:00Z',
};

PublicProfile senderProfileFixture({
  String id = 'sender-1',
  int? paymentPct = 100,
  int? cancelPct = 8,
  bool newOnRideLink = false,
}) => PublicProfile.fromJson(
  senderProfileJson(
    id: id,
    paymentPct: paymentPct,
    cancelPct: cancelPct,
    newOnRideLink: newOnRideLink,
  ),
);

PublicProfile riderPublicProfileFixture({String id = 'rider-1'}) =>
    PublicProfile.fromJson(riderProfileJson(id: id));

ApiException notFound() =>
    const ApiException(statusCode: 404, message: 'not found');

class FakePublicProfileRepository implements PublicProfileRepository {
  FakePublicProfileRepository({
    Map<String, PublicProfile>? senders,
    Map<String, PublicProfile>? riders,
    Map<PublicProfileRole, PublicProfile>? mineByRole,
  }) : senders = senders ?? {'sender-1': senderProfileFixture()},
       riders = riders ?? {'rider-1': riderPublicProfileFixture()},
       mineByRole =
           mineByRole ??
           {
             PublicProfileRole.sender: senderProfileFixture(id: 'user-1'),
             PublicProfileRole.rider: riderPublicProfileFixture(id: 'user-1'),
           };

  final Map<String, PublicProfile> senders;
  final Map<String, PublicProfile> riders;
  final Map<PublicProfileRole, PublicProfile> mineByRole;

  /// When set, every sender call waits on it (slow network).
  Completer<void>? senderGate;
  Object? senderError;
  Object? riderError;
  Object? mineError;

  final senderCalls = <String>[];
  final senderPhotoCalls = <String>[];
  Uint8List? senderPhotoBytes;
  Object? senderPhotoError;
  final riderCalls = <String>[];
  final mineCalls = <PublicProfileRole>[];

  @override
  Future<PublicProfile> sender(String id) async {
    senderCalls.add(id);
    if (senderGate != null) await senderGate!.future;
    if (senderError != null) throw senderError!;
    return senders[id] ?? (throw notFound());
  }

  @override
  Future<Uint8List?> senderPhoto(String id) async {
    senderPhotoCalls.add(id);
    if (senderPhotoError != null) throw senderPhotoError!;
    return senderPhotoBytes;
  }

  @override
  Future<PublicProfile> rider(String id) async {
    riderCalls.add(id);
    if (riderError != null) throw riderError!;
    return riders[id] ?? (throw notFound());
  }

  @override
  Future<PublicProfile> mine(PublicProfileRole role) async {
    mineCalls.add(role);
    if (mineError != null) throw mineError!;
    return mineByRole[role] ?? (throw notFound());
  }
}
