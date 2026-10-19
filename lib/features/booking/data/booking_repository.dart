import 'dart:typed_data';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/location/geo_point.dart';
import 'booking_models.dart';

/// Place search is switched off on the server (503 "maps not configured").
class MapsUnavailableException implements Exception {
  const MapsUnavailableException();
}

/// Every call the sender booking flow makes to the Go server.
abstract class BookingRepository {
  Future<List<PlacePrediction>> autocomplete({
    required String input,
    required String sessionToken,
    GeoPoint? near,
  });

  Future<Place> placeDetails({
    required String placeId,
    required String sessionToken,
  });

  Future<List<ItemCategory>> itemCategories();

  Future<Order> createOrder(CreateOrderInput input);

  Future<Order> getOrder(String orderId);

  /// GET /orders/{id} as the sender, including `pending_offer`.
  Future<SenderOrder> senderOrder(String orderId);

  /// GET /orders/active: the sender's non-terminal orders, newest first.
  Future<List<SenderOrder>> activeOrders();

  Future<Order> updateRoute(String orderId, RouteInput route);

  Future<RiderList> ridersForOrder(String orderId);

  /// Null when the rider has no approved photo (404).
  Future<Uint8List?> riderPhoto(String riderId);

  Future<Offer> sendOffer({required String orderId, required String riderId});

  Future<Order> cancelOrder(String orderId);

  /// The sender's orders (GET /orders).
  Future<List<Order>> myOrders();

  /// Sender confirms the cash was paid (payment_requested -> cash_pending).
  Future<Order> confirmPaymentSent(String orderId);
}

class ApiBookingRepository implements BookingRepository {
  ApiBookingRepository(this._api);

  final ApiClient _api;

  static Map<String, dynamic> _map(Object? data) =>
      (data as Map).cast<String, dynamic>();

  Future<T> _mapsCall<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on ApiException catch (e) {
      if (e.statusCode == 503) throw const MapsUnavailableException();
      rethrow;
    }
  }

  @override
  Future<List<PlacePrediction>> autocomplete({
    required String input,
    required String sessionToken,
    GeoPoint? near,
  }) => _mapsCall(() async {
    final data = _map(
      await _api.get(
        'places/autocomplete',
        query: {
          'input': input,
          'session_token': sessionToken,
          if (near != null) 'lat': near.lat,
          if (near != null) 'lng': near.lng,
        },
      ),
    );
    return [
      for (final p in (data['predictions'] as List? ?? const []))
        PlacePrediction.fromJson(_map(p)),
    ];
  });

  @override
  Future<Place> placeDetails({
    required String placeId,
    required String sessionToken,
  }) => _mapsCall(
    () async => Place.fromJson(
      _map(
        await _api.get(
          'places/details',
          query: {'place_id': placeId, 'session_token': sessionToken},
        ),
      ),
    ),
  );

  @override
  Future<List<ItemCategory>> itemCategories() async {
    final data = _map(await _api.get('item-categories'));
    return [
      for (final c in (data['categories'] as List? ?? const []))
        ItemCategory.fromJson(_map(c)),
    ];
  }

  @override
  Future<Order> createOrder(CreateOrderInput input) async =>
      Order.fromJson(_map(await _api.post('orders', data: input.toJson())));

  @override
  Future<Order> getOrder(String orderId) async =>
      Order.fromJson(_map(await _api.get('orders/$orderId')));

  @override
  Future<SenderOrder> senderOrder(String orderId) async =>
      SenderOrder.fromJson(_map(await _api.get('orders/$orderId')));

  @override
  Future<List<SenderOrder>> activeOrders() async {
    final data = _map(await _api.get('orders/active'));
    return [
      for (final o in (data['orders'] as List? ?? const []))
        SenderOrder.fromJson(_map(o)),
    ];
  }

  @override
  Future<Order> updateRoute(String orderId, RouteInput route) async =>
      Order.fromJson(
        _map(await _api.patch('orders/$orderId/route', data: route.toJson())),
      );

  @override
  Future<RiderList> ridersForOrder(String orderId) async =>
      RiderList.fromJson(_map(await _api.get('orders/$orderId/riders')));

  @override
  Future<Uint8List?> riderPhoto(String riderId) async {
    try {
      return await _api.getBytes('riders/$riderId/photo');
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  @override
  Future<Offer> sendOffer({
    required String orderId,
    required String riderId,
  }) async => Offer.fromJson(
    _map(await _api.post('orders/$orderId/offer', data: {'rider_id': riderId})),
  );

  @override
  Future<Order> cancelOrder(String orderId) async => Order.fromJson(
    _map(
      await _api.patch('orders/$orderId/status', data: {'status': 'cancelled'}),
    ),
  );

  @override
  Future<List<Order>> myOrders() async {
    final data = _map(await _api.get('orders'));
    return [
      for (final o in (data['orders'] as List? ?? const []))
        Order.fromJson(_map(o)),
    ];
  }

  @override
  Future<Order> confirmPaymentSent(String orderId) async =>
      Order.fromJson(_map(await _api.post('orders/$orderId/payment/sent')));
}
