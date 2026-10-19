import 'package:flutter_test/flutter_test.dart';
import 'package:ridelink/core/format/money.dart';
import 'package:ridelink/core/format/uuid.dart';
import 'package:ridelink/core/realtime/realtime_event.dart';
import 'package:ridelink/features/booking/booking_labels.dart';
import 'package:ridelink/features/booking/data/booking_models.dart';
import 'package:ridelink/features/booking/data/place_search_session.dart';
import 'package:ridelink/features/booking/offer_waiting_screen.dart';
import 'package:ridelink/features/booking/order_form.dart';
import 'package:ridelink/features/booking/rider_list_screen.dart';
import 'package:ridelink/l10n/app_localizations_en.dart';

import '../../support/booking_fakes.dart';

void main() {
  final l = AppLocalizationsEn();

  group('money and distance formatting', () {
    test('KES amounts have a space, grouping and no decimals', () {
      expect(formatKes(350), 'KES 350');
      expect(formatKes(1200), 'KES 1,200');
      expect(formatKes(349.6), 'KES 350');
      expect(formatKesEstimate(350), 'KES ~350');
    });

    test('rates keep cents only when present', () {
      expect(formatKesRate(16), 'KES 16');
      expect(formatKesRate(16.5), 'KES 16.50');
    });

    test('km to one decimal, whole numbers without one', () {
      expect(formatKm(4.83), '4.8 km');
      expect(formatKm(10), '10 km');
      expect(formatKm(0.04), '0 km');
    });
  });

  test('uuidV4 is a well-formed, random v4 UUID', () {
    final pattern = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    );
    final a = uuidV4();
    expect(a, matches(pattern));
    expect(uuidV4(), isNot(a));
  });

  group('PlaceSearchSession token lifecycle', () {
    late FakeBookingRepository repo;
    late int minted;
    late PlaceSearchSession session;

    setUp(() {
      repo = FakeBookingRepository();
      minted = 0;
      session = PlaceSearchSession(repo, newToken: () => 'token-${++minted}');
    });

    test('no token and no call under 2 characters', () async {
      expect(await session.search(' W '), isEmpty);
      expect(repo.autocompleteCalls, isEmpty);
      expect(session.token, isNull);
    });

    test(
      'one token reused for every autocomplete and the details call',
      () async {
        await session.search('We');
        await session.search('West');
        final results = await session.search('Westlands');
        expect(repo.autocompleteCalls.map((c) => c.token), [
          'token-1',
          'token-1',
          'token-1',
        ]);
        final place = await session.select(results.first);
        expect(place.placeId, 'p-westlands');
        expect(repo.detailsCalls.single.token, 'token-1');
        expect(session.token, isNull, reason: 'discarded after details');
      },
    );

    test('a new search after selecting starts a new token', () async {
      final r = await session.search('Moi');
      await session.select(r.first);
      await session.search('West');
      expect(repo.autocompleteCalls.last.token, 'token-2');
    });

    test('token is discarded even when details fail', () async {
      repo.detailsError = Exception('boom');
      final r = await session.search('Moi');
      await expectLater(session.select(r.first), throwsException);
      expect(session.token, isNull);
    });

    test('discard ends the session without a details call', () async {
      await session.search('Moi');
      session.discard();
      expect(session.token, isNull);
      expect(repo.detailsCalls, isEmpty);
    });
  });

  group('order form validation', () {
    test('receiver name is required (trimmed)', () {
      expect(validateReceiverName('   ', l), l.errorReceiverRequired);
      expect(validateReceiverName(null, l), l.errorReceiverRequired);
      expect(validateReceiverName(' Grace ', l), isNull);
    });

    test('description is required', () {
      expect(validateDescription('', l), l.errorDescriptionRequired);
      expect(validateDescription('Sealed envelope', l), isNull);
    });

    test('weight is optional but must be above zero', () {
      expect(validateWeight('', l), isNull);
      expect(validateWeight('0.5', l), isNull);
      expect(validateWeight('0,5', l), isNull);
      expect(validateWeight('0', l), l.errorWeightInvalid);
      expect(validateWeight('-2', l), l.errorWeightInvalid);
      expect(validateWeight('abc', l), l.errorWeightInvalid);
    });

    test('value band and category are required', () {
      expect(validateValueBand(null, l), l.errorValueBandRequired);
      expect(validateValueBand(ValueBand.under500, l), isNull);
      expect(validateCategory(null, l), l.errorCategoryRequired);
      expect(validateCategory('cat-docs', l), isNull);
    });

    test('value band wire values and labels match the contract', () {
      expect(ValueBand.values.map((b) => b.wire), [
        'under_500',
        '500_to_2000',
        '2000_to_5000',
        '5000_to_10000',
      ]);
      expect(ValueBand.values.map((b) => valueBandLabel(l, b)), [
        'Under KES 500',
        'KES 500–2,000',
        'KES 2,000–5,000',
        'KES 5,000–10,000',
      ]);
    });

    test('delivery body carries receiver and declaration, never a phone', () {
      final json = buildCreateOrderInput(
        service: ServiceType.delivery,
        pickup: westlands,
        dropoff: cbd,
        receiverName: '  Grace Wanjiku ',
        categoryId: 'cat-docs',
        description: ' Sealed envelope ',
        weightText: '0,5',
        valueBand: ValueBand.from500To2000,
      ).toJson();
      expect(json['service_type'], 'delivery');
      expect(json['receiver_name'], 'Grace Wanjiku');
      expect(json['pickup_address'], 'Westlands Mall, Waiyaki Way, Nairobi');
      expect(json['pickup_location'], {'lat': -1.2648, 'lng': 36.8025});
      expect(json['declaration'], {
        'category_id': 'cat-docs',
        'description': 'Sealed envelope',
        'weight_kg': 0.5,
        'value_band': '500_to_2000',
      });
      expect(json.keys.where((k) => k.contains('phone')), isEmpty);
    });

    test('weight is omitted when blank', () {
      final json = buildCreateOrderInput(
        service: ServiceType.delivery,
        pickup: westlands,
        dropoff: cbd,
        receiverName: 'Grace',
        categoryId: 'cat-docs',
        description: 'Keys',
        weightText: '',
        valueBand: ValueBand.under500,
      ).toJson();
      expect((json['declaration'] as Map).containsKey('weight_kg'), isFalse);
    });

    test('ride body has only the route', () {
      final json = buildCreateOrderInput(
        service: ServiceType.ride,
        pickup: westlands,
        dropoff: cbd,
      ).toJson();
      expect(json.keys, {
        'service_type',
        'pickup_address',
        'dropoff_address',
        'pickup_location',
        'dropoff_location',
      });
      expect(json['service_type'], 'ride');
    });
  });

  test('sortRiders by price or distance with the other as tie-break', () {
    final a = riderFixture(id: 'a', total: 300, pickupKm: 0.5);
    final b = riderFixture(id: 'b', total: 200, pickupKm: 2.0);
    final c = riderFixture(id: 'c', total: 200, pickupKm: 1.0);
    expect(sortRiders([a, b, c], RiderSort.price).map((r) => r.riderId), [
      'c',
      'b',
      'a',
    ]);
    expect(sortRiders([a, b, c], RiderSort.distance).map((r) => r.riderId), [
      'a',
      'c',
      'b',
    ]);
  });

  group('parsing', () {
    test('rider list from the contract JSON', () {
      final list = RiderList.fromJson({
        'trip_distance_km': 4.83,
        'distance_estimated': true,
        'riders': [
          {
            'rider_id': 'r1',
            'display_name': 'Moses O.',
            'has_photo': true,
            'rating': {'average': 4.9, 'count': 120},
            'on_time_rate': null,
            'completed': null,
            'pickup_distance_km': 0.81,
            'pickup_window_mins': 10,
            'quote': {
              'total': 214,
              'currency': 'KES',
              'breakdown': {
                'base_fare': 80,
                'platform_km': 4.83,
                'platform_amount': 77,
                'rider_km': 0,
                'rider_rate': 16.5,
                'rider_amount': 0,
                'minimum_fare_applied': false,
              },
            },
          },
        ],
      });
      expect(list.distanceEstimated, isTrue);
      final r = list.riders.single;
      expect(r.onTimeRate, isNull);
      expect(r.completed, isNull);
      expect(r.total, 214);
      expect(r.breakdown.riderRate, 16.5);
    });

    test('offer window comes from server timestamps', () {
      final offer = Offer.fromJson({
        'id': 'o1',
        'order_id': 'order-1',
        'rider_id': 'r1',
        'offered_at': '2026-10-13T09:42:00Z',
        'expires_at': '2026-10-13T09:43:00Z',
        'quoted_total': 214,
        'pickup_window_mins': 10,
      });
      expect(offer.serverWindow, const Duration(seconds: 60));
      expect(offer.quotedTotal, 214);
    });
  });

  group('labels', () {
    test('categories localize by code with a readable fallback', () {
      expect(categoryLabel(l, 'documents'), 'Documents');
      expect(categoryLabel(l, 'spare_parts'), 'Spare parts');
    });

    test('initials from "First L." names', () {
      expect(initialsOf('Moses O.'), 'MO');
      expect(initialsOf('grace'), 'G');
      expect(initialsOf(''), '');
    });
  });

  group('outcomeFromEvent', () {
    RealtimeEvent ev(String type, Map<String, dynamic> data) => RealtimeEvent(
      type: type,
      kind: RealtimeEventKind.fromWire(type),
      data: data,
    );
    OfferOutcome? outcome(RealtimeEvent e) =>
        outcomeFromEvent(e, offerId: 'offer-1', orderId: 'order-1');

    test('offer.resolved outcomes for this offer', () {
      for (final (wire, expected) in [
        ('accepted', OfferOutcome.accepted),
        ('declined', OfferOutcome.declined),
        ('expired', OfferOutcome.expired),
      ]) {
        expect(
          outcome(
            ev('offer.resolved', {
              'offer_id': 'offer-1',
              'order_id': 'order-1',
              'outcome': wire,
            }),
          ),
          expected,
        );
      }
    });

    test('ignores other offers and unrelated events', () {
      expect(
        outcome(
          ev('offer.resolved', {
            'offer_id': 'offer-9',
            'order_id': 'order-1',
            'outcome': 'accepted',
          }),
        ),
        isNull,
      );
      expect(
        outcome(ev('notification.created', {'order_id': 'order-1'})),
        isNull,
      );
      expect(
        outcome(
          ev('order.updated', {'order_id': 'order-1', 'status': 'offered'}),
        ),
        isNull,
      );
    });

    test('order.updated accepted or cancelled resolves too', () {
      expect(
        outcome(
          ev('order.updated', {'order_id': 'order-1', 'status': 'accepted'}),
        ),
        OfferOutcome.accepted,
      );
      expect(
        outcome(
          ev('order.updated', {'order_id': 'order-1', 'status': 'cancelled'}),
        ),
        OfferOutcome.cancelled,
      );
    });
  });
}
