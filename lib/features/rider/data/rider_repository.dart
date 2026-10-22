import 'package:intl/intl.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/location/geo_point.dart';
import '../../booking/data/booking_models.dart';
import '../../payments/data/payment_models.dart';
import 'rider_models.dart';

/// Every call the rider side makes to the Go server.
abstract class RiderRepository {
  /// Null when the user has no rider profile (404).
  Future<RiderProfile?> me();

  Future<RiderProfile> register({required String plateNumber});

  Future<Verification> verification();

  Future<DocumentState> uploadDocument({
    required DocType type,
    required List<int> bytes,
    required String fileName,
    DateTime? expiresOn,
    DateTime? issuedOn,
  });

  Future<RiderLimits> limits();

  Future<RiderProfile> updateSettings(RiderSettingsInput input);

  Future<RiderProfile> setOnline(bool online);

  Future<void> updateLocation(GeoPoint point);

  Future<RiderActive> active();

  Future<List<Order>> myOrders();

  Future<Order> acceptOffer(String orderId);

  Future<void> declineOffer(String orderId);

  Future<Order> markArrived(String orderId);

  /// PATCH /orders/{id}/status for started, in_transit, handed_over, completed.
  Future<Order> updateStatus(String orderId, String status);

  Future<Order> cancel(String orderId);

  /// Arrived at the drop-off and request payment in one step (in_transit -> payment_requested).
  Future<Order> requestPayment(String orderId);

  /// Records the payment and completes the order (payment_requested -> completed).
  Future<Order> paymentReceived(
    String orderId, {
    required PayMethod method,
    String? mpesaCode,
  });

  Future<Order> paymentNotReceived(String orderId);

  /// The rider's own M-Pesa methods with full numbers (cash is implicit).
  Future<List<PaymentMethod>> paymentMethods();

  /// Adds or replaces the method of [type]; [number] is already normalized.
  Future<PaymentMethod> savePaymentMethod(
    PayMethod type, {
    required String number,
    required String accountName,
  });

  Future<void> deletePaymentMethod(PayMethod type);
}

final _date = DateFormat('yyyy-MM-dd');

class ApiRiderRepository implements RiderRepository {
  ApiRiderRepository(this._api);

  final ApiClient _api;

  static Map<String, dynamic> _map(Object? data) =>
      (data as Map).cast<String, dynamic>();

  @override
  Future<RiderProfile?> me() async {
    try {
      return RiderProfile.fromJson(_map(await _api.get('riders/me')));
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  @override
  Future<RiderProfile> register({required String plateNumber}) async =>
      RiderProfile.fromJson(
        _map(
          await _api.post(
            'riders',
            data: {'vehicle_type': 'boda_boda', 'plate_number': plateNumber},
          ),
        ),
      );

  @override
  Future<Verification> verification() async =>
      Verification.fromJson(_map(await _api.get('riders/me/verification')));

  @override
  Future<DocumentState> uploadDocument({
    required DocType type,
    required List<int> bytes,
    required String fileName,
    DateTime? expiresOn,
    DateTime? issuedOn,
  }) async => DocumentState.fromJson(
    _map(
      await _api.postMultipart(
        'riders/me/documents',
        fields: {
          'doc_type': type.wire,
          if (expiresOn != null) 'expires_on': _date.format(expiresOn),
          if (issuedOn != null) 'issued_on': _date.format(issuedOn),
        },
        fileBytes: bytes,
        fileName: fileName,
      ),
    ),
  );

  @override
  Future<RiderLimits> limits() async =>
      RiderLimits.fromJson(_map(await _api.get('riders/me/limits')));

  @override
  Future<RiderProfile> updateSettings(RiderSettingsInput input) async =>
      RiderProfile.fromJson(
        _map(await _api.patch('riders/me/settings', data: input.toJson())),
      );

  @override
  Future<RiderProfile> setOnline(bool online) async => RiderProfile.fromJson(
    _map(await _api.patch('riders/me/online', data: {'online': online})),
  );

  @override
  Future<void> updateLocation(GeoPoint point) async {
    await _api.patch('riders/me/location', data: point.toJson());
  }

  @override
  Future<RiderActive> active() async =>
      RiderActive.fromJson(_map(await _api.get('riders/me/active')));

  @override
  Future<List<Order>> myOrders() async {
    final data = _map(await _api.get('riders/me/orders'));
    return [
      for (final o in (data['orders'] as List? ?? const []))
        Order.fromJson(_map(o)),
    ];
  }

  Future<Order> _order(Future<dynamic> call) async =>
      Order.fromJson(_map(await call));

  @override
  Future<Order> acceptOffer(String orderId) =>
      _order(_api.post('orders/$orderId/offer/accept'));

  @override
  Future<void> declineOffer(String orderId) async {
    await _api.post('orders/$orderId/offer/decline');
  }

  @override
  Future<Order> markArrived(String orderId) =>
      _order(_api.post('orders/$orderId/pickup/arrived'));

  @override
  Future<Order> updateStatus(String orderId, String status) =>
      _order(_api.patch('orders/$orderId/status', data: {'status': status}));

  @override
  Future<Order> cancel(String orderId) => updateStatus(orderId, 'cancelled');

  @override
  Future<Order> requestPayment(String orderId) =>
      _order(_api.post('orders/$orderId/payment/request'));

  @override
  Future<Order> paymentReceived(
    String orderId, {
    required PayMethod method,
    String? mpesaCode,
  }) => _order(
    _api.post(
      'orders/$orderId/payment/received',
      data: {'method': method.wire, 'mpesa_code': ?mpesaCode},
    ),
  );

  @override
  Future<Order> paymentNotReceived(String orderId) =>
      _order(_api.post('orders/$orderId/payment/not-received'));

  @override
  Future<List<PaymentMethod>> paymentMethods() async => parsePaymentMethods(
    _map(await _api.get('riders/me/payment-methods'))['methods'],
  );

  @override
  Future<PaymentMethod> savePaymentMethod(
    PayMethod type, {
    required String number,
    required String accountName,
  }) async {
    final data = await _api.put(
      'riders/me/payment-methods/${type.wire}',
      data: {'number': number, 'account_name': accountName},
    );
    return PaymentMethod.tryParse(data) ??
        PaymentMethod(type: type, number: number, accountName: accountName);
  }

  @override
  Future<void> deletePaymentMethod(PayMethod type) async {
    await _api.delete('riders/me/payment-methods/${type.wire}');
  }
}
