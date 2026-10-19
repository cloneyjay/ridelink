import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridelink/core/api/api_client.dart';
import 'package:ridelink/core/auth/access_token_source.dart';
import 'package:ridelink/core/config/app_config.dart';
import 'package:ridelink/features/booking/data/booking_repository.dart';
import 'package:ridelink/features/rider/data/rider_models.dart';
import 'package:ridelink/features/rider/data/rider_repository.dart';

import '../../support/fakes.dart';

Map<String, dynamic> _order(String status) => {
  'id': 'o1',
  'service_type': 'delivery',
  'status': status,
  'pickup_address': 'A',
  'dropoff_address': 'B',
  'agreed_price': 214,
};

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

  test('me returns null on 404', () async {
    final repo = ApiRiderRepository(client({}));
    expect(await repo.me(), isNull);
  });

  test('register sends boda boda and the plate', () async {
    final repo = ApiRiderRepository(
      client({
        'riders': (_) => jsonResponse(201, {
          'id': 'r1',
          'plate_number': 'KMFA 123B',
          'verification_status': 'pending',
        }),
      }),
    );
    final p = await repo.register(plateNumber: 'KMFA 123B');
    expect(p.verificationStatus, VerificationStatus.pending);
    expect(adapter.requests.single.data, {
      'vehicle_type': 'boda_boda',
      'plate_number': 'KMFA 123B',
    });
  });

  test('document upload is multipart with doc_type, date and file', () async {
    final repo = ApiRiderRepository(
      client({
        'riders/me/documents': (_) => jsonResponse(201, {
          'doc_type': 'psv_insurance',
          'status': 'pending',
          'expires_on': '2027-03-01',
          'current': false,
        }),
      }),
    );
    final doc = await repo.uploadDocument(
      type: DocType.psvInsurance,
      bytes: [1, 2, 3],
      fileName: 'psv.pdf',
      expiresOn: DateTime(2027, 3, 1),
    );
    expect(doc.status, DocStatus.pending);
    final form = adapter.requests.single.data as FormData;
    expect(Map.fromEntries(form.fields), {
      'doc_type': 'psv_insurance',
      'expires_on': '2027-03-01',
    });
    expect(form.files.single.key, 'file');
    expect(form.files.single.value.filename, 'psv.pdf');
  });

  test('online, settings and location payloads', () async {
    final rider = {'id': 'r1', 'is_online': true};
    final repo = ApiRiderRepository(
      client({
        'riders/me/online': (_) => jsonResponse(200, rider),
        'riders/me/settings': (_) => jsonResponse(200, rider),
        'riders/me/location': (_) => jsonResponse(200, {'message': 'ok'}),
      }),
    );
    await repo.setOnline(true);
    await repo.updateSettings(
      const RiderSettingsInput(
        pickupRadiusKm: 2,
        maxDistanceKm: 12,
        deliveryPricePerKm: 18,
        ridePricePerKm: 20,
        maxWeightKg: 15,
      ),
    );
    expect(adapter.requests[0].data, {'online': true});
    expect(adapter.requests[1].method, 'PATCH');
    expect((adapter.requests[1].data as Map)['max_distance_km'], 12);
  });

  test('job and cash endpoints hit the contract paths', () async {
    final repo = ApiRiderRepository(
      client({
        'orders/o1/offer/accept': (_) => jsonResponse(200, _order('accepted')),
        'orders/o1/pickup/arrived': (_) =>
            jsonResponse(200, _order('accepted')),
        'orders/o1/status': (_) => jsonResponse(200, _order('started')),
        'orders/o1/payment/request': (_) =>
            jsonResponse(200, _order('payment_requested')),
        'orders/o1/payment/received': (_) => jsonResponse(200, _order('paid')),
        'orders/o1/payment/not-received': (_) =>
            jsonResponse(200, _order('unresolved')),
      }),
    );
    expect((await repo.acceptOffer('o1')).agreedPrice, 214);
    await repo.markArrived('o1');
    await repo.updateStatus('o1', 'started');
    expect((await repo.requestPayment('o1')).status, 'payment_requested');
    expect((await repo.paymentReceived('o1')).status, 'paid');
    expect((await repo.paymentNotReceived('o1')).status, 'unresolved');
    expect(adapter.requests[2].data, {'status': 'started'});
  });

  test('active parses offer and order; limits parse', () async {
    final repo = ApiRiderRepository(
      client({
        'riders/me/active': (_) =>
            jsonResponse(200, {'offer': null, 'order': _order('in_transit')}),
        'riders/me/limits': (_) => jsonResponse(200, {
          'min_max_distance_km': 10,
          'max_pickup_radius_km': 3,
          'default_pickup_radius_km': 1.8,
          'delivery_rate': {'min': 16, 'max': 32},
          'ride_rate': {'min': 16, 'max': 32},
        }),
      }),
    );
    final active = await repo.active();
    expect(active.offer, isNull);
    expect(active.order!.status, 'in_transit');
    expect((await repo.limits()).maxPickupRadiusKm, 3);
  });

  test('sender cash confirmation posts payment/sent', () async {
    final repo = ApiBookingRepository(
      client({
        'orders/o1/payment/sent': (_) =>
            jsonResponse(200, _order('cash_pending')),
        'orders': (_) => jsonResponse(200, {
          'orders': [_order('accepted')],
        }),
      }),
    );
    expect((await repo.confirmPaymentSent('o1')).status, 'cash_pending');
    expect((await repo.myOrders()).single.isActiveJob, isTrue);
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
