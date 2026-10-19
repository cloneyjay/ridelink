import 'package:flutter_test/flutter_test.dart';
import 'package:ridelink/core/api/api_client.dart';
import 'package:ridelink/core/api/api_exception.dart';
import 'package:ridelink/core/auth/access_token_source.dart';
import 'package:ridelink/core/config/app_config.dart';
import 'package:ridelink/core/location/geo_point.dart';
import 'package:ridelink/features/booking/data/booking_models.dart';
import 'package:ridelink/features/booking/data/booking_repository.dart';
import 'package:ridelink/features/shell/account_repository.dart';

import '../../support/booking_fakes.dart';
import '../../support/fakes.dart';

void main() {
  late FakeAdapter adapter;

  ApiClient client(Map<String, FakeHandler> routes) {
    adapter = FakeAdapter(routeHandler(routes));
    return ApiClient(
      AppConfig(apiBaseUrl: Uri.parse('http://test.local')),
      tokens: _StaticTokens(),
      adapter: adapter,
    );
  }

  test('autocomplete sends input, session token and bias point', () async {
    final repo = ApiBookingRepository(
      client({
        'places/autocomplete': (_) => jsonResponse(200, {
          'predictions': [
            {
              'place_id': 'p1',
              'primary_text': 'Westlands Mall',
              'secondary_text': 'Nairobi',
            },
          ],
        }),
      }),
    );
    final results = await repo.autocomplete(
      input: 'West',
      sessionToken: 'tok',
      near: const GeoPoint(-1.26, 36.8),
    );
    expect(results.single.primaryText, 'Westlands Mall');
    final q = adapter.requests.single.uri.queryParameters;
    expect(q, {
      'input': 'West',
      'session_token': 'tok',
      'lat': '-1.26',
      'lng': '36.8',
    });
    expect(adapter.requests.single.headers['Authorization'], 'Bearer access-1');
  });

  test('503 from places becomes MapsUnavailableException', () async {
    final repo = ApiBookingRepository(
      client({
        'places/autocomplete': (_) =>
            jsonResponse(503, {'error': 'maps not configured'}),
        'places/details': (_) =>
            jsonResponse(503, {'error': 'maps not configured'}),
      }),
    );
    await expectLater(
      repo.autocomplete(input: 'We', sessionToken: 't'),
      throwsA(isA<MapsUnavailableException>()),
    );
    await expectLater(
      repo.placeDetails(placeId: 'p', sessionToken: 't'),
      throwsA(isA<MapsUnavailableException>()),
    );
  });

  test('details passes the same session token', () async {
    final repo = ApiBookingRepository(
      client({
        'places/details': (_) => jsonResponse(200, {
          'place_id': 'p1',
          'name': 'Westlands Mall',
          'address': 'Waiyaki Way, Nairobi',
          'location': {'lat': -1.26, 'lng': 36.8},
        }),
      }),
    );
    final place = await repo.placeDetails(placeId: 'p1', sessionToken: 'tok');
    expect(place.location, const GeoPoint(-1.26, 36.8));
    expect(adapter.requests.single.uri.queryParameters, {
      'place_id': 'p1',
      'session_token': 'tok',
    });
  });

  test('create order posts the contract body and parses distance', () async {
    final repo = ApiBookingRepository(
      client({
        'orders': (_) => jsonResponse(201, {
          'id': 'order-1',
          'service_type': 'ride',
          'status': 'created',
          'pickup_address': 'A',
          'dropoff_address': 'B',
          'distance_km': 4.83,
          'distance_estimated': true,
        }),
      }),
    );
    final order = await repo.createOrder(
      CreateOrderInput(
        serviceType: ServiceType.ride,
        route: const RouteInput(pickup: westlands, dropoff: cbd),
      ),
    );
    expect(order.distanceKm, 4.83);
    expect(order.distanceEstimated, isTrue);
    expect(order.routeEditable, isTrue);
    final body = adapter.requests.single.data as Map;
    expect(body['service_type'], 'ride');
    expect(body.containsKey('declaration'), isFalse);
  });

  test('route edit, offer and cancel hit the right endpoints', () async {
    Map<String, dynamic> order(String status) => {
      'id': 'order-1',
      'service_type': 'delivery',
      'status': status,
      'pickup_address': 'A',
      'dropoff_address': 'B',
    };
    final repo = ApiBookingRepository(
      client({
        'orders/order-1/route': (_) => jsonResponse(200, order('created')),
        'orders/order-1/offer': (_) => jsonResponse(201, {
          'id': 'offer-1',
          'order_id': 'order-1',
          'rider_id': 'r1',
          'offered_at': '2026-10-13T09:42:00Z',
          'expires_at': '2026-10-13T09:43:00Z',
        }),
        'orders/order-1/status': (_) => jsonResponse(200, order('cancelled')),
      }),
    );
    await repo.updateRoute(
      'order-1',
      const RouteInput(pickup: westlands, dropoff: cbd),
    );
    final offer = await repo.sendOffer(orderId: 'order-1', riderId: 'r1');
    final cancelled = await repo.cancelOrder('order-1');
    expect(offer.serverWindow, const Duration(seconds: 60));
    expect(cancelled.status, 'cancelled');
    expect(adapter.requests.map((r) => '${r.method} ${r.uri.path}'), [
      'PATCH /v1/orders/order-1/route',
      'POST /v1/orders/order-1/offer',
      'PATCH /v1/orders/order-1/status',
    ]);
    expect(adapter.requests[1].data, {'rider_id': 'r1'});
    expect(adapter.requests[2].data, {'status': 'cancelled'});
  });

  test('rider photo returns bytes, or null on 404', () async {
    final repo = ApiBookingRepository(client({}));
    expect(await repo.riderPhoto('missing'), isNull);
  });

  test('item categories parse code and status', () async {
    final repo = ApiBookingRepository(
      client({
        'item-categories': (_) => jsonResponse(200, {
          'categories': [
            {
              'id': 'c1',
              'code': 'documents',
              'status': 'allowed',
              'requires_extra_check': false,
            },
          ],
        }),
      }),
    );
    final cats = await repo.itemCategories();
    expect(cats.single.code, 'documents');
  });

  group('AccountRepository.isRider', () {
    test('200 is a rider', () async {
      final repo = ApiAccountRepository(
        client({
          'riders/me': (_) => jsonResponse(200, {'id': 'r1'}),
        }),
      );
      expect(await repo.isRider(), isTrue);
    });

    test('404 is not a rider', () async {
      final repo = ApiAccountRepository(client({}));
      expect(await repo.isRider(), isFalse);
    });

    test('other errors propagate', () async {
      final repo = ApiAccountRepository(
        client({
          'riders/me': (_) => jsonResponse(500, {'error': 'x'}),
        }),
      );
      await expectLater(repo.isRider(), throwsA(isA<ApiException>()));
    });
  });
}

class _StaticTokens implements AccessTokenSource {
  @override
  String? get accessToken => 'access-1';

  @override
  bool get hasSession => true;

  @override
  Future<bool> refresh() async => false;
}
