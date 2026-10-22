import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/routing/app_router.dart';
import '../evidence/data/evidence_models.dart';
import '../payments/data/payment_models.dart';
import 'data/order_models.dart';

final orderDetailsProvider = FutureProvider.autoDispose
    .family<OrderDetails, String>(
      (ref, orderId) => ref.watch(ordersRepositoryProvider).details(orderId),
      retry: (_, _) => null,
    );

final orderRatingsProvider = FutureProvider.autoDispose
    .family<List<Rating>, String>(
      (ref, orderId) => ref.watch(ordersRepositoryProvider).ratings(orderId),
      retry: (_, _) => null,
    );

/// GET /orders/{id}/payment; invalidate it when the order enters `payment_requested`.
final orderPaymentProvider = FutureProvider.autoDispose
    .family<OrderPayment, String>(
      (ref, orderId) => ref.watch(ordersRepositoryProvider).payment(orderId),
      retry: (_, _) => null,
    );

final evidenceChainProvider = FutureProvider.autoDispose
    .family<List<EvidenceEvent>, String>(
      (ref, orderId) => ref.watch(evidenceRepositoryProvider).chain(orderId),
      retry: (_, _) => null,
    );

final evidencePhotoProvider = FutureProvider.autoDispose
    .family<Uint8List, ({String orderId, String mediaId})>(
      (ref, key) =>
          ref.watch(evidenceRepositoryProvider).photo(key.orderId, key.mediaId),
      retry: (_, _) => null,
    );

enum OrderRole { sender, rider }

/// Which party the signed-in user is on [d]. The server only sends `sender` to the rider.
OrderRole roleFor(OrderDetails d, String? userId) {
  final senderId = d.order.senderId;
  if (senderId != null && userId != null) {
    return senderId == userId ? OrderRole.sender : OrderRole.rider;
  }
  return d.senderName != null ? OrderRole.rider : OrderRole.sender;
}

/// Where a tap on an order (e.g. from a notification) should land: the live screen while the
/// job runs, otherwise the order's history detail.
String routeForOrder(OrderDetails d, String? userId) {
  final o = d.order;
  final role = roleFor(d, userId);
  if (o.isActiveJob) {
    return role == OrderRole.sender
        ? AppRoutes.trackingFor(o.id)
        : AppRoutes.riderHome;
  }
  return AppRoutes.orderDetailFor(o.id, asRider: role == OrderRole.rider);
}
