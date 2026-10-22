import 'dart:async';
import 'dart:typed_data';

import 'package:ridelink/core/api/api_exception.dart';
import 'package:ridelink/core/location/geo_point.dart';
import 'package:ridelink/core/navigation/navigation_launcher.dart';
import 'package:ridelink/core/share/share_service.dart';
import 'package:ridelink/features/booking/data/booking_models.dart';
import 'package:ridelink/features/evidence/data/evidence_models.dart';
import 'package:ridelink/features/evidence/data/evidence_repository.dart';
import 'package:ridelink/features/notifications/data/notification_repository.dart';
import 'package:ridelink/features/orders/data/order_models.dart';
import 'package:ridelink/features/orders/data/orders_repository.dart';
import 'package:ridelink/features/payments/data/payment_models.dart';

/// The signed-in user in every harness (see sessionJson in fakes.dart).
const testUserId = 'user-1';

ApiException apiError(int status, String code, [String message = 'server']) =>
    ApiException(statusCode: status, code: code, message: message);

/// Serves GET /orders/{id} from [details] or, by default, the booking fake's current order.
class FakeOrdersRepository implements OrdersRepository {
  FakeOrdersRepository({this.orderSource});

  /// Default order source (e.g. the booking fake's `order`), read on every call.
  Order Function()? orderSource;
  final fixedDetails = <String, OrderDetails>{};
  OrderRider? rider;
  OrderTerms? terms;
  String? senderName;
  ReceiverLocation? receiverLocation;
  Object? detailsError;
  int detailsCalls = 0;

  List<Order> senderOrdersList = const [];
  List<Order> riderOrdersList = const [];
  Object? historyError;

  final ratingsByOrder = <String, List<Rating>>{};
  Object? ratingsError;
  final ratingCalls = <({String orderId, int score, String? comment})>[];
  Object? ratingError;

  int receiverLinkCalls = 0;
  Object? receiverLinkError;
  String receiverUrl = 'https://ridelink.test/r/abc123';

  /// GET /orders/{id}/payment; defaults to cash only for the source order's price, with the
  /// "Did you pay?" answer pending when the source order is `unresolved`.
  OrderPayment? paymentResult;
  Object? paymentError;
  int paymentCalls = 0;

  @override
  Future<OrderDetails> details(String orderId) async {
    detailsCalls++;
    if (detailsError != null) throw detailsError!;
    final fixed = fixedDetails[orderId];
    if (fixed != null) return fixed;
    final order = orderSource?.call();
    if (order == null) throw apiError(404, 'not_found');
    return OrderDetails(
      order: order,
      rider: rider,
      terms: terms,
      senderName: senderName,
      receiverLocation: receiverLocation,
    );
  }

  @override
  Future<List<Order>> senderOrders() async {
    if (historyError != null) throw historyError!;
    return senderOrdersList;
  }

  @override
  Future<List<Order>> riderOrders() async {
    if (historyError != null) throw historyError!;
    return riderOrdersList;
  }

  @override
  Future<List<Rating>> ratings(String orderId) async {
    if (ratingsError != null) throw ratingsError!;
    return ratingsByOrder[orderId] ?? const [];
  }

  @override
  Future<Rating> submitRating(
    String orderId, {
    required int score,
    String? comment,
  }) async {
    ratingCalls.add((orderId: orderId, score: score, comment: comment));
    if (ratingError != null) throw ratingError!;
    final rating = Rating(
      fromId: testUserId,
      toId: 'other',
      score: score,
      comment: comment,
    );
    ratingsByOrder[orderId] = [...?ratingsByOrder[orderId], rating];
    return rating;
  }

  @override
  Future<ReceiverLink> createReceiverLink(String orderId) async {
    receiverLinkCalls++;
    if (receiverLinkError != null) throw receiverLinkError!;
    return ReceiverLink(url: receiverUrl);
  }

  @override
  Future<OrderPayment> payment(String orderId) async {
    paymentCalls++;
    if (paymentError != null) throw paymentError!;
    final order = orderSource?.call();
    return paymentResult ??
        OrderPayment(
          amount: order?.agreedPrice ?? 0,
          currency: 'KES',
          cash: true,
          methods: const [],
          payerResponse: order?.status == 'unresolved'
              ? PayerResponseState.pending
              : null,
        );
  }
}

class FakeEvidenceRepository implements EvidenceRepository {
  List<EvidenceEvent> events = const [];
  Object? chainError;
  ChainVerification verification = const ChainVerification(
    valid: true,
    eventCount: 3,
  );
  Object? verifyError;
  int verifyCalls = 0;

  final uploads =
      <({String orderId, MediaKind kind, List<int> bytes, String sha256})>[];

  /// Errors thrown by the next uploads, in order (null = succeed).
  final uploadErrors = <Object?>[];
  Completer<void>? uploadGate;
  Uint8List photoBytes = Uint8List.fromList(const [1, 2, 3]);
  final photoCalls = <String>[];

  @override
  Future<List<EvidenceEvent>> chain(String orderId) async {
    if (chainError != null) throw chainError!;
    return events;
  }

  @override
  Future<ChainVerification> verify(String orderId) async {
    verifyCalls++;
    if (verifyError != null) throw verifyError!;
    return verification;
  }

  @override
  Future<EvidenceMedia> uploadPhoto(
    String orderId, {
    required MediaKind kind,
    required List<int> bytes,
    required String fileName,
    required String sha256,
    void Function(int sent, int total)? onProgress,
  }) async {
    uploads.add((orderId: orderId, kind: kind, bytes: bytes, sha256: sha256));
    onProgress?.call(bytes.length ~/ 2, bytes.length);
    if (uploadGate != null) await uploadGate!.future;
    final error = uploadErrors.isEmpty ? null : uploadErrors.removeAt(0);
    if (error != null) throw error;
    return EvidenceMedia(
      id: 'media-${uploads.length}',
      kind: kind,
      sha256: sha256,
    );
  }

  @override
  Future<Uint8List> photo(String orderId, String mediaId) async {
    photoCalls.add(mediaId);
    return photoBytes;
  }
}

class FakeNotificationRepository implements NotificationRepository {
  List<AppNotification> items = const [];
  int? unreadOverride;
  Object? listError;
  int listCalls = 0;
  final readCalls = <String>[];

  @override
  Future<NotificationPage> list() async {
    listCalls++;
    if (listError != null) throw listError!;
    return NotificationPage(
      items: items,
      unreadCount: unreadOverride ?? items.where((n) => !n.isRead).length,
    );
  }

  @override
  Future<void> markRead(String id) async => readCalls.add(id);
}

class FakeNavigationLauncher implements NavigationLauncher {
  final destinations = <GeoPoint>[];
  bool result = true;

  @override
  Future<bool> navigateTo(GeoPoint destination) async {
    destinations.add(destination);
    return result;
  }
}

class FakeShareService implements ShareService {
  final shared = <String>[];

  @override
  Future<void> shareText(String text) async => shared.add(text);
}

AppNotification notificationFixture({
  String id = 'n-1',
  String type = 'payment_requested',
  String? orderId = 'order-9',
  Map<String, dynamic> data = const {'order_id': 'order-9', 'amount': 214},
  bool read = false,
  String title = 'Server title',
  String body = 'Server body',
}) => AppNotification(
  id: id,
  type: type,
  title: title,
  body: body,
  orderId: orderId,
  data: data,
  readAt: read ? DateTime.utc(2026, 10, 13, 9) : null,
  createdAt: DateTime.utc(2026, 10, 13, 9, 40),
);

EvidenceEvent evidenceEventFixture({
  int seq = 1,
  String type = 'pickup_photo',
  String? actorId = testUserId,
  Map<String, dynamic>? payload,
}) => EvidenceEvent(
  id: 'ev-$seq',
  seq: seq,
  eventType: type,
  eventHash: 'a' * 56 + seq.toString().padLeft(8, '0'),
  actorId: actorId,
  payload:
      payload ??
      (type.endsWith('_photo')
          ? {'media_id': '00000000-0000-0000-0000-00000000000$seq'}
          : {'amount': 214}),
  serverReceivedAt: DateTime.utc(2026, 10, 13, 9, 40 + seq),
);
