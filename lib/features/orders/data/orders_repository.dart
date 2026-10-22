import '../../../core/api/api_client.dart';
import '../../booking/data/booking_models.dart';
import '../../payments/data/payment_models.dart';
import 'order_models.dart';

/// Order calls shared by both sides: details, history, ratings, receiver link.
abstract class OrdersRepository {
  Future<OrderDetails> details(String orderId);

  /// GET /orders (orders I sent).
  Future<List<Order>> senderOrders();

  /// GET /riders/me/orders (orders I rode).
  Future<List<Order>> riderOrders();

  Future<List<Rating>> ratings(String orderId);

  /// Throws ApiException 409 `already_rated` when this party has rated already.
  Future<Rating> submitRating(
    String orderId, {
    required int score,
    String? comment,
  });

  Future<ReceiverLink> createReceiverLink(String orderId);

  /// GET /orders/{id}/payment. The sender gets it only while `payment_requested`
  /// (422 `payment_details_hidden` otherwise); the assigned rider at any active status.
  Future<OrderPayment> payment(String orderId);
}

class ApiOrdersRepository implements OrdersRepository {
  ApiOrdersRepository(this._api);

  final ApiClient _api;

  static Map<String, dynamic> _map(Object? data) =>
      (data as Map).cast<String, dynamic>();

  List<Order> _orders(Object? data) => [
    for (final o in (_map(data)['orders'] as List? ?? const []))
      Order.fromJson(_map(o)),
  ];

  @override
  Future<OrderDetails> details(String orderId) async =>
      OrderDetails.fromJson(_map(await _api.get('orders/$orderId')));

  @override
  Future<List<Order>> senderOrders() async => _orders(await _api.get('orders'));

  @override
  Future<List<Order>> riderOrders() async =>
      _orders(await _api.get('riders/me/orders'));

  @override
  Future<List<Rating>> ratings(String orderId) async => [
    for (final r
        in (_map(await _api.get('orders/$orderId/ratings'))['ratings']
                as List? ??
            const []))
      Rating.fromJson(_map(r)),
  ];

  @override
  Future<Rating> submitRating(
    String orderId, {
    required int score,
    String? comment,
  }) async => Rating.fromJson(
    _map(
      await _api.post(
        'orders/$orderId/rating',
        data: {'score': score, 'comment': ?comment},
      ),
    ),
  );

  @override
  Future<ReceiverLink> createReceiverLink(String orderId) async =>
      ReceiverLink.fromJson(
        _map(await _api.post('orders/$orderId/receiver-link')),
      );

  @override
  Future<OrderPayment> payment(String orderId) async =>
      OrderPayment.fromJson(_map(await _api.get('orders/$orderId/payment')));
}
